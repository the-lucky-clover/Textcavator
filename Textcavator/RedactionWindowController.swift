import AppKit

class RedactionWindowController: NSWindowController {
    var image: NSImage!
    var onRedacted: ((NSImage) -> Void)?
    var onCancel: (() -> Void)?
    var captureId: UUID?

    private var overlayView: RedactionOverlayView!
    private var imageView: NSImageView!
    private var templatePopover: NSPopover?
    private var auditLog: [RedactionAuditEntry] = []

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
        overlayView.onSelectionChanged = { [weak self] in
            self?.updateAuditLog()
        }
        imageView.addSubview(overlayView)
    }

    private func updateAuditLog() {
        guard let captureId = captureId else { return }
        for region in overlayView.regions {
            let entry = RedactionAuditEntry(
                captureId: captureId,
                region: region,
                exportedSafe: false
            )
            auditLog.append(entry)
            TextcavatorDatabase.shared.saveRedactionAuditEntry(entry)
        }
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

    @objc private func highlightSelected() {
        overlayView.tool = .highlight
    }

    @objc private func noteSelected() {
        overlayView.tool = .note
    }

    @objc private func applyTemplate(_ template: RedactionTemplate) {
        overlayView.tool = .solid
        templatePopover?.performClose(nil)
    }

    @objc private func exportSafeClicked() {
        guard let captureId = captureId else { return }
        guard let exported = overlayView.renderRedactedImage(from: image, template: .none) else { return }

        for i in 0..<overlayView.regions.count {
            auditLog[i].exportedSafe = true
            TextcavatorDatabase.shared.updateAuditEntryExport(auditLog[i].id, exportedSafe: true)
        }

        onRedacted?(exported)
        window?.close()
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
        return [.flexibleSpace, .init("blur"), .init("pixelate"), .init("solid"), .init("highlight"), .init("note"), .init("template"), .init("exportSafe"), .init("apply"), .init("cancel")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("blur"), .init("pixelate"), .init("solid"), .init("highlight"), .init("note"), .init("template"), .init("exportSafe"), .init("apply"), .init("cancel")]
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
        case "highlight":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Highlight"
            item.toolTip = "Yellow highlight"
            item.image = NSImage(systemSymbolName: "highlighter", accessibilityDescription: "Highlight")
            item.target = self
            item.action = #selector(highlightSelected)
            return item
        case "note":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Note"
            item.toolTip = "Add annotation note"
            item.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Note")
            item.target = self
            item.action = #selector(noteSelected)
            return item
        case "template":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Template"
            item.toolTip = "Apply redaction template"
            item.image = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: "Template")
            item.target = self
            item.action = #selector(showTemplateMenu)
            return item
        case "exportSafe":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Export Safe"
            item.toolTip = "Export with audit trail"
            item.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "Export Safe")
            item.target = self
            item.action = #selector(exportSafeClicked)
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

    @objc private func showTemplateMenu() {
        let menu = NSMenu()
        for template in RedactionTemplate.allCases {
            let item = NSMenuItem(title: template.displayName, action: #selector(templateSelected(_:)), keyEquivalent: "")
            item.representedObject = template
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: .zero, in: view)
    }

    @objc private func templateSelected(_ sender: NSMenuItem) {
        if let template = sender.representedObject as? RedactionTemplate {
            applyTemplate(template)
        }
    }
}
