import AppKit
import SwiftUI

/// AppDelegate — manages the NSStatusItem (menu bar icon) and its popover.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var signatureManager = SignatureManager.shared
    private var eventMonitor: EventMonitor?
    private var globalHotkeyMonitor: Any?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only: hide from Dock and ⌘Tab switcher
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupGlobalHotkey()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ClosePopover"), object: nil, queue: .main) { [weak self] _ in
            self?.closePopover()
        }
    }

    func checkForUpdates() {
        // Native GitHub Releases API check
        let url = URL(string: "https://api.github.com/repos/mustafabercerita/personal-signature/releases/latest")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    
                    if tagName.replacingOccurrences(of: "v", with: "") > currentVersion.replacingOccurrences(of: "v", with: "") {
                        alert.messageText = "Update Available"
                        alert.informativeText = "Version \(tagName) is available! You are currently running \(currentVersion)."
                        alert.addButton(withTitle: "Download Update")
                        alert.addButton(withTitle: "Cancel")
                        let response = alert.runModal()
                        if response == .alertFirstButtonReturn {
                            if let htmlUrl = json["html_url"] as? String, let url = URL(string: htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    } else {
                        alert.messageText = "You're up to date!"
                        alert.informativeText = "Personal Signature v\(currentVersion) is currently the newest version available."
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                } else {
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Could not connect to GitHub to check for updates. Please try again later."
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
        task.resume()
    }

    func applicationWillTerminate(_ notification: Notification) {
        teardownGlobalHotkey()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // macOS automatically treats images ending with "Template" as template images
            // (meaning it will color them black/white automatically based on Light/Dark mode).
            let image = NSImage(named: "MenuBarIconTemplate")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Personal Signature"
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = true

        let contentView = MenuBarView()
            .environmentObject(signatureManager)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 300, height: 380)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 300, height: 380)
    }

    // MARK: - Event Monitor (close on outside click)

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.closePopover()
        }
    }

    // MARK: - Global Hotkey (⌥⌘S)

    private func setupGlobalHotkey() {
        GlobalShortcutManager.shared.action = { [weak self] in
            let copied = self?.signatureManager.copySignatureToClipboard() ?? false
            if !copied && self?.signatureManager.signatureImage == nil {
                // No signature yet — open popover to let user add one
                self?.openPopover()
            }
        }
    }

    private func teardownGlobalHotkey() {
        // Handled automatically by system on app exit, or could add an unregister method
    }

    // MARK: - Popover Control

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        guard let button = statusItem.button else { return }

        // Resize based on current state
        let hasSignature = signatureManager.signatureImage != nil
        let height: CGFloat = hasSignature ? 360 : 260
        popover.contentSize = NSSize(width: 300, height: height)

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        eventMonitor?.start()
    }

    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
}
