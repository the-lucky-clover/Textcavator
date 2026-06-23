import AppKit

class SettingsWindowController: NSWindowController {
    
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    
    convenience init() {
        let settingsViewController = SettingsViewController()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Textcavator Settings"
        window.contentViewController = settingsViewController
        window.center()
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}