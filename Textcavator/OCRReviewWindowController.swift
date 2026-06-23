import AppKit
import Vision

class OCRReviewWindowController: NSWindowController {
    private let image: NSImage
    private var observations: [VNRecognizedTextObservation]
    private var onConfirm: ((String, [VNRecognizedTextObservation]) -> Void)?
    private var onRescan: (() -> Void)?
    private var onCancel: (() -> Void)?

    private var reviewView: OCRReviewView!

    init(image: NSImage, observations: [VNRecognizedTextObservation], confirm: @escaping (String, [VNRecognizedTextObservation]) -> Void, rescan: @escaping () -> Void, cancel: @escaping () -> Void) {
        self.image = image
        self.observations = observations
        self.onConfirm = confirm
        self.onRescan = rescan
        self.onCancel = cancel

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Review Extraction"
        window.minSize = NSSize(width: 800, height: 500)
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

        let toolbar = NSToolbar(identifier: "OCRReviewToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.sizeMode = .default
        toolbar.delegate = self
        window?.toolbar = toolbar

        reviewView = OCRReviewView(frame: contentView.bounds)
        reviewView.autoresizingMask = [.width, .height]
        reviewView.configure(image: image, observations: observations)
        contentView.addSubview(reviewView)
    }

    func updateObservations(_ observations: [VNRecognizedTextObservation]) {
        self.observations = observations
        reviewView.configure(image: image, observations: observations)
    }

    @objc private func confirmClicked() {
        let text = reviewView.extractedText
        onConfirm?(text, observations)
        onConfirm = nil
        onRescan = nil
        onCancel = nil
        window?.close()
    }

    @objc private func rescanClicked() {
        onRescan?()
    }

    @objc private func cancelClicked() {
        onCancel?()
        onConfirm = nil
        onRescan = nil
        onCancel = nil
        window?.close()
    }
}

extension OCRReviewWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("confirm"), .init("rescan"), .init("cancel")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("confirm"), .init("rescan"), .init("cancel")]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "confirm" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Confirm & Copy"
            item.toolTip = "Copy extracted text to clipboard"
            item.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Confirm")
            item.target = self
            item.action = #selector(confirmClicked)
            return item
        } else if itemIdentifier.rawValue == "rescan" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Rescan"
            item.toolTip = "Re-run OCR on this capture"
            item.image = NSImage(systemSymbolName: "arrow.clockwise.circle.fill", accessibilityDescription: "Rescan")
            item.target = self
            item.action = #selector(rescanClicked)
            return item
        } else if itemIdentifier.rawValue == "cancel" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Discard"
            item.toolTip = "Discard this capture"
            item.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Cancel")
            item.target = self
            item.action = #selector(cancelClicked)
            return item
        }
        return nil
    }
}

extension OCRReviewWindowController {
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
