import AppKit

class SearchResultViewController: NSViewController {
    private let captureRecord: CaptureRecord
    private let snippet: String
    var onSelect: (() -> Void)?
    var onQuickAction: ((QuickAction) -> Void)?

    enum QuickAction {
        case copy
        case redact
        case delete
        case openFile
    }

    init(record: CaptureRecord, snippet: String) {
        self.captureRecord = record
        self.snippet = snippet
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 90))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 0.6).cgColor
        view.layer?.cornerRadius = 8

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let titleLabel = NSTextField(labelWithString: captureRecord.sourceApp)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = .white
        titleLabel.frame = NSRect(x: 12, y: 62, width: 576, height: 20)
        view.addSubview(titleLabel)

        let dateLabel = NSTextField(labelWithString: dateFormatter.string(from: captureRecord.capturedAt))
        dateLabel.font = NSFont.systemFont(ofSize: 11)
        dateLabel.textColor = NSColor(white: 0.7, alpha: 1.0)
        dateLabel.frame = NSRect(x: 12, y: 42, width: 200, height: 16)
        view.addSubview(dateLabel)

        let snippetLabel = NSTextField(labelWithString: snippet)
        snippetLabel.font = NSFont.systemFont(ofSize: 12)
        snippetLabel.textColor = NSColor(white: 0.9, alpha: 1.0)
        snippetLabel.frame = NSRect(x: 12, y: 4, width: 520, height: 34)
        snippetLabel.lineBreakMode = .byTruncatingTail
        snippetLabel.maximumNumberOfLines = 2
        view.addSubview(snippetLabel)

        setupQuickActionButtons()
    }

    private func setupQuickActionButtons() {
        let buttonSize = NSSize(width: 28, height: 28)
        let spacing: CGFloat = 6
        let startX = 540
        let y: CGFloat = 50

        let copyBtn = NSButton(frame: NSRect(origin: NSPoint(x: startX, y: y), size: buttonSize))
        copyBtn.bezelStyle = .regularSquare
        copyBtn.bordered = false
        copyBtn.title = ""
        copyBtn.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")
        copyBtn.target = self
        copyBtn.action = #selector(copyClicked)
        view.addSubview(copyBtn)

        let redactBtn = NSButton(frame: NSRect(origin: NSPoint(x: startX + buttonSize.width + spacing, y: y), size: buttonSize))
        redactBtn.bezelStyle = .regularSquare
        redactBtn.bordered = false
        redactBtn.title = ""
        redactBtn.image = NSImage(systemSymbolName: "eye.trianglebadge.exclamationmark", accessibilityDescription: "Redact")
        redactBtn.target = self
        redactBtn.action = #selector(redactClicked)
        view.addSubview(redactBtn)

        let deleteBtn = NSButton(frame: NSRect(origin: NSPoint(x: startX + (buttonSize.width + spacing) * 2, y: y), size: buttonSize))
        deleteBtn.bezelStyle = .regularSquare
        deleteBtn.bordered = false
        deleteBtn.title = ""
        deleteBtn.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")
        deleteBtn.target = self
        deleteBtn.action = #selector(deleteClicked)
        view.addSubview(deleteBtn)
    }

    @objc private func copyClicked() {
        onQuickAction?(.copy)
    }

    @objc private func redactClicked() {
        onQuickAction?(.redact)
    }

    @objc private func deleteClicked() {
        onQuickAction?(.delete)
    }

    @objc private func openFileClicked() {
        onQuickAction?(.openFile)
    }

    override func mouseUp(with event: NSEvent) {
        onSelect?()
    }
}
