import AppKit

class SearchWindowController: NSWindowController {
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?

    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    private let searchField = NSSearchField()
    private let emptyStateLabel = NSTextField(labelWithString: "")
    private var resultControllers: [SearchResultViewController] = []

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Textcavator — Visual Memory Vault"
        window.minSize = NSSize(width: 480, height: 360)
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        setupUI()
        loadRecent()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let toolbar = NSToolbar(identifier: "SearchToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.sizeMode = .default
        toolbar.delegate = self
        window?.toolbar = toolbar

        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        scrollView.documentView = stackView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        searchField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            searchField.heightAnchor.constraint(equalToConstant: 28)
        ])

        searchField.placeholderString = "Search every word you've ever seen..."
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)

        let border = NSBox(frame: NSRect(x: 16, y: 48, width: contentView.bounds.width - 32, height: contentView.bounds.height - 64))
        border.boxType = .custom
        border.borderColor = NSColor(calibratedWhite: 0.3, alpha: 1.0)
        border.borderWidth = 1
        border.cornerRadius = 6
        contentView.addSubview(border)

        scrollView.frame = NSRect(x: 20, y: 52, width: contentView.bounds.width - 40, height: contentView.bounds.height - 72)
        contentView.addSubview(scrollView)

        emptyStateLabel.alignment = .center
        emptyStateLabel.isEditable = false
        emptyStateLabel.isBordered = false
        emptyStateLabel.backgroundColor = .clear
        emptyStateLabel.textColor = NSColor(white: 0.6, alpha: 1.0)
        emptyStateLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
    }

    @objc private func searchFieldChanged() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            loadRecent()
            return
        }
        performSearch(query: query)
    }

    private func loadRecent() {
        clearResults()
        let records = TextcavatorDatabase.shared.recentCaptures(limit: 50)
        for record in records {
            let vc = SearchResultViewController(record: record, snippet: record.ocrText ?? "")
            vc.onSelect = { [weak self] in
                self?.openCapture(record)
            }
            stackView.addArrangedSubview(vc.view)
            resultControllers.append(vc)
        }
        updateEmptyState(count: records.count)
    }

    private func performSearch(query: String) {
        clearResults()
        let results = TextcavatorDatabase.shared.search(query: query, limit: 100)
        for (record, snippet) in results {
            let vc = SearchResultViewController(record: record, snippet: snippet)
            vc.onSelect = { [weak self] in
                self?.openCapture(record)
            }
            stackView.addArrangedSubview(vc.view)
            resultControllers.append(vc)
        }
        updateEmptyState(count: results.count)
    }

    private func clearResults() {
        resultControllers.forEach { $0.view.removeFromSuperview() }
        resultControllers.removeAll()
    }

    private func updateEmptyState(count: Int) {
        if count == 0 {
            emptyStateLabel.stringValue = searchField.stringValue.isEmpty ? "No captures yet" : "No matches found"
            emptyStateLabel.sizeToFit()
            emptyStateLabel.frame = NSRect(x: (scrollView.bounds.width - emptyStateLabel.bounds.width) / 2, y: 60, width: emptyStateLabel.bounds.width, height: emptyStateLabel.bounds.height)
            scrollView.documentView?.addSubview(emptyStateLabel)
        } else {
            emptyStateLabel.removeFromSuperview()
        }
    }

    private func openCapture(_ record: CaptureRecord) {
        guard let image = NSImage(contentsOfFile: record.imagePath) else { return }
        let detailVC = CaptureDetailViewController(image: image, record: record)
        let detailWindow = NSWindow(contentViewController: detailVC)
        detailWindow.title = "Capture Detail"
        detailWindow.makeKeyAndOrderFront(nil)
    }
}

extension SearchWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("captureArea"), .init("captureWindow")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("captureArea"), .init("captureWindow")]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "captureArea" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Capture Area"
            item.toolTip = "Capture screen area"
            item.image = NSImage(systemSymbolName: "crop", accessibilityDescription: "Capture Area")
            item.target = self
            item.action = #selector(captureAreaTapped)
            return item
        } else if itemIdentifier.rawValue == "captureWindow" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Capture Window"
            item.toolTip = "Capture window"
            item.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Capture Window")
            item.target = self
            item.action = #selector(captureWindowTapped)
            return item
        }
        return nil
    }

    @objc private func captureAreaTapped() {
        onCaptureArea?()
    }

    @objc private func captureWindowTapped() {
        onCaptureWindow?()
    }
}
