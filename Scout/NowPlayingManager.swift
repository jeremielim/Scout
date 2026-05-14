import AppKit
import Foundation
import MediaPlayer

class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    private var lastArtworkURL: URL?
    private var artworkTask: URLSessionDataTask?

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
        update(title: "Scout", artist: "Bandcamp", album: nil, artworkURL: nil)
    }

    func update(title: String?, artist: String?, album: String?, artworkURL: URL?) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:           title  ?? "Unknown Track",
            MPMediaItemPropertyArtist:          artist ?? "",
            MPMediaItemPropertyAlbumTitle:      album  ?? "",
            MPNowPlayingInfoPropertyMediaType:  MPNowPlayingInfoMediaType.audio.rawValue,
        ]

        // Carry the existing artwork forward so a text-only update doesn't clear it.
        if let existing = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] {
            info[MPMediaItemPropertyArtwork] = existing
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        if let url = artworkURL, url != lastArtworkURL {
            lastArtworkURL = url
            fetchArtwork(url)
        }
    }

    private func fetchArtwork(_ url: URL) {
        artworkTask?.cancel()
        artworkTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, url == self.lastArtworkURL,
                  let data, let image = NSImage(data: data) else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async {
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
        artworkTask?.resume()
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let scoutPlayPause     = Notification.Name("scoutPlayPause")
    static let scoutNextTrack     = Notification.Name("scoutNextTrack")
    static let scoutPreviousTrack = Notification.Name("scoutPreviousTrack")
}
