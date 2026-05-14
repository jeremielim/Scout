import SwiftUI

struct ContentView: View {
    @State private var currentURL = "https://bandcamp.com"
    @State private var inputURL = "https://bandcamp.com"
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var webViewAction: WebViewAction = .none

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            BandcampWebView(
                urlString: $currentURL,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                action: $webViewAction
            )
        }
        .onChange(of: currentURL) { url in
            inputURL = url
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button(action: { webViewAction = .goBack }) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)
            .buttonStyle(.plain)

            Button(action: { webViewAction = .goForward }) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)
            .buttonStyle(.plain)

            TextField("bandcamp.com", text: $inputURL)
                .textFieldStyle(.roundedBorder)
                .onSubmit { navigate(to: inputURL) }

            Button("Go") { navigate(to: inputURL) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func navigate(to raw: String) {
        var url = raw.trimmingCharacters(in: .whitespaces)
        if !url.contains(".") {
            url = "https://bandcamp.com/search?q=\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)"
        } else if !url.hasPrefix("http") {
            url = "https://\(url)"
        }
        currentURL = url
    }
}

enum WebViewAction: Equatable {
    case none, goBack, goForward, reload
}
