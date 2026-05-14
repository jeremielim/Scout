import Foundation

final class PlayerState: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var artworkURL: URL?
    @Published var isPlaying: Bool = false

    @Published var volume: Float = {
        (UserDefaults.standard.object(forKey: "scoutVolume") as? Float) ?? 1.0
    }() {
        didSet {
            let clamped = max(0, min(1, volume))
            if clamped != volume {
                volume = clamped
                return
            }
            UserDefaults.standard.set(volume, forKey: "scoutVolume")
            NotificationCenter.default.post(name: .scoutVolumeChange, object: volume)
        }
    }

    private var preMuteVolume: Float = 1.0

    func toggleMute() {
        if volume > 0 {
            preMuteVolume = volume
            volume = 0
        } else {
            volume = preMuteVolume > 0 ? preMuteVolume : 1.0
        }
    }
}
