import SwiftUI
import WebKit

struct BandcampWebView: NSViewRepresentable {
    let urlString: String
    @ObservedObject var state: PlayerState

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.addUserScript(Self.metadataScript)
        config.userContentController.add(context.coordinator, name: "nowPlaying")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Identify as Safari so Bandcamp serves the full desktop player
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        context.coordinator.webView = webView
        load(urlString, in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != urlString {
            context.coordinator.prepareForNewLoad()
            load(urlString, in: webView)
        }
    }

    private func load(_ raw: String, in webView: WKWebView) {
        guard let url = URL(string: raw) else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Injected JavaScript

    private static let metadataScript: WKUserScript = {
        let source = #"""
        (function() {
            var lastKey = '';

            function pull() {
                var title = document.querySelector('.current_track .track-title')?.textContent?.trim()
                         || document.querySelector('tr.current_track .title-col .track-title')?.textContent?.trim()
                         || document.querySelector('.title-section .trackTitle')?.textContent?.trim()
                         || document.querySelector('h2.trackTitle')?.textContent?.trim()
                         || (document.title?.split(' | ')[0]?.trim()) || '';

                var artist = document.querySelector('.title-section .artist a')?.textContent?.trim()
                          || document.querySelector('#band-name-location span.title')?.textContent?.trim()
                          || (document.title?.split(' | ')[1]?.trim()) || '';

                var album = document.querySelector('.title-section .album a')?.textContent?.trim() || '';

                var art = document.querySelector('#tralbumArt img')?.src
                       || document.querySelector('a.popupImage img')?.src
                       || document.querySelector('meta[property="og:image"]')?.content
                       || '';

                var audio = document.querySelector('audio');
                var isPlaying = audio ? !audio.paused && !audio.ended : false;

                if (!title) { return; }

                var key = title + '|' + isPlaying + '|' + art;
                if (key !== lastKey) {
                    lastKey = key;
                    window.webkit.messageHandlers.nowPlaying.postMessage({
                        title:     title,
                        artist:    artist,
                        album:     album,
                        artwork:   art,
                        isPlaying: isPlaying
                    });
                }
            }

            setInterval(pull, 750);
            pull();
        })();
        """#
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }()

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let state: PlayerState
        weak var webView: WKWebView?
        private var observers: [NSObjectProtocol] = []
        private var didAutoPlay = false

        init(state: PlayerState) {
            self.state = state
            super.init()
            observe(.scoutPlayPause, js: Self.playPauseJS)
            observe(.scoutNextTrack, js: Self.nextJS)
            observe(.scoutPreviousTrack, js: Self.prevJS)

            let volumeToken = NotificationCenter.default.addObserver(forName: .scoutVolumeChange, object: nil, queue: .main) { [weak self] note in
                guard let value = note.object as? Float else { return }
                let clamped = max(0, min(1, value))
                let js = "(function(){var a=document.querySelector('audio'); if(a){a.volume=\(clamped);}})();"
                self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
            observers.append(volumeToken)
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
        }

        private func observe(_ name: Notification.Name, js: String) {
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
            observers.append(token)
        }

        func prepareForNewLoad() {
            didAutoPlay = false
        }

        // Bandcamp's DOM varies by page; try each selector in order.
        private static let playPauseJS = clickJS([".playbutton", "button.play-btn", "[data-bind*=\"playPause\"]"])
        private static let nextJS      = clickJS([".nextbutton", "button[aria-label=\"Next track\"]"])
        private static let prevJS      = clickJS([".prevbutton", "button[aria-label=\"Previous track\"]"])

        private static func clickJS(_ selectors: [String]) -> String {
            let list = selectors.map { "'\($0)'" }.joined(separator: ",")
            return """
            (function() {
                var sels = [\(list)];
                for (var i = 0; i < sels.length; i++) {
                    var el = document.querySelector(sels[i]);
                    if (el) { el.click(); return; }
                }
            })();
            """
        }

        // MARK: WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didAutoPlay else { return }
            didAutoPlay = true
            // The Bandcamp player needs a moment to initialize before .playbutton is clickable.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak webView, weak self] in
                webView?.evaluateJavaScript(Self.playPauseJS, completionHandler: nil)
                if let volume = self?.state.volume {
                    NotificationCenter.default.post(name: .scoutVolumeChange, object: volume)
                }
            }
        }

        // MARK: WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "nowPlaying",
                  let body = message.body as? [String: Any] else { return }

            let title     = body["title"]     as? String ?? ""
            let artist    = body["artist"]    as? String ?? ""
            let album     = body["album"]     as? String ?? ""
            let artwork   = body["artwork"]   as? String ?? ""
            let isPlaying = body["isPlaying"] as? Bool   ?? false

            DispatchQueue.main.async {
                self.state.title      = title
                self.state.artist     = artist
                self.state.album      = album
                self.state.artworkURL = URL(string: artwork)
                self.state.isPlaying  = isPlaying
            }

            NowPlayingManager.shared.update(
                title:      title,
                artist:     artist,
                album:      album,
                artworkURL: URL(string: artwork)
            )
        }
    }
}
