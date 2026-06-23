import AppKit

class RedactionWindowController: NSWindowController {
    var image: NSImage!
    var onRedacted: ((NSImage) -> Void)?
    var onCancel: (() -> Void)?

    private var overlayView: RedactionOverlayView!
    private var imageView: NSImageView!

    init(image: NSImage) {
        self.image = image
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Redaction Layer"
        window.minSize = NSSize(width: 600, height: 500)
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let toolbar = NSToolbar(identifier: "RedactionToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.sizeMode = .default
        toolbar.delegate = self
        window?.toolbar = toolbar

        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        contentView.addSubview(scrollView)

        imageView = NSImageView(frame: NSRect(origin: .zero, size: image.size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        scrollView.documentView = imageView

        overlayView = RedactionOverlayView(frame: imageView.bounds)
        overlayView.autoresizingMask = [.width, .height]
        imageView.addSubview(overlayView)
    }

    @objc private func blurSelected() {
        overlayView.tool = .blur
    }

    @objc private func pixelateSelected() {
        overlayView.tool = .pixelate
    }

    @objc private func solidSelected() {
        overlayView.tool = .solid
    }

    @objc private func applyClicked() {
        guard let redacted = overlayView.renderRedactedImage(from: image) else { return }
        onRedacted?(redacted)
        window?.close()
    }

    @objc private func cancelClicked() {
        onCancel?()
        window?.close()
    }
}

extension RedactionWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("blur"), .init("pixelate"), .init("solid"), .init("apply"), .init("cancel")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("blur"), .init("pixelate"), .init("solid"), .init("apply"), .init("cancel")]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "blur":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Blur"
            item.toolTip = "Gaussian blur redaction"
            item.image = NSImage(systemSymbolName: "eye.trianglebadge.exclamationmark", accessibilityDescription: "Blur")
            item.target = self
            item.action = #selector(blurSelected)
            return item
        case "pixelate":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Pixelate"
            item.toolTip = "Pixelate redaction"
            item.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "Pixelate")
            item.target = self
            item.action = #selector(pixelateSelected)
            return item
        case "solid":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Solid"
            item.toolTip = "Solid black redaction"
            item.image = NSImage(systemSymbolName: "rectangle.fill", accessibilityDescription: "Solid")
            item.target = self
            item.action = #selector(solidSelected)
            return item
        case "apply":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Apply"
            item.toolTip = "Apply redactions"
            item.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Apply")
            item.borderContentType = .none
            item.target = self
            item.action = #selector(applyClicked)
            return item
        case "cancel":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Cancel"
            item.toolTip = "Cancel redaction"
            item.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Cancel")
            item.target = self
            item.action = #selector(cancelClicked)
            return item
        default:
            return nil
        }
    }
}
