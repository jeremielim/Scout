import Foundation
import MediaPlayer

class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    func setup() {
        let cc = MPRemoteCommandCenter.shared()

        cc.togglePlayPauseCommand.addTarget { _ in
            NotificationCenter.default.post(name: .scoutPlayPause, object: nil)
            return .success
        }
        cc.playCommand.addTarget { _ in
            NotificationCenter.default.post(name: .scoutPlayPause, object: nil)
            return .success
        }
        cc.pauseCommand.addTarget { _ in
            NotificationCenter.default.post(name: .scoutPlayPause, object: nil)
            return .success
        }
        cc.nextTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: .scoutNextTrack, object: nil)
            return .success
        }
        cc.previousTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: .scoutPreviousTrack, object: nil)
            return .success
        }

        // Register with the system as a media app immediately
        update(title: "Scout", artist: "Bandcamp", album: nil)
    }

    func update(title: String?, artist: String?, album: String?) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle:       title  ?? "Unknown Track",
            MPMediaItemPropertyArtist:      artist ?? "",
            MPMediaItemPropertyAlbumTitle:  album  ?? "",
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let scoutPlayPause     = Notification.Name("scoutPlayPause")
    static let scoutNextTrack     = Notification.Name("scoutNextTrack")
    static let scoutPreviousTrack = Notification.Name("scoutPreviousTrack")
}
