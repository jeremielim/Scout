import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var state: PlayerState

    var body: some View {
        VStack(spacing: 18) {
            artwork
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 8, y: 4)

            VStack(spacing: 2) {
                Text(state.title.isEmpty ? "Loading…" : state.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(state.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: 280)

            HStack(spacing: 36) {
                ControlButton(symbol: "backward.fill", size: 22) {
                    NotificationCenter.default.post(name: .scoutPreviousTrack, object: nil)
                }
                ControlButton(symbol: state.isPlaying ? "pause.fill" : "play.fill", size: 36) {
                    NotificationCenter.default.post(name: .scoutPlayPause, object: nil)
                }
                ControlButton(symbol: "forward.fill", size: 22) {
                    NotificationCenter.default.post(name: .scoutNextTrack, object: nil)
                }
            }
            .padding(.top, 4)

            HStack(spacing: 8) {
                Button { state.toggleMute() } label: {
                    Image(systemName: state.volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Slider(value: Binding(
                    get: { Double(state.volume) },
                    set: { state.volume = Float($0) }
                ), in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 240)
            .padding(.top, 2)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = state.artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Color.secondary.opacity(0.15))
            Image(systemName: "music.note")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
        }
    }

}

private struct ControlButton: View {
    let symbol: String
    var size: CGFloat = 24
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(width: size + 12, height: size + 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
