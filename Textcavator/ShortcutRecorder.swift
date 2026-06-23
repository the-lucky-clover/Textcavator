import AppKit

class ShortcutRecorderView: NSView {
    var onShortcutRecorded: ((keyCode: Int, modifiers: UInt) -> Void)?
    var onCancelled: (() -> Void)?

    private var recordedKeyCode: Int = 0
    private var recordedModifiers: UInt = 0
    private var label: NSTextField!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 0.95).cgColor
        layer?.cornerRadius = 12
        layer?.borderColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.5).cgColor
        layer?.borderWidth = 1.5

        label = NSTextField(labelWithString: "Press new shortcut...")
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 20, y: 30, width: bounds.width - 40, height: 24)
        addSubview(label)

        let cancelBtn = CyberpunkButton(frame: NSRect(x: bounds.width - 90, y: 8, width: 70, height: 26))
        cancelBtn.title = "Cancel"
        cancelBtn.glowColor = NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.48, alpha: 1.0)
        cancelBtn.target = self
        cancelBtn.action = #selector(cancelClicked)
        addSubview(cancelBtn)
    }

    override func keyDown(with event: NSEvent) {
        let keyCode = Int(event.keyCode)
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift]).rawValue

        if keyCode == 53 { // Escape
            onCancelled?()
            return
        }

        if keyCode == 36 || keyCode == 76 { // Return or Enter
            if recordedKeyCode != 0 {
                onShortcutRecorded?(keyCode: recordedKeyCode, modifiers: recordedModifiers & 0xFFFF)
            }
            return
        }

        recordedKeyCode = keyCode
        recordedModifiers = modifiers

        let mods = modifierString(for: modifiers)
        let keyName = keyName(for: keyCode)
        label.stringValue = "\(mods)\(keyName)"

        UXSoundPlayer.shared.play(.select)
    }

    override var acceptsFirstResponder: Bool { true }

    private func modifierString(for modifiers: UInt) -> String {
        var parts: [String] = []
        if modifiers & UInt(NSEvent.ModifierFlags.command.rawValue) != 0 { parts.append("⌘") }
        if modifiers & UInt(NSEvent.ModifierFlags.control.rawValue) != 0 { parts.append("⌃") }
        if modifiers & UInt(NSEvent.ModifierFlags.option.rawValue) != 0 { parts.append("⌥") }
        if modifiers & UInt(NSEvent.ModifierFlags.shift.rawValue) != 0 { parts.append("⇧") }
        return parts.joined()
    }

    private func keyName(for keyCode: Int) -> String {
        switch keyCode {
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 35: return "5"
        case 6:  return "Z"
        case 7:  return "X"
        case 8:  return "C"
        case 9:  return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 53: return "ESC"
        case 36: return "↵"
        case 76: return "↵"
        default: return "\(keyCode)"
        }
    }

    @objc private func cancelClicked() {
        UXSoundPlayer.shared.play(.cancel)
        onCancelled?()
    }
}

class ShortcutRecorderWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 70),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar + 1
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        self.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let contentView = window?.contentView else { return }
        let recorder = ShortcutRecorderView(frame: contentView.bounds)
        recorder.autoresizingMask = [.width, .height]
        contentView.addSubview(recorder)
    }

    func showCentered() {
        if let screen = NSScreen.main {
            let x = screen.frame.midX - 130
            let y = screen.frame.midY - 35
            window?.setFrameTopLeftPoint(NSPoint(x: x, y: y + 70))
        }
        window?.makeKeyAndOrderFront(nil)
        window?.contentView?.subviews.first?.window?.makeFirstResponder(window?.contentView?.subviews.first)
    }
}
