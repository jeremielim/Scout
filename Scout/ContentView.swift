import SwiftUI

struct ContentView: View {
    @StateObject private var state = PlayerState()
    @State private var inputURL: String = ""
    @State private var loadedURL: String?

    var body: some View {
        ZStack {
            if loadedURL != nil {
                MiniPlayerView(state: state)
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
        loadedURL = raw.hasPrefix("http") ? raw : "https://\(raw)"
    }
}
