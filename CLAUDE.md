# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# Project: Scout

Native macOS menu-bar shell around the Bandcamp web player (`WKWebView`). Not a Bandcamp API client — just a better container around the existing site. See `README.md` for product motivation.

## Build & run

```sh
xcodegen generate                                                          # regenerates Scout.xcodeproj from project.yml
xcodebuild -project Scout.xcodeproj -scheme Scout -configuration Debug build
open build/Build/Products/Debug/Scout.app                                  # or open Scout.xcodeproj and ⌘R in Xcode
```

`Scout.xcodeproj/` is generated — **edit `project.yml`, never the `.pbxproj` directly**. Re-run `xcodegen generate` after changing source layout, entitlements, or Info.plist properties.

## File map

| File | Responsibility |
|---|---|
| `Scout/ScoutApp.swift` | `@main` entry; wires `AppDelegate` via `@NSApplicationDelegateAdaptor`. |
| `Scout/AppDelegate.swift` | Menu-bar `NSStatusItem`, single `NSWindow` lifecycle, calls `NowPlayingManager.shared.setup()`. |
| `Scout/ContentView.swift` | SwiftUI toolbar (back/forward/URL field) + the web view. |
| `Scout/BandcampWebView.swift` | `WKWebView` wrapper. Injects JS that extracts track metadata; observes `.scoutPlayPause`/`.scoutNextTrack`/`.scoutPreviousTrack` and clicks Bandcamp's player buttons via JS. |
| `Scout/NowPlayingManager.swift` | `MPRemoteCommandCenter` (receives media keys → posts notifications) + `MPNowPlayingInfoCenter` (publishes track metadata to Control Center). |
| `Scout/Info.plist` | `LSUIElement=YES` (menu-bar app, no Dock icon). |
| `Scout/Scout.entitlements` | App Sandbox + `network.client`. |
| `project.yml` | XcodeGen spec — source of truth for the project. |

## Gotchas

- **Bandcamp DOM is brittle.** JS selectors (track extraction in `BandcampWebView.swift`, player-button clicks in the `Coordinator` static `*JS` constants) use fallback chains. When Bandcamp ships a redesign, expect to add another selector to the chain rather than rewrite from scratch.
- **`LSUIElement` AND `setActivationPolicy(.accessory)` are both needed.** Plist key hides the Dock icon before launch finishes; runtime call keeps it hidden if the plist is missing. Removing either causes a flicker or a stuck Dock icon.
- **Cookie persistence relies on `WKWebsiteDataStore.default()`.** Don't switch to `.nonPersistent()` — it would log the user out on every launch.
- **macOS 13 deployment target.** Use the single-closure form of `.onChange(of:)`; the two-argument form is macOS 14+.
- **Media keys flow:** OS key press → `MPRemoteCommandCenter` handler in `NowPlayingManager` → `NotificationCenter` post → `BandcampWebView.Coordinator` observer → `evaluateJavaScript` clicks the player button in the page. If keys stop working, check that link end-to-end.
