import SwiftUI

@main
struct PersonalSignatureApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — this is a menu-bar-only app.
        Settings { EmptyView() }
    }
}
