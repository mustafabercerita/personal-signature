# Changelog

All notable changes to **Personal Signature** will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

## [1.1.0] — 2026-06-14

### Added
- **Built-in Drawing Canvas** — draw your signature natively using your trackpad, mouse, or Apple Pencil
- **Multiple signature profiles** — save and quickly switch between different signatures
- **Auto-Paste** — uses macOS Accessibility APIs to paste your signature directly into the active document
- **Global Shortcut Customization** — record your own custom hotkey
- **Drag & Drop Out** — drag the signature from the popover directly into target apps
- **Native Auto-Updater** — lightweight, native SwiftUI GitHub release checker

### Fixed
- **Background removal** — correctly drops white backgrounds while preserving original ink color
- **Memory leaks** — fixed memory leaks in the popover and signature processing
- **Drag and Drop** — fixed issues where drag & drop was not working reliably
- **Windows Memory Leaks** — fixed a memory leak in the Windows app where global shortcuts registered multiple event handlers to the UI thread dispatcher
- **Windows UI Issues** — fixed a UI flashing issue on startup in the Windows app
- **Windows Performance** — dramatically improved image processing performance for background removal in the Windows app by replacing GetPixel/SetPixel with LockBits

### Technical
- **Modular UI Refactoring** — split `MenuBarView` into `HeaderView`, `SignatureActiveView`, `FooterView`, `EmptyStateView`, `DrawingView`, and `AboutView` for better maintainability

---

## [Unreleased]

### Planned
- Touch Bar support
- App Store release

---

## [1.0.0] — 2024-06-14

### Added
- Menu bar icon (`signature` SF Symbol, template — adapts to light/dark menu bar)
- **Add Signature** — pick PNG / JPEG / TIFF from Finder via file importer
- **Sign** — one-click copy of signature image to `NSPasteboard` (paste anywhere: Word, Google Docs, PDF editors, email, etc.)
- **Change Signature** — replace active signature at any time
- **Remove Signature** — delete saved signature with confirmation dialog
- **Drag & Drop** — drag a PNG/image file directly onto the popover (active & empty state)
- **Live preview** thumbnail in popover
- **Empty state** with dashed drop-zone and friendly messaging
- **Toast feedback** — animated "Signature copied to clipboard ✓" notification
- **Launch at Login** toggle via `SMAppService` (macOS 13+)
- **Global hotkey** ⌥⌘S — copy signature without opening popover
- **About panel** — version, GitHub link, shortcut hint
- **Persistent storage** in `~/Library/Application Support/PersonalSignature/signature.png`
- **App Sandbox** with `user-selected.read-only` entitlement
- Unit tests for `SignatureManager` (7 test cases)
- GitHub Actions CI workflow (build + test + archive on main)
- `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, `LICENSE` (MIT)

### Technical
- Swift 5.9 + SwiftUI + AppKit hybrid
- `LSUIElement = YES` — no Dock icon, no ⌘Tab entry
- `NSPasteboard.writeObjects([NSImage])` for universal image paste compatibility
- PNG re-encoding on save — normalizes any source format
- Thread-safe `@Published` state with main-thread dispatch
- `EventMonitor` for outside-click dismissal
- macOS 13.0 Ventura minimum deployment target

[Unreleased]: https://github.com/mustafabercerita/personal-signature/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/mustafabercerita/personal-signature/releases/tag/v1.0.0
