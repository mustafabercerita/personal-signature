# Personal Signature 🖊️

> A lightweight macOS menu bar app that puts your digital signature one click away.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue?logo=apple)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License MIT](https://img.shields.io/badge/License-MIT-green)
![Open Source](https://img.shields.io/badge/Open-Source-brightgreen)

---

## The Problem

Every time you need to sign a document — Word, Excel, Google Docs, a PDF editor, an email — you have to:

1. Open Finder
2. Navigate to your signature file
3. Copy the image
4. Paste it into the document

**Personal Signature eliminates steps 1–3.** Your signature lives in the menu bar, one click away.

---

## Demo Flow

```
Install app → ▲ icon appears in menu bar → click icon
→ Add Signature (choose PNG) → preview shows in popover
→ click Sign → ✓ Signature copied to clipboard
→ ⌘V in any app → done.
```

---

## Features (v1.0 MVP)

| Feature | Description |
|---|---|
| **Menu bar icon** | Lives quietly in macOS menu bar, no Dock icon |
| **Add Signature** | Choose any PNG/JPEG/TIFF file from Finder |
| **Live preview** | Thumbnail of active signature shown in popover |
| **One-click Sign** | Copies signature image to clipboard instantly |
| **Change Signature** | Swap your active signature at any time |
| **Empty state** | Friendly prompt when no signature is saved yet |
| **Toast feedback** | "Signature copied to clipboard ✓" confirmation |
| **Persistent storage** | Signature survives app restarts (stored locally) |
| **Zero dependencies** | Pure Swift/SwiftUI, no Electron, no backend |

---

## Requirements

- macOS 13.0 Ventura or later
- Xcode 15.0 or later
- Apple Developer account (free tier is enough for local builds)

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/personal-signature.git
cd personal-signature
```

### 2. Open in Xcode

```bash
open "PersonalSignature.xcodeproj"
```

Or double-click `PersonalSignature.xcodeproj` in Finder.

### 3. Set your signing team

1. In Xcode, select the **PersonalSignature** target
2. Go to **Signing & Capabilities**
3. Choose your Apple ID team from the dropdown
4. Xcode will auto-manage the provisioning profile

### 4. Run

Press **⌘R** (or click the ▶ Run button).

The app starts immediately — look for the **🖊 signature icon** in your menu bar (top-right area of the screen).

> **Note:** Because `LSUIElement = YES`, the app does **not** appear in the Dock or the ⌘Tab app switcher. This is intentional.

### 5. First use

1. Click the menu bar icon
2. Click **Add Signature**
3. Choose a PNG file of your signature
4. The preview appears immediately
5. Click **Sign** to copy it to your clipboard
6. Paste (⌘V) anywhere

---

## Project Structure

```
Personal Signature/
├── PersonalSignature.xcodeproj/
│   └── project.pbxproj              # Xcode project configuration
│
└── PersonalSignature/
    ├── App/
    │   ├── PersonalSignatureApp.swift  # @main entry point
    │   └── AppDelegate.swift           # NSStatusItem + NSPopover setup
    │
    ├── Models/
    │   └── SignatureManager.swift      # Business logic, persistence, clipboard
    │
    ├── Views/
    │   ├── MenuBarView.swift           # Root popover SwiftUI view
    │   └── Components.swift            # PrimaryButtonStyle, ToastView
    │
    ├── Utilities/
    │   └── EventMonitor.swift          # Global mouse event watcher
    │
    └── Resources/
        └── Info.plist                  # LSUIElement, bundle metadata
```

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for a full technical walkthrough.

**TL;DR:**

```
AppDelegate (NSObject)
  └─ NSStatusItem  ──► NSPopover
                          └─ NSHostingController<MenuBarView>
                                    └─ SignatureManager (ObservableObject / singleton)
                                          ├─ @Published signatureImage: NSImage?
                                          ├─ @Published toastMessage: String?
                                          ├─ saveSignature(from:) → ~/Library/Application Support/PersonalSignature/signature.png
                                          └─ copySignatureToClipboard() → NSPasteboard
```

---

## Build for Distribution (Direct / Non-App Store)

1. In Xcode: **Product → Archive**
2. Click **Distribute App → Developer ID → Export**
3. Optionally notarize with `notarytool`

---

## MVP Limitations

- Supports **one** signature slot (no multiple-signature switching)
- No **drawing pad** — must supply an existing PNG file
- No **background launch at login** (LaunchAgent) — must be added manually
- No **iCloud / Handoff** sync
- No **keyboard shortcut** to trigger Sign from anywhere
- Signature format limited to raster (no SVG)

---

## Roadmap / Future Ideas

- [ ] Multiple signature profiles with quick-switch
- [ ] Built-in drawing canvas to create signature directly in the app
- [ ] Global hotkey (e.g. ⌥⌘S) to copy signature without opening the popover
- [ ] Launch at Login toggle (using `SMAppService`)
- [ ] Transparent PNG background enforcement / background removal
- [ ] Drag-and-drop PNG onto the popover
- [ ] Touch Bar support
- [ ] App Store release

---

## Contributing

Pull requests are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Made with ❤️ to save you those extra clicks, every single day.*
