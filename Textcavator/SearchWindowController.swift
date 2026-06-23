import AppKit

class SearchWindowController: NSWindowController {
    var onCaptureArea: (() -> Void)?

    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    private let searchField = NSSearchField()
    private let emptyStateLabel = NSTextField(labelWithString: "")
    private var resultControllers: [SearchResultViewController] = []

    private var currentFilter = SearchFilter()
    private var savedSearches: [SavedSearch] = []
    private var smartCollections: [SmartCollection] = []
    private var suggestions: [String] = []

    private var filterPanel: NSView?
    private var filterAppField: NSTextField!
    private var filterLangField: NSTextField!
    private var filterConfidenceSlider: NSSlider!
    private var filterResetBtn: CyberpunkButton!
    private var filterApplyBtn: CyberpunkButton!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Textcavator — Spotlight Recall"
        window.minSize = NSSize(width: 720, height: 480)
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        setupUI()
        loadSavedSearches()
        loadSmartCollections()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let toolbar = NSToolbar(identifier: "SearchToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.sizeMode = .default
        toolbar.delegate = self
        window?.toolbar = toolbar

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

        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        scrollView.documentView = stackView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.frame = NSRect(x: 16, y: 50, width: contentView.bounds.width - 32, height: contentView.bounds.height - 90)
        contentView.addSubview(scrollView)

        emptyStateLabel.alignment = .center
        emptyStateLabel.isEditable = false
        emptyStateLabel.isBordered = false
        emptyStateLabel.backgroundColor = .clear
        emptyStateLabel.textColor = NSColor(white: 0.6, alpha: 1.0)
        emptyStateLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)

        setupFilterPanel(in: contentView)
    }

    private func setupFilterPanel(in contentView: NSView) {
        let panelWidth: CGFloat = 260
        let panel = NSView(frame: NSRect(x: contentView.bounds.width - panelWidth - 16, y: 50, width: panelWidth, height: contentView.bounds.height - 90))
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 0.95).cgColor
        panel.layer?.cornerRadius = 10
        panel.layer?.borderColor = NSColor(calibratedWhite: 0.2, alpha: 1.0).cgColor
        panel.layer?.borderWidth = 1
        contentView.addSubview(panel)
        filterPanel = panel

        var y: CGFloat = panel.bounds.height - 16

        let filterTitle = NSTextField(labelWithString: "FILTERS")
        filterTitle.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        filterTitle.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        filterTitle.frame = NSRect(x: 12, y: y - 18, width: panelWidth - 24, height: 16)
        panel.addSubview(filterTitle)

        y -= 40
        let appLabel = NSTextField(labelWithString: "App:")
        appLabel.font = NSFont.systemFont(ofSize: 11)
        appLabel.textColor = .white
        appLabel.frame = NSRect(x: 12, y: y, width: 60, height: 16)
        panel.addSubview(appLabel)
        filterAppField = NSTextField(frame: NSRect(x: 12, y: y - 22, width: panelWidth - 24, height: 22))
        filterAppField.placeholderString = "Any app"
        filterAppField.target = self
        filterAppField.action = #selector(filterChanged)
        panel.addSubview(filterAppField)

        y -= 60
        let langLabel = NSTextField(labelWithString: "Language:")
        langLabel.font = NSFont.systemFont(ofSize: 11)
        langLabel.textColor = .white
        langLabel.frame = NSRect(x: 12, y: y, width: 60, height: 16)
        panel.addSubview(langLabel)
        filterLangField = NSTextField(frame: NSRect(x: 12, y: y - 22, width: panelWidth - 24, height: 22))
        filterLangField.placeholderString = "Any language"
        filterLangField.target = self
        filterLangField.action = #selector(filterChanged)
        panel.addSubview(filterLangField)

        y -= 60
        let confLabel = NSTextField(labelWithString: "Min Confidence:")
        confLabel.font = NSFont.systemFont(ofSize: 11)
        confLabel.textColor = .white
        confLabel.frame = NSRect(x: 12, y: y, width: 100, height: 16)
        panel.addSubview(confLabel)
        filterConfidenceSlider = NSSlider(frame: NSRect(x: 12, y: y - 22, width: panelWidth - 24, height: 20))
        filterConfidenceSlider.minValue = 0.0
        filterConfidenceSlider.maxValue = 1.0
        filterConfidenceSlider.doubleValue = 0.0
        filterConfidenceSlider.target = self
        filterConfidenceSlider.action = #selector(filterChanged)
        panel.addSubview(filterConfidenceSlider)

        y -= 50
        filterApplyBtn = CyberpunkButton(frame: NSRect(x: 12, y: y, width: 100, height: 26))
        filterApplyBtn.title = "Apply"
        filterApplyBtn.glowColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        filterApplyBtn.target = self
        filterApplyBtn.action = #selector(applyFilters)
        panel.addSubview(filterApplyBtn)

        filterResetBtn = CyberpunkButton(frame: NSRect(x: 124, y: y, width: 100, height: 26))
        filterResetBtn.title = "Reset"
        filterResetBtn.glowColor = NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.48, alpha: 1.0)
        filterResetBtn.target = self
        filterResetBtn.action = #selector(resetFilters)
        panel.addSubview(filterResetBtn)

        y -= 40
        let savedTitle = NSTextField(labelWithString: "SAVED")
        savedTitle.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        savedTitle.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        savedTitle.frame = NSRect(x: 12, y: y, width: panelWidth - 24, height: 16)
        panel.addSubview(savedTitle)

        y -= 24
        for saved in savedSearches.prefix(5) {
            let btn = CyberpunkButton(frame: NSRect(x: 12, y: y, width: panelWidth - 24, height: 24))
            btn.title = saved.name
            btn.glowColor = NSColor(calibratedRed: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
            btn.tag = saved.id.hashValue
            btn.target = self
            btn.action = #selector(savedSearchClicked(_:))
            panel.addSubview(btn)
            y -= 30
        }

        y -= 16
        let smartTitle = NSTextField(labelWithString: "COLLECTIONS")
        smartTitle.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        smartTitle.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        smartTitle.frame = NSRect(x: 12, y: y, width: panelWidth - 24, height: 16)
        panel.addSubview(smartTitle)

        y -= 24
        for collection in smartCollections.prefix(5) {
            let btn = CyberpunkButton(frame: NSRect(x: 12, y: y, width: panelWidth - 24, height: 24))
            btn.title = "\(collection.icon) \(collection.name)"
            btn.glowColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
            btn.tag = collection.id.hashValue
            btn.target = self
            btn.action = #selector(smartCollectionClicked(_:))
            panel.addSubview(btn)
            y -= 30
        }
    }

    @objc private func searchFieldChanged() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            loadRecent()
            return
        }
        updateSuggestions(for: query)
        performSearch(query: query, filter: currentFilter)
    }

    private func updateSuggestions(for query: String) {
        suggestions = TextcavatorDatabase.shared.searchSuggestions(prefix: query, limit: 8)
        searchField.usesDataSource = false
    }

    private func loadSavedSearches() {
        savedSearches = TextcavatorDatabase.shared.savedSearches()
    }

    private func loadSmartCollections() {
        smartCollections = TextcavatorDatabase.shared.smartCollections()
    }

    @objc private func filterChanged() {
        currentFilter.query = searchField.stringValue
        currentFilter.app = filterAppField.stringValue.isEmpty ? nil : filterAppField.stringValue
        currentFilter.language = filterLangField.stringValue.isEmpty ? nil : filterLangField.stringValue
        currentFilter.minConfidence = filterConfidenceSlider.doubleValue > 0 ? filterConfidenceSlider.doubleValue : nil
    }

    @objc private func applyFilters() {
        filterChanged()
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        performSearch(query: query, filter: currentFilter)
    }

    @objc private func resetFilters() {
        currentFilter = SearchFilter()
        searchField.stringValue = ""
        filterAppField.stringValue = ""
        filterLangField.stringValue = ""
        filterConfidenceSlider.doubleValue = 0.0
        loadRecent()
    }

    @objc private func savedSearchClicked(_ sender: CyberpunkButton) {
        guard let saved = savedSearches.first(where: { $0.id.hashValue == sender.tag }) else { return }
        currentFilter = saved.filter
        searchField.stringValue = saved.filter.query
        filterAppField.stringValue = saved.filter.app ?? ""
        filterLangField.stringValue = saved.filter.language ?? ""
        filterConfidenceSlider.doubleValue = saved.filter.minConfidence ?? 0.0
        performSearch(query: saved.filter.query, filter: saved.filter)
    }

    @objc private func smartCollectionClicked(_ sender: CyberpunkButton) {
        guard let collection = smartCollections.first(where: { $0.id.hashValue == sender.tag }) else { return }
        currentFilter = collection.filter
        searchField.stringValue = ""
        filterAppField.stringValue = ""
        filterLangField.stringValue = ""
        filterConfidenceSlider.doubleValue = collection.filter.minConfidence ?? 0.0
        performSearch(query: "", filter: collection.filter)
    }

    private func loadRecent() {
        clearResults()
        let records = TextcavatorDatabase.shared.recentCaptures(limit: 50)
        for record in records {
            let vc = SearchResultViewController(record: record, snippet: record.ocrText ?? "")
            vc.onSelect = { [weak self] in self?.openCapture(record) }
            vc.onQuickAction = { [weak self] action in self?.handleQuickAction(action, record: record) }
            stackView.addArrangedSubview(vc.view)
            resultControllers.append(vc)
        }
        updateEmptyState(count: records.count)
    }

    private func performSearch(query: String, filter: SearchFilter) {
        clearResults()
        let records = TextcavatorDatabase.shared.searchWithFilter(filter, limit: 100)
        for (record, snippet) in records {
            let vc = SearchResultViewController(record: record, snippet: snippet)
            vc.onSelect = { [weak self] in self?.openCapture(record) }
            vc.onQuickAction = { [weak self] action in self?.handleQuickAction(action, record: record) }
            stackView.addArrangedSubview(vc.view)
            resultControllers.append(vc)
        }
        updateEmptyState(count: records.count)
    }

    private func handleQuickAction(_ action: SearchResultViewController.QuickAction, record: CaptureRecord) {
        switch action {
        case .copy:
            if let text = record.ocrText {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(text, forType: .string)
            }
        case .redact:
            if let image = NSImage(contentsOfFile: record.imagePath) {
                let redactWC = RedactionWindowController(image: image)
                redactWC.captureId = record.id
                redactWC.onRedacted = { [weak self] redacted in
                    self?.openCapture(CaptureRecord(id: record.id, imagePath: record.imagePath, thumbnailPath: record.thumbnailPath, width: record.width, height: record.height, sourceApp: record.sourceApp, capturedAt: record.capturedAt, ocrText: record.ocrText, confidence: record.confidence, language: record.language, ocrStatus: record.ocrStatus))
                }
                redactWC.showWindow(nil)
            }
        case .delete:
            deleteCapture(record)
        case .openFile:
            NSWorkspace.shared.open(URL(fileURLWithPath: record.imagePath))
        }
    }

    private func deleteCapture(_ record: CaptureRecord) {
        try? FileManager.default.removeItem(atPath: record.imagePath)
        try? FileManager.default.removeItem(atPath: record.thumbnailPath ?? "")
        TextcavatorDatabase.shared.saveCapture(CaptureRecord(id: record.id, imagePath: "", thumbnailPath: nil, width: 0, height: 0, sourceApp: "", ocrStatus: "deleted"))
        loadRecent()
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
        return [.flexibleSpace, .init("captureArea")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("captureArea")]
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
        }
        return nil
    }

    @objc private func captureAreaTapped() {
        onCaptureArea?()
    }
}
