import SwiftUI

struct ContentView: View {
    private static let lastURLKey = "scoutLastURL"

    @StateObject private var state = PlayerState()
    @State private var inputURL: String
    @State private var loadedURL: String?
    @State private var isReplacingURL = false

    init() {
        let savedRawURL = UserDefaults.standard.string(forKey: Self.lastURLKey)?
            .trimmingCharacters(in: .whitespaces)
        let savedURL = savedRawURL?.isEmpty == false ? savedRawURL : nil
        _inputURL = State(initialValue: savedURL ?? "")
        _loadedURL = State(initialValue: savedURL)
    }

    var body: some View {
        ZStack {
            if loadedURL != nil {
                MiniPlayerView(
                    state: state,
                    inputURL: $inputURL,
                    isReplacingURL: $isReplacingURL,
                    onSubmitURL: submit
                )
            } else {
                URLInputView(input: $inputURL, onSubmit: submit)
            }

            // The web view stays mounted so audio keeps playing; it's invisible
            // and ignores hits — the mini player drives playback over the JS bridge.
            if let url = loadedURL {
                BandcampWebView(urlString: url, state: state)
                    .frame(width: 1024, height: 720)
                    .opacity(0)
                    .offset(x: -1400, y: -900)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private func submit() {
        let raw = inputURL.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let normalizedURL = raw.hasPrefix("http") ? raw : "https://\(raw)"
        inputURL = normalizedURL
        UserDefaults.standard.set(normalizedURL, forKey: Self.lastURLKey)
        state.resetTrack()
        NowPlayingManager.shared.reset()
        loadedURL = normalizedURL
        isReplacingURL = false
    }
}
