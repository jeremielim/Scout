import SwiftUI

struct URLInputView: View {
    @Binding var input: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "headphones")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("Scout")
                .font(.title2.bold())
            Text("Paste a Bandcamp album or track URL")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextField("https://artist.bandcamp.com/album/…", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSubmit)
                .frame(maxWidth: 280)
            Button("Go", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
