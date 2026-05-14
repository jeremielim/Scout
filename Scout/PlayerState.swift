import Foundation

final class PlayerState: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var artworkURL: URL?
    @Published var isPlaying: Bool = false
}
