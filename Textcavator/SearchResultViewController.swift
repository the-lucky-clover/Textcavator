import AppKit

class SearchResultViewController: NSViewController {
    private let captureRecord: CaptureRecord
    private let snippet: String
    var onSelect: (() -> Void)?

    init(record: CaptureRecord, snippet: String) {
        self.captureRecord = record
        self.snippet = snippet
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 80))
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
        titleLabel.frame = NSRect(x: 12, y: 52, width: 576, height: 20)
        view.addSubview(titleLabel)

        let dateLabel = NSTextField(labelWithString: dateFormatter.string(from: captureRecord.capturedAt))
        dateLabel.font = NSFont.systemFont(ofSize: 11)
        dateLabel.textColor = NSColor(white: 0.7, alpha: 1.0)
        dateLabel.frame = NSRect(x: 12, y: 32, width: 200, height: 16)
        view.addSubview(dateLabel)

        let snippetLabel = NSTextField(labelWithString: snippet)
        snippetLabel.font = NSFont.systemFont(ofSize: 12)
        snippetLabel.textColor = NSColor(white: 0.9, alpha: 1.0)
        snippetLabel.frame = NSRect(x: 12, y: 4, width: 576, height: 26)
        snippetLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(snippetLabel)
    }

    override func mouseUp(with event: NSEvent) {
        onSelect?()
    }
}
