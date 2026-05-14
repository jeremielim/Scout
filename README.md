# Scout

A lightweight native Mac app that wraps Bandcamp so you can browse and listen without opening a browser tab. Lives in the menu bar or as a standalone mini window.

## Why

Bandcamp's web player runs on standard HTML5 audio, which macOS's `WKWebView` handles natively. Scout is a native shell around their existing web player — not a Bandcamp client, not a reverse-engineered API. Full playback, the discover feed, your collection, and purchases all work out of the box.

No reverse-engineering. No unofficial API. Just a web view with a better container.

## Features

- Load any Bandcamp URL (discover, collection, artist pages) in a native Mac window
- Keeps playing music in the background while you work in other apps
- System media keys (play/pause, skip) via `MPRemoteCommandCenter`
- Current track shown in the macOS Now Playing widget and Control Center
- Menu bar mode — one click to show/hide, stays out of the Dock
- Session persistence — log in once, stays logged in

## Tech stack

| Layer | Tool |
|---|---|
| UI shell | SwiftUI |
| Web rendering | `WKWebView` (WebKit) |
| Media key support | `MediaPlayer` framework (`MPRemoteCommandCenter`) |
| Now-playing metadata | `MPNowPlayingInfoCenter` |
| App style | Menu bar app (`LSUIElement = true`) |

## Getting started

1. Open Xcode → **File > New > Project**
2. Choose **macOS > App**
3. Set product name to `Scout`, interface to `SwiftUI`, language to `Swift`
4. Delete the generated `ContentView.swift`
5. Drag all files from the `Scout/` source folder into the project
6. In **Signing & Capabilities**, add `com.apple.security.network.client` to the App Sandbox
7. In `Info.plist`, add `Application is agent (UIElement)` → `YES` for menu bar mode
8. Build and run (`⌘R`)

## Project structure

```
Scout/
├── ScoutApp.swift          # @main entry point, wires up AppDelegate
├── AppDelegate.swift       # NSStatusItem menu bar, window lifecycle
├── ContentView.swift       # Main window UI with toolbar
├── BandcampWebView.swift   # WKWebView wrapper + JS injection
└── NowPlayingManager.swift # MPRemoteCommandCenter + MPNowPlayingInfoCenter
```

## Build plan

- [x] Scaffold source files
- [ ] Create Xcode project
- [ ] Working web view shell (~2 hrs)
- [ ] Media key + now-playing integration (~3 hrs)
- [ ] Menu bar mode (~2 hrs)
- [ ] Polish + edge cases (~3 hrs)

## Known challenges

- **Cookie/session persistence** — `WKWebView` has its own cookie store, separate from Safari. Log in once inside the app; after that it persists across launches.
- **JavaScript injection** — Bandcamp's DOM structure can change. JS hooks are kept minimal and resilient with fallbacks.
- **Audio session** — macOS doesn't require explicit audio session management like iOS, but the process must not get suspended while playing.

## Requirements

- macOS 13 Ventura or later
- Xcode 15+

## Related ideas

- Mini player overlay (album art + track name, always-on-top)
- Global hotkey to toggle play/pause from anywhere
- Last.fm scrobbling via JS injection
