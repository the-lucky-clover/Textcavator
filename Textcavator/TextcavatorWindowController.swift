import AppKit

class TextcavatorWindowController: NSWindowController {
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screenshot"
        
        self.init(window: window)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}