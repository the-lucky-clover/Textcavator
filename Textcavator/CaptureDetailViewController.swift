import AppKit

class CaptureDetailViewController: NSViewController {
    private let image: NSImage
    private let record: CaptureRecord

    init(image: NSImage, record: CaptureRecord) {
        self.image = image
        self.record = record
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let contentView = view else { return }

        let splitView = NSSplitView(frame: contentView.bounds)
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        contentView.addSubview(splitView)

        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]

        let detailView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))

        let scrollView = NSScrollView(frame: detailView.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.documentView = detailView
        scrollView.autoresizingMask = [.width, .height]

        splitView.addArrangedSubview(imageView)
        splitView.addArrangedSubview(scrollView)

        var y: CGFloat = 16
        let maxWidth = detailView.bounds.width - 32

        let title = NSTextField(labelWithString: "Capture Detail")
        title.font = NSFont.boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 16, y: y, width: maxWidth, height: 24)
        detailView.addSubview(title)
        y -= 36

        addDetailRow(to: detailView, y: &y, label: "App", value: record.sourceApp, maxWidth: maxWidth)
        addDetailRow(to: detailView, y: &y, label: "Dimensions", value: "\(record.width) x \(record.height)", maxWidth: maxWidth)
        addDetailRow(to: detailView, y: &y, label: "Captured", value: ISO8601DateFormatter().string(from: record.capturedAt), maxWidth: maxWidth)
        if let confidence = record.confidence {
            addDetailRow(to: detailView, y: &y, label: "Confidence", value: String(format: "%.1f%%", confidence * 100), maxWidth: maxWidth)
        }
        if let language = record.language {
            addDetailRow(to: detailView, y: &y, label: "Language", value: language, maxWidth: maxWidth)
        }
        if let ocrText = record.ocrText, !ocrText.isEmpty {
            y -= 8
            let label = NSTextField(labelWithString: "Extracted Text")
            label.font = NSFont.boldSystemFont(ofSize: 13)
            label.frame = NSRect(x: 16, y: y, width: maxWidth, height: 18)
            detailView.addSubview(label)
            y -= 26

            let textView = NSTextView(frame: NSRect(x: 16, y: y, width: maxWidth, height: 200))
            textView.textStorage?.setAttributedString(NSAttributedString(string: ocrText))
            textView.isEditable = false
            textView.backgroundColor = NSColor(calibratedWhite: 0.15, alpha: 1.0)
            textView.textColor = .white
            textView.font = NSFont.systemFont(ofSize: 12)
            let container = NSTextContainer(size: NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
            container.widthTracksTextView = true
            textView.textContainer?.widthTracksTextView = true
            detailView.addSubview(textView)
        }
    }

    private func addDetailRow(to parent: NSView, y: inout CGFloat, label: String, value: String, maxWidth: CGFloat) {
        let labelField = NSTextField(labelWithString: "\(label):")
        labelField.font = NSFont.boldSystemFont(ofSize: 12)
        labelField.textColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        labelField.frame = NSRect(x: 16, y: y, width: maxWidth, height: 18)
        parent.addSubview(labelField)

        let valueField = NSTextField(labelWithString: value)
        valueField.font = NSFont.systemFont(ofSize: 12)
        valueField.textColor = .white
        valueField.frame = NSRect(x: 16, y: y - 18, width: maxWidth, height: 18)
        parent.addSubview(valueField)

        y -= 40
    }
}
