import AppKit

class SettingsViewController: NSViewController, NSTextFieldDelegate {
    
    private var outputModeSegment: CyberpunkSegmentedControl!
    private var folderPathField: CyberpunkTextField!
    private var notificationsSwitch: NSSwitch!
    private var launchAtLoginSwitch: NSSwitch!
    private var soundEffectsSwitch: NSSwitch!
    private var particleEffectsSwitch: NSSwitch!
    private var autoSaveSwitch: NSSwitch!
    private var darkPaletteSwitch: NSSwitch!
    private var showOCRReviewSwitch: NSSwitch!
    private var autoDeleteScreenshotSwitch: NSSwitch!
    private var scrollStepsField: NSTextField!
    private var scrollStepsLabel: NSTextField!
    private var shortcutAreaBtn: CyberpunkButton!
    private var shortcutWindowBtn: CyberpunkButton!
    private var shortcutFullScreenBtn: CyberpunkButton!
    private var shortcutScrollBtn: CyberpunkButton!
    private var shortcutResetBtn: CyberpunkButton!
    private var shortcutWarningLabel: NSTextField!
    private var showPreviewSwitch: NSSwitch!
    private var batchCountField: NSTextField!
    private var batchIntervalField: NSTextField!
    private var hybridSwitch: NSSwitch!
    private var summarizationSwitch: NSSwitch!
    private var crossRefSwitch: NSSwitch!
    private var confidenceSlider: NSSlider!
    private var confidenceLabel: NSTextField!
    private var crosshairFlagBtn: CyberpunkButton!
    private var windowFlagBtn: CyberpunkButton!
    
    var onClose: (() -> Void)?
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    
    override func loadView() {
        view = CyberpunkCard(frame: NSRect(x: 0, y: 0, width: 480, height: 560))
        (view as? CyberpunkCard)?.glowColor = NSColor(calibratedRed: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
        view.alphaValue = 0
        view.animator().alphaValue = 1
    }
    
    private func setupUI() {
        let background = HUDGridBackgroundView(frame: view.bounds)
        view.addSubview(background)
        background.autoresizingMask = [.width, .height]
        
        let titleLabel = createLabel(text: "Settings HUD", fontSize: 22, weight: .bold)
        titleLabel.frame = NSRect(x: 24, y: 416, width: 432, height: 30)
        view.addSubview(titleLabel)
        
        let subtitleLabel = createLabel(text: "Local OCR routing, capture flags, and glass HUD preferences", fontSize: 11, weight: .regular)
        subtitleLabel.textColor = NSColor(white: 0.62, alpha: 1.0)
        subtitleLabel.frame = NSRect(x: 24, y: 396, width: 432, height: 16)
        view.addSubview(subtitleLabel)
        
        let flagSectionLabel = createLabel(text: "CAPTURE FLAGS", fontSize: 11, weight: .medium)
        flagSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        flagSectionLabel.frame = NSRect(x: 24, y: 360, width: 432, height: 16)
        view.addSubview(flagSectionLabel)
        
        let crosshairFlagBtn = CyberpunkButton(frame: NSRect(x: 24, y: 322, width: 205, height: 32))
        crosshairFlagBtn.title = "Crosshair Capture ⌃⌘⌥1"
        crosshairFlagBtn.glowColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        crosshairFlagBtn.target = self
        crosshairFlagBtn.action = #selector(crosshairFlagClicked)
        view.addSubview(crosshairFlagBtn)
        
        let windowFlagBtn = CyberpunkButton(frame: NSRect(x: 251, y: 322, width: 205, height: 32))
        windowFlagBtn.title = "Window Capture ⌃⌘⌥2"
        windowFlagBtn.glowColor = NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.65, alpha: 1.0)
        windowFlagBtn.target = self
        windowFlagBtn.action = #selector(windowFlagClicked)
        view.addSubview(windowFlagBtn)
        
        let outputSectionLabel = createLabel(text: "OUTPUT MODE", fontSize: 11, weight: .medium)
        outputSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        outputSectionLabel.frame = NSRect(x: 24, y: 288, width: 432, height: 16)
        view.addSubview(outputSectionLabel)
        
        outputModeSegment = CyberpunkSegmentedControl(frame: NSRect(x: 24, y: 256, width: 432, height: 34))
        outputModeSegment.segmentCount = 2
        outputModeSegment.setLabel("Clipboard", forSegment: 0)
        outputModeSegment.setLabel("Text File", forSegment: 1)
        outputModeSegment.selectedSegment = 0
        outputModeSegment.target = self
        outputModeSegment.action = #selector(outputModeChanged)
        view.addSubview(outputModeSegment)
        
        let folderSectionLabel = createLabel(text: "OUTPUT FOLDER", fontSize: 11, weight: .medium)
        folderSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        folderSectionLabel.frame = NSRect(x: 24, y: 224, width: 432, height: 16)
        view.addSubview(folderSectionLabel)
        
        folderPathField = CyberpunkTextField(frame: NSRect(x: 24, y: 190, width: 318, height: 30))
        folderPathField.placeholderString = "Select output folder..."
        view.addSubview(folderPathField)
        
        let browseBtn = CyberpunkButton(frame: NSRect(x: 354, y: 190, width: 102, height: 30))
        browseBtn.title = "Browse"
        browseBtn.glowColor = NSColor(calibratedRed: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
        browseBtn.target = self
        browseBtn.action = #selector(browseFolder)
        view.addSubview(browseBtn)
        
        let prefsSectionLabel = createLabel(text: "PREFERENCES", fontSize: 11, weight: .medium)
        prefsSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        prefsSectionLabel.frame = NSRect(x: 24, y: 158, width: 432, height: 16)
        view.addSubview(prefsSectionLabel)
        
        addSwitchRow(label: "Show Notifications", y: 128, switchView: &notificationsSwitch, action: #selector(notificationsToggled))
        addSwitchRow(label: "Launch at Login", y: 100, switchView: &launchAtLoginSwitch, action: #selector(launchAtLoginToggled))
        addSwitchRow(label: "Soft HUD Sounds", y: 72, switchView: &soundEffectsSwitch, action: #selector(soundToggled))
        addSwitchRow(label: "Particle Effects", y: 44, switchView: &particleEffectsSwitch, action: #selector(effectsToggled))
        addSwitchRow(label: "Auto-save to Vault", y: 16, switchView: &autoSaveSwitch, action: #selector(autoSaveToggled))
        addSwitchRow(label: "Dark Mode", y: -12, switchView: &darkPaletteSwitch, action: #selector(darkPaletteToggled))
        addSwitchRow(label: "OCR Review Step (off by default)", y: -40, switchView: &showOCRReviewSwitch, action: #selector(showOCRReviewToggled))
        addSwitchRow(label: "Auto-delete screenshot after copy", y: -68, switchView: &autoDeleteScreenshotSwitch, action: #selector(autoDeleteScreenshotToggled))

        let scrollSectionLabel = createLabel(text: "SCROLL CAPTURE", fontSize: 11, weight: .medium)
        scrollSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        scrollSectionLabel.frame = NSRect(x: 24, y: -96, width: 432, height: 16)
        view.addSubview(scrollSectionLabel)

        scrollStepsLabel = createLabel(text: "Max scroll steps: 50", fontSize: 12, weight: .regular)
        scrollStepsLabel.frame = NSRect(x: 24, y: -118, width: 432, height: 18)
        view.addSubview(scrollStepsLabel)

        scrollStepsField = NSTextField(frame: NSRect(x: 24, y: -140, width: 100, height: 22))
        scrollStepsField.stringValue = "50"
        scrollStepsField.delegate = self
        view.addSubview(scrollStepsField)

        let shortcutSectionLabel = createLabel(text: "KEYBOARD SHORTCUTS", fontSize: 11, weight: .medium)
        shortcutSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        shortcutSectionLabel.frame = NSRect(x: 24, y: -172, width: 432, height: 16)
        view.addSubview(shortcutSectionLabel)

        shortcutAreaBtn = createShortcutButton(title: "Crosshair Capture", keyCode: 18, y: -194, mode: .area)
        shortcutWindowBtn = createShortcutButton(title: "Window Capture", keyCode: 19, y: -224, mode: .window)
        shortcutFullScreenBtn = createShortcutButton(title: "Full Screen Capture", keyCode: 20, y: -254, mode: .fullScreen)
        shortcutScrollBtn = createShortcutButton(title: "Scroll Capture", keyCode: 21, y: -284, mode: .scroll)

        shortcutResetBtn = CyberpunkButton(frame: NSRect(x: 24, y: -316, width: 140, height: 26))
        shortcutResetBtn.title = "Reset to Defaults"
        shortcutResetBtn.glowColor = HUDPalette.amber
        shortcutResetBtn.target = self
        shortcutResetBtn.action = #selector(resetShortcutsClicked)
        view.addSubview(shortcutResetBtn)

        shortcutWarningLabel = NSTextField(labelWithString: "")
        shortcutWarningLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        shortcutWarningLabel.textColor = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 1.0)
        shortcutWarningLabel.frame = NSRect(x: 180, y: -316, width: 276, height: 26)
        shortcutWarningLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(shortcutWarningLabel)

        let filterSectionLabel = createLabel(text: "OCR CONFIDENCE FILTER", fontSize: 11, weight: .medium)
        filterSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        filterSectionLabel.frame = NSRect(x: 24, y: -356, width: 432, height: 16)
        view.addSubview(filterSectionLabel)

        confidenceLabel = createLabel(text: "Minimum Confidence: 50%", fontSize: 12, weight: .regular)
        confidenceLabel.frame = NSRect(x: 24, y: -378, width: 432, height: 18)
        view.addSubview(confidenceLabel)

        confidenceSlider = NSSlider(frame: NSRect(x: 24, y: -402, width: 432, height: 20))
        confidenceSlider.minValue = 0.0
        confidenceSlider.maxValue = 1.0
        confidenceSlider.doubleValue = 0.5
        confidenceSlider.target = self
        confidenceSlider.action = #selector(confidenceChanged)
        view.addSubview(confidenceSlider)

        let captureSectionLabel = createLabel(text: "CAPTURE OPTIONS", fontSize: 11, weight: .medium)
        captureSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        captureSectionLabel.frame = NSRect(x: 24, y: -468, width: 432, height: 16)
        view.addSubview(captureSectionLabel)

        showPreviewSwitch = NSSwitch()
        showPreviewSwitch.frame = NSRect(x: 416, y: -490, width: 40, height: 18)
        showPreviewSwitch.target = self
        showPreviewSwitch.action = #selector(showPreviewToggled)
        view.addSubview(showPreviewSwitch)
        let previewLabel = createLabel(text: "Show capture preview before OCR", fontSize: 12, weight: .regular)
        previewLabel.frame = NSRect(x: 24, y: -488, width: 380, height: 22)
        view.addSubview(previewLabel)

        let batchLabel = createLabel(text: "Batch capture count:", fontSize: 12, weight: .regular)
        batchLabel.frame = NSRect(x: 24, y: -518, width: 180, height: 22)
        view.addSubview(batchLabel)
        batchCountField = NSTextField(frame: NSRect(x: 220, y: -518, width: 60, height: 22))
        batchCountField.stringValue = "5"
        batchCountField.delegate = self
        view.addSubview(batchCountField)

        let batchIntervalLabel = createLabel(text: "Interval (sec):", fontSize: 12, weight: .regular)
        batchIntervalLabel.frame = NSRect(x: 24, y: -546, width: 180, height: 22)
        view.addSubview(batchIntervalLabel)
        batchIntervalField = NSTextField(frame: NSRect(x: 220, y: -546, width: 60, height: 22))
        batchIntervalField.stringValue = "2.0"
        batchIntervalField.delegate = self
        view.addSubview(batchIntervalField)

        let aiSectionLabel = createLabel(text: "AI & KNOWLEDGE", fontSize: 11, weight: .medium)
        aiSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        aiSectionLabel.frame = NSRect(x: 24, y: -576, width: 432, height: 16)
        view.addSubview(aiSectionLabel)

        var hybridSwitch = NSSwitch()
        hybridSwitch.frame = NSRect(x: 416, y: -598, width: 40, height: 18)
        hybridSwitch.target = self
        hybridSwitch.action = #selector(hybridSearchToggled)
        view.addSubview(hybridSwitch)
        let hybridLabel = createLabel(text: "Hybrid Search (vector + text)", fontSize: 12, weight: .regular)
        hybridLabel.frame = NSRect(x: 24, y: -596, width: 380, height: 22)
        view.addSubview(hybridLabel)

        var summarizationSwitch = NSSwitch()
        summarizationSwitch.frame = NSRect(x: 416, y: -626, width: 40, height: 18)
        summarizationSwitch.target = self
        summarizationSwitch.action = #selector(summarizationToggled)
        view.addSubview(summarizationSwitch)
        let summarizationLabel = createLabel(text: "AI Summarization", fontSize: 12, weight: .regular)
        summarizationLabel.frame = NSRect(x: 24, y: -624, width: 380, height: 22)
        view.addSubview(summarizationLabel)

        var crossRefSwitch = NSSwitch()
        crossRefSwitch.frame = NSRect(x: 416, y: -654, width: 40, height: 18)
        crossRefSwitch.target = self
        crossRefSwitch.action = #selector(crossRefToggled)
        view.addSubview(crossRefSwitch)
        let crossRefLabel = createLabel(text: "Cross-Reference Engine", fontSize: 12, weight: .regular)
        crossRefLabel.frame = NSRect(x: 24, y: -652, width: 380, height: 22)
        view.addSubview(crossRefLabel)

        let closeBtn = CyberpunkButton(frame: NSRect(x: 366, y: -694, width: 90, height: 28))
        closeBtn.title = "Done"
        closeBtn.glowColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        closeBtn.target = self
        closeBtn.action = #selector(closeClicked)
        view.addSubview(closeBtn)
    }
    
    private func addSwitchRow(label: String, y: CGFloat, switchView: inout NSSwitch, action: Selector) {
        let rowLabel = createLabel(text: label, fontSize: 12, weight: .regular)
        rowLabel.frame = NSRect(x: 24, y: y, width: 300, height: 22)
        view.addSubview(rowLabel)
        
        switchView = NSSwitch()
        switchView.frame = NSRect(x: 416, y: y + 2, width: 40, height: 18)
        switchView.target = self
        switchView.action = action
        view.addSubview(switchView)
    }

    private func createShortcutButton(title: String, keyCode: Int, y: CGFloat, mode: SettingsManager.CaptureMode) -> CyberpunkButton {
        let label = createLabel(text: title, fontSize: 12, weight: .regular)
        label.frame = NSRect(x: 24, y: y, width: 180, height: 22)
        view.addSubview(label)

        let btn = CyberpunkButton(frame: NSRect(x: 220, y: y, width: 140, height: 22))
        btn.title = keyName(for: keyCode)
        btn.glowColor = HUDPalette.cyan
        btn.tag = mode.rawValue.hashValue
        btn.target = self
        btn.action = #selector(shortcutButtonClicked(_:))
        view.addSubview(btn)
        return btn
    }

    private func keyName(for keyCode: Int) -> String {
        let mods = modifierString(for: SettingsManager.shared.allShortcuts().values.first { $0 == keyCode } != nil ? 0 : 0)
        let name: String
        switch keyCode {
        case 18: name = "1"
        case 19: name = "2"
        case 20: name = "3"
        case 21: name = "4"
        case 6:  name = "Z"
        case 7:  name = "X"
        case 8:  name = "C"
        case 9:  name = "V"
        default: name = "\(keyCode)"
        }
        return "⌃⌘⌥" + name
    }

    private func modifierString(for modifiers: UInt) -> String {
        return "⌃⌘⌥"
    }
    
    private func createLabel(text: String, fontSize: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = .white
        label.backgroundColor = .clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        return label
    }
    
    private func createLinkButton(title: String, url: String) -> NSTextField {
        let label = NSTextField()
        label.stringValue = title
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = NSColor(calibratedRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        label.backgroundColor = .clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        
        if let linkURL = URL(string: url) {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor(calibratedRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: linkURL
            ]
            label.attributedStringValue = NSAttributedString(string: title, attributes: attributes)
        }
        
        return label
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared

        outputModeSegment.selectedSegment = settings.outputMode == .clipboard ? 0 : 1
        folderPathField.stringValue = settings.outputFolder?.path ?? ""
        notificationsSwitch.state = settings.showNotifications ? .on : .off
        launchAtLoginSwitch.state = settings.launchAtLogin ? .on : .off
        soundEffectsSwitch.state = settings.soundEnabled ? .on : .off
        particleEffectsSwitch.state = settings.effectsEnabled ? .on : .off
        autoSaveSwitch.state = settings.autoSaveToDatabase ? .on : .off
        darkPaletteSwitch.state = settings.darkPalette ? .on : .off
        showOCRReviewSwitch.state = settings.showOCRReview ? .on : .off
        autoDeleteScreenshotSwitch.state = settings.autoDeleteScreenshot ? .on : .off
        scrollStepsField.stringValue = "\(settings.scrollCaptureSteps)"
        showPreviewSwitch.state = settings.showCapturePreview ? .on : .off
        batchCountField.stringValue = "\(settings.batchCaptureCount)"
        batchIntervalField.stringValue = String(format: "%.1f", settings.batchCaptureInterval)
        hybridSwitch.state = settings.enableHybridSearch ? .on : .off
        summarizationSwitch.state = settings.enableSummarization ? .on : .off
        crossRefSwitch.state = settings.enableCrossReference ? .on : .off

        shortcutAreaBtn.title = keyName(for: settings.shortcutArea)
        shortcutWindowBtn.title = keyName(for: settings.shortcutWindow)
        shortcutFullScreenBtn.title = keyName(for: settings.shortcutFullScreen)
        shortcutScrollBtn.title = keyName(for: settings.shortcutScroll)

        let areaKey = keyName(for: settings.shortcutArea)
        let windowKey = keyName(for: settings.shortcutWindow)
        crosshairFlagBtn.title = "Crosshair Capture \(areaKey)"
        windowFlagBtn.title = "Window Capture \(windowKey)"

        shortcutWarningLabel.stringValue = ""

        confidenceSlider.doubleValue = settings.minConfidence
        confidenceLabel.stringValue = String(format: "Minimum Confidence: %.0f%%", settings.minConfidence * 100)

        updateFolderFieldVisibility()
    }
    
    private func updateFolderFieldVisibility() {
        let isTextFileMode = outputModeSegment.selectedSegment == 1
        folderPathField.isHidden = !isTextFileMode
        view.subviews.first { $0.frame == NSRect(x: 354, y: 190, width: 102, height: 30) }?.isHidden = !isTextFileMode
    }
    
    @objc private func outputModeChanged() {
        let mode: SettingsManager.OutputMode = outputModeSegment.selectedSegment == 0 ? .clipboard : .textFile
        SettingsManager.shared.outputMode = mode
        updateFolderFieldVisibility()
    }
    
    @objc private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select output folder for text files"
        
        if panel.runModal() == .OK, let url = panel.url {
            folderPathField.stringValue = url.path
            SettingsManager.shared.outputFolder = url
        }
    }
    
    @objc private func notificationsToggled() {
        SettingsManager.shared.showNotifications = notificationsSwitch.state == .on
    }
    
    @objc private func launchAtLoginToggled() {
        SettingsManager.shared.launchAtLogin = launchAtLoginSwitch.state == .on
    }
    
    @objc private func soundToggled() {
        SettingsManager.shared.soundEnabled = soundEffectsSwitch.state == .on
        UXSoundPlayer.shared.play(.select)
    }
    
    @objc private func effectsToggled() {
        SettingsManager.shared.effectsEnabled = particleEffectsSwitch.state == .on
        UXSoundPlayer.shared.play(.select)
    }

    @objc private func autoSaveToggled() {
        SettingsManager.shared.autoSaveToDatabase = autoSaveSwitch.state == .on
    }

    @objc private func darkPaletteToggled() {
        SettingsManager.shared.darkPalette = darkPaletteSwitch.state == .on
    }

    @objc private func showOCRReviewToggled() {
        SettingsManager.shared.showOCRReview = showOCRReviewSwitch.state == .on
    }

    @objc private func autoDeleteScreenshotToggled() {
        SettingsManager.shared.autoDeleteScreenshot = autoDeleteScreenshotSwitch.state == .on
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        if let field = obj.object as? NSTextField, field == scrollStepsField {
            let value = Int(field.stringValue) ?? 50
            SettingsManager.shared.scrollCaptureSteps = max(10, min(200, value))
            scrollStepsField.stringValue = "\(SettingsManager.shared.scrollCaptureSteps)"
            scrollStepsLabel.stringValue = "Max scroll steps: \(SettingsManager.shared.scrollCaptureSteps)"
        } else if let field = obj.object as? NSTextField, field == batchCountField {
            let value = Int(field.stringValue) ?? 5
            SettingsManager.shared.batchCaptureCount = max(1, min(50, value))
            batchCountField.stringValue = "\(SettingsManager.shared.batchCaptureCount)"
        } else if let field = obj.object as? NSTextField, field == batchIntervalField {
            let value = Double(field.stringValue) ?? 2.0
            SettingsManager.shared.batchCaptureInterval = max(0.5, min(60.0, value))
            batchIntervalField.stringValue = String(format: "%.1f", SettingsManager.shared.batchCaptureInterval)
        }
    }

    @objc private func showPreviewToggled() {
        SettingsManager.shared.showCapturePreview = showPreviewSwitch.state == .on
    }

    @objc private func hybridSearchToggled() {
        SettingsManager.shared.enableHybridSearch = hybridSwitch.state == .on
    }

    @objc private func summarizationToggled() {
        SettingsManager.shared.enableSummarization = summarizationSwitch.state == .on
    }

    @objc private func crossRefToggled() {
        SettingsManager.shared.enableCrossReference = crossRefSwitch.state == .on
    }

    @objc private func confidenceChanged() {
        let value = confidenceSlider.doubleValue
        SettingsManager.shared.minConfidence = value
        confidenceLabel.stringValue = String(format: "Minimum Confidence: %.0f%%", value * 100)
    }
    
    @objc private func crosshairFlagClicked() {
        onCaptureArea?()
    }
    
    @objc private func windowFlagClicked() {
        onCaptureWindow?()
    }
    
    @objc private func openLink(_ sender: NSTextField) {
        if let url = URL(string: "https://soundcloud.com/lucky-clover") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func luckyCloverClicked() {
        if let url = URL(string: "https://soundcloud.com/lucky-clover") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func closeClicked() {
        onClose?()
    }

    private var activeRecorder: ShortcutRecorderWindowController?
    private var remappingMode: SettingsManager.CaptureMode?

    @objc private func shortcutButtonClicked(_ sender: CyberpunkButton) {
        guard let mode = modeFromTag(sender.tag) else { return }
        remappingMode = mode
        showShortcutRecorder(for: mode, button: sender)
    }

    private func modeFromTag(_ tag: Int) -> SettingsManager.CaptureMode? {
        switch tag {
        case SettingsManager.CaptureMode.area.rawValue.hashValue: return .area
        case SettingsManager.CaptureMode.window.rawValue.hashValue: return .window
        case SettingsManager.CaptureMode.fullScreen.rawValue.hashValue: return .fullScreen
        case SettingsManager.CaptureMode.scroll.rawValue.hashValue: return .scroll
        default: return nil
        }
    }

    private func showShortcutRecorder(for mode: SettingsManager.CaptureMode, button: CyberpunkButton) {
        let recorder = ShortcutRecorderWindowController()
        activeRecorder = recorder

        recorder.onShortcutRecorded = { [weak self] keyCode, modifiers in
            guard let self = self, let mode = self.remappingMode else { return }
            let settings = SettingsManager.shared

            if let conflict = settings.shortcutConflicts(for: mode, keyCode: keyCode) {
                self.shortcutWarningLabel.stringValue = "Conflict with \(modeName(conflict))! Reassigning..."
                settings.setShortcut(keyCode, for: mode)
                settings.setShortcut(0, for: conflict)
                UXSoundPlayer.shared.play(.complete)
            } else {
                settings.setShortcut(keyCode, for: mode)
                self.shortcutWarningLabel.stringValue = ""
                UXSoundPlayer.shared.play(.complete)
            }

            self.updateShortcutButtons()
            self.remappingMode = nil
            self.activeRecorder = nil
        }

        recorder.onCancelled = { [weak self] in
            self?.remappingMode = nil
            self?.activeRecorder = nil
            self?.shortcutWarningLabel.stringValue = ""
        }

        recorder.showCentered()
        UXSoundPlayer.shared.play(.arm)
    }

    @objc private func resetShortcutsClicked() {
        SettingsManager.shared.resetShortcutsToDefaults()
        updateShortcutButtons()
        shortcutWarningLabel.stringValue = ""
        UXSoundPlayer.shared.play(.complete)
    }

    private func updateShortcutButtons() {
        let settings = SettingsManager.shared
        shortcutAreaBtn.title = keyName(for: settings.shortcutArea)
        shortcutWindowBtn.title = keyName(for: settings.shortcutWindow)
        shortcutFullScreenBtn.title = keyName(for: settings.shortcutFullScreen)
        shortcutScrollBtn.title = keyName(for: settings.shortcutScroll)
    }

    private func modeName(_ mode: SettingsManager.CaptureMode) -> String {
        switch mode {
        case .area: return "Crosshair"
        case .window: return "Window"
        case .fullScreen: return "Full Screen"
        case .scroll: return "Scroll"
        case .batch: return "Batch"
        }
    }
}
