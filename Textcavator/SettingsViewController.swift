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
    private var confidenceSlider: NSSlider!
    private var confidenceLabel: NSTextField!
    
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
        crosshairFlagBtn.title = "Crosshair Capture ⌘⇧1"
        crosshairFlagBtn.glowColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        crosshairFlagBtn.target = self
        crosshairFlagBtn.action = #selector(crosshairFlagClicked)
        view.addSubview(crosshairFlagBtn)
        
        let windowFlagBtn = CyberpunkButton(frame: NSRect(x: 251, y: 322, width: 205, height: 32))
        windowFlagBtn.title = "Window Capture ⌘⇧2"
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

        let filterSectionLabel = createLabel(text: "OCR CONFIDENCE FILTER", fontSize: 11, weight: .medium)
        filterSectionLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        filterSectionLabel.frame = NSRect(x: 24, y: -172, width: 432, height: 16)
        view.addSubview(filterSectionLabel)

        confidenceLabel = createLabel(text: "Minimum Confidence: 50%", fontSize: 12, weight: .regular)
        confidenceLabel.frame = NSRect(x: 24, y: -194, width: 432, height: 18)
        view.addSubview(confidenceLabel)

        confidenceSlider = NSSlider(frame: NSRect(x: 24, y: -218, width: 432, height: 20))
        confidenceSlider.minValue = 0.0
        confidenceSlider.maxValue = 1.0
        confidenceSlider.doubleValue = 0.5
        confidenceSlider.target = self
        confidenceSlider.action = #selector(confidenceChanged)
        view.addSubview(confidenceSlider)

        let closeBtn = CyberpunkButton(frame: NSRect(x: 366, y: -262, width: 90, height: 28))
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
        }
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
}
