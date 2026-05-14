import SwiftUI
import WebKit

struct BandcampWebView: NSViewRepresentable {
    @Binding var urlString: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var action: WebViewAction

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.addUserScript(nowPlayingScript)
        config.userContentController.add(context.coordinator, name: "nowPlaying")
        config.userContentController.add(context.coordinator, name: "playerState")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Identify as Safari so Bandcamp serves the full desktop player
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true

        context.coordinator.webView = webView
        load(url: urlString, in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Handle navigation actions triggered from the toolbar
        if action != .none {
            switch action {
            case .goBack:    webView.goBack()
            case .goForward: webView.goForward()
            case .reload:    webView.reload()
            case .none:      break
            }
            DispatchQueue.main.async { self.action = .none }
            return
        }

        // Navigate when the URL binding changes externally
        if webView.url?.absoluteString != urlString {
            load(url: urlString, in: webView)
        }
    }

    private func load(url raw: String, in webView: WKWebView) {
        guard let url = URL(string: raw) else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Injected JavaScript

    private var nowPlayingScript: WKUserScript {
        let source = """
        (function() {
            var lastTitle = '';

            function extractTrackInfo() {
                var title   = document.querySelector('.title-section .trackTitle')?.textContent?.trim()
                           ?? document.querySelector('h2.trackTitle')?.textContent?.trim()
                           ?? (document.title?.split(' | ')[0]?.trim());
                var artist  = document.querySelector('.title-section .artist a')?.textContent?.trim()
                           ?? document.querySelector('#band-name-location span.title')?.textContent?.trim()
                           ?? (document.title?.split(' | ')[1]?.trim());
                var album   = document.querySelector('.title-section .album a')?.textContent?.trim() ?? '';

                if (title && title !== lastTitle) {
                    lastTitle = title;
                    window.webkit.messageHandlers.nowPlaying.postMessage({
                        title:  title  ?? '',
                        artist: artist ?? '',
                        album:  album  ?? ''
                    });
                }
            }

            setInterval(extractTrackInfo, 1500);
            extractTrackInfo();
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: BandcampWebView
        weak var webView: WKWebView?

        init(_ parent: BandcampWebView) {
            self.parent = parent
        }

        // MARK: WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                if let url = webView.url?.absoluteString {
                    self.parent.urlString = url
                }
                self.parent.canGoBack    = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }

        // Allow Bandcamp's own redirects and pop-ups
        func webView(
            _ webView: WKWebView,
            decidePolicyFor action: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        // MARK: WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "nowPlaying",
                  let body = message.body as? [String: String] else { return }
            NowPlayingManager.shared.update(
                title:  body["title"],
                artist: body["artist"],
                album:  body["album"]
            )
        }
    }
}
