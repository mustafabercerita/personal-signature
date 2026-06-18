import AppKit
import SwiftUI

/// Shows transient notifications when the menu bar popover is closed.
final class MenuBarToastPresenter {

    static let shared = MenuBarToastPresenter()

    private var panel: NSPanel?
    private var hideTimer: Timer?
    private var restoredToolTip: String?

    private init() {}

    func show(message: String, statusItem: NSStatusItem?, duration: TimeInterval = 2.5) {
        hideTimer?.invalidate()

        if let button = statusItem?.button {
            if restoredToolTip == nil {
                restoredToolTip = button.toolTip
            }
            button.toolTip = message
        }

        hidePanel()

        let toastView = NSHostingView(rootView: ToastView(message: message))
        toastView.frame.size = toastView.fittingSize

        let padding: CGFloat = 16
        let panelSize = NSSize(
            width: toastView.fittingSize.width + padding,
            height: toastView.fittingSize.height + padding
        )

        let floatingPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        floatingPanel.isOpaque = false
        floatingPanel.backgroundColor = .clear
        floatingPanel.hasShadow = true
        floatingPanel.level = .statusBar
        floatingPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        floatingPanel.hidesOnDeactivate = false

        toastView.frame = NSRect(
            x: padding / 2,
            y: padding / 2,
            width: toastView.fittingSize.width,
            height: toastView.fittingSize.height
        )
        floatingPanel.contentView = toastView

        if let button = statusItem?.button, let window = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = window.convertToScreen(buttonFrame)
            let origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.minY - panelSize.height - 6
            )
            floatingPanel.setFrameOrigin(origin)
        } else {
            floatingPanel.center()
        }

        floatingPanel.orderFrontRegardless()
        panel = floatingPanel

        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        hidePanel()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        panel = nil
    }

    func restoreToolTip(on statusItem: NSStatusItem?) {
        if let button = statusItem?.button {
            button.toolTip = restoredToolTip ?? "Ponten"
        }
        restoredToolTip = nil
    }
}