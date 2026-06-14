# Architecture — Ponten

## Overview

Ponten is a **menu-bar-only** macOS application. It has no main window, no Dock icon, and no visible presence beyond a single icon in the system menu bar. All interaction happens through a compact **NSPopover** rendered with **SwiftUI**.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  macOS Menu Bar                                                  │
│  ┌───────────┐                                                   │
│  │  🖊 icon  │ ◄── NSStatusItem (AppDelegate owns this)         │
│  └─────┬─────┘                                                   │
│        │ click                                                    │
│        ▼                                                         │
│  ┌─────────────────────────────────────┐                        │
│  │  NSPopover (300 × 240-340 pt)       │                        │
│  │  ┌─────────────────────────────┐    │                        │
│  │  │  NSHostingController        │    │                        │
│  │  │  └─ MenuBarView (SwiftUI)   │    │                        │
│  │  │      ├─ HeaderView          │    │                        │
│  │  │      ├─ SignatureActiveView │    │                        │
│  │  │      │  OR EmptyStateView   │    │                        │
│  │  │      ├─ FooterView          │    │                        │
│  │  │      └─ ToastView (overlay) │    │                        │
│  │  └─────────────────────────────┘    │                        │
│  └─────────────────────────────────────┘                        │
│                                                                  │
│  Outside click → EventMonitor → closePopover()                  │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────┐
                    │  SignatureManager (singleton) │
                    │  @Published signatureImage    │
                    │  @Published toastMessage      │
                    │                              │
                    │  saveSignature(from:)        │
                    │    └─ writes PNG to          │
                    │       ~/Library/Application  │
                    │         Support/             │
                    │         Ponten/            │
                    │         signature.png        │
                    │                              │
                    │  copySignatureToClipboard()  │
                    │    └─ NSPasteboard.general   │
                    │       .writeObjects([image]) │
                    └──────────────────────────────┘
```

---

## Key Components

### `PontenApp` (SwiftUI `@main`)

- Uses `@NSApplicationDelegateAdaptor` to bridge to AppKit's `AppDelegate`.
- Declares a `Settings { EmptyView() }` scene — the minimum required to suppress the default main window without triggering SwiftUI warnings.

### `AppDelegate: NSObject, NSApplicationDelegate`

- Calls `NSApp.setActivationPolicy(.accessory)` on launch — this removes the app from the Dock and the ⌘Tab switcher.
- Creates and owns the `NSStatusItem` with a template SF Symbol (`"signature"`).
- Creates and owns the `NSPopover`, wired to `MenuBarView` via `NSHostingController`.
- Manages an `EventMonitor` to close the popover on outside clicks.

### `SignatureManager: ObservableObject` (singleton)

The single source of truth for all business logic:

| Responsibility | Implementation |
|---|---|
| Persistence | Copies chosen PNG into `~/Library/Application Support/Ponten/signature.png` |
| Re-encoding | Re-encodes via `NSBitmapImageRep` to guarantee valid PNG |
| Clipboard | `NSPasteboard.general.writeObjects([NSImage])` |
| Reactive state | `@Published` properties drive SwiftUI re-renders |
| Toast | Timer-driven ephemeral `toastMessage` string |

### `MenuBarView` (SwiftUI)

Root view of the popover. Uses `@EnvironmentObject` to receive `SignatureManager`.

Switches between two states:
- **`SignatureActiveView`** — preview + Sign button + Change Signature button
- **`EmptyStateView`** — icon, description text, Add Signature button

Both states use SwiftUI's `.fileImporter` modifier (backed by `NSOpenPanel`) to let the user pick a file.

### `EventMonitor`

A thin wrapper around `NSEvent.addGlobalMonitorForEvents(matching:handler:)`. Started when the popover opens, stopped when it closes. Calls `closePopover()` on any mouse-down outside the popover window.

### `Components.swift`

- **`PrimaryButtonStyle`**: accent-colored, animated press scale.
- **`ToastView`**: dark capsule with white text, floats above the popover content.

---

## Data Flow

```
User picks PNG file
        │
        ▼  (fileImporter result)
SignatureManager.saveSignature(from:)
        │
        ├─► re-encode → write to ~/Library/…/signature.png
        └─► @Published signatureImage = NSImage(…)
                │
                ▼ (SwiftUI reacts)
        MenuBarView switches to SignatureActiveView
        Preview thumbnail renders

User clicks "Sign"
        │
        ▼
SignatureManager.copySignatureToClipboard()
        │
        ├─► NSPasteboard.general.writeObjects([signatureImage])
        └─► toastMessage = "Signature copied to clipboard ✓"
                │
                ▼ (SwiftUI reacts)
        ToastView animates in → auto-dismisses after 2.5 s
```

---

## Storage

```
~/Library/Application Support/Ponten/
└── signature.png   ← single active signature, replaced on change
```

No database, no CoreData, no UserDefaults for image data. Just a single file on disk. Simple and inspectable.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| SwiftUI inside NSPopover | Gives reactive UI with minimal boilerplate |
| Singleton `SignatureManager` | Shared between AppDelegate (for future hotkey) and SwiftUI views |
| Re-encode PNG on save | Normalizes any JPEG/TIFF drag to a consistent PNG |
| `LSUIElement = YES` | True menu-bar agent — no Dock clutter |
| No SwiftData / CoreData | One file needs one path, not an ORM |
| `NSPasteboard.writeObjects([NSImage])` | Pastes as image in rich-text apps (Word, Pages, Google Docs) |

---

## macOS Version Support

- **Minimum**: macOS 13.0 Ventura
- **Reason**: `.fileImporter` with `allowedContentTypes` + SwiftUI stability on macOS require 13+

---

## Security & Privacy

- App Sandbox enabled
- `com.apple.security.files.user-selected.read-only` entitlement — user explicitly chooses the file; no broad file system access
- No network access — no entitlement requested or granted
- No analytics, no telemetry, no third-party SDKs
