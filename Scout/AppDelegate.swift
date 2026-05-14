import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupWindow()
        NowPlayingManager.shared.setup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "Scout")
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }

    @objc func toggleWindow() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Window

    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window?.title = "Scout"
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        window?.center()
        window?.contentView = NSHostingView(rootView: ContentView())
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
