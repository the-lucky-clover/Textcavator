import AppKit

class CapturePreviewViewController: NSViewController {
    var image: NSImage!
    var onConfirm: (() -> Void)?
    var onRetake: (() -> Void)?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 520))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let imageView = NSImageView(frame: NSRect(x: 20, y: 60, width: 600, height: 400))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(imageView)

        let continueBtn = CyberpunkButton(frame: NSRect(x: 340, y: 14, width: 140, height: 32))
        continueBtn.title = "Continue"
        continueBtn.glowColor = HUDPalette.mint
        continueBtn.target = self
        continueBtn.action = #selector(confirmClicked)
        view.addSubview(continueBtn)

        let retakeBtn = CyberpunkButton(frame: NSRect(x: 180, y: 14, width: 140, height: 32))
        retakeBtn.title = "Retake"
        retakeBtn.glowColor = NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.48, alpha: 1.0)
        retakeBtn.target = self
        retakeBtn.action = #selector(retakeClicked)
        view.addSubview(retakeBtn)
    }

    @objc private func confirmClicked() {
        onConfirm?()
    }

    @objc private func retakeClicked() {
        onRetake?()
    }
}

class CapturePreviewWindowController: NSWindowController {
    convenience init(image: NSImage) {
        let vc = CapturePreviewViewController()
        vc.image = image
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Capture Preview"
        window.contentViewController = vc
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func showAndWait() -> Bool {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}
