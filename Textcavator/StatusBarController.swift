import AppKit

class StatusBarController {
    
    private(set) var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverViewController: StatusBarPopoverViewController!
    private var eventMonitor: Any?
    
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    
    override func loadView() {
        view = CyberpunkCard(frame: NSRect(x: 0, y: 0, width: 360, height: 620))
        (view as? CyberpunkCard)?.glowColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCaptureModeIndicator()
        refreshLanguageButton()
        view.alphaValue = 0
        view.layer?.transform = CATransform3DMakeScale(0.965, 0.965, 1)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.view.animator().alphaValue = 1
                self.view.layer?.transform = CATransform3DIdentity
            }
        }
    }
    
    private func setupUI() {
        let background = HUDGridBackgroundView(frame: view.bounds)
        view.addSubview(background)
        background.autoresizingMask = [.width, .height]
        
        titleLabel = createLabel(text: LocalizedText.value("app"), fontSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 22, y: 606, width: 280, height: 28)
        view.addSubview(titleLabel)
        
        subtitleLabel = createLabel(text: LocalizedText.value("subtitle"), fontSize: 10.5, weight: .regular)
        subtitleLabel.textColor = HUDPalette.mutedText
        subtitleLabel.frame = NSRect(x: 22, y: 588, width: 280, height: 16)
        view.addSubview(subtitleLabel)
        
        languageAvatar = LanguageAvatarButton(frame: NSRect(x: 306, y: 606, width: 34, height: 34))
        languageAvatar.languageCode = SettingsManager.shared.languageCode
        languageAvatar.target = self
        languageAvatar.action = #selector(languageAvatarClicked)
        view.addSubview(languageAvatar)
        
        flagMenuView = FlagMenuView(frame: NSRect(x: 22, y: 546, width: 316, height: 32))
        flagMenuView.onCaptureArea = { [weak self] in self?.onCaptureArea?() }
        flagMenuView.onCaptureWindow = { [weak self] in self?.onCaptureWindow?() }
        view.addSubview(flagMenuView)
        
        heroView = AnimatedHeroView(frame: NSRect(x: 22, y: 406, width: 316, height: 130))
        view.addSubview(heroView)
        
        headlineLabel = createLabel(text: LocalizedText.value("heroHeadline"), fontSize: 17, weight: .bold)
        headlineLabel.frame = NSRect(x: 18, y: 94, width: 280, height: 24)
        heroView.addSubview(headlineLabel)
        
        subheadlineLabel = createLabel(text: LocalizedText.value("heroSubheading"), fontSize: 10.5, weight: .regular)
        subheadlineLabel.textColor = HUDPalette.mutedText
        subheadlineLabel.lineBreakMode = .byWordWrapping
        subheadlineLabel.frame = NSRect(x: 18, y: 50, width: 280, height: 38)
        heroView.addSubview(subheadlineLabel)
        
        let statLanguages = StatPillView(frame: NSRect(x: 22, y: 354, width: 60, height: 42))
        statLanguages.valueText = LocalizedText.value("statLanguages")
        statLanguages.labelText = LocalizedText.value("statLanguagesCaption")
        view.addSubview(statLanguages)
        let statModes = StatPillView(frame: NSRect(x: 88, y: 354, width: 58, height: 42))
        statModes.valueText = LocalizedText.value("statModes")
        statModes.labelText = LocalizedText.value("statModesCaption")
        view.addSubview(statModes)
        let statCloud = StatPillView(frame: NSRect(x: 152, y: 354, width: 60, height: 42))
        statCloud.valueText = LocalizedText.value("statCloud")
        statCloud.labelText = LocalizedText.value("statCloudCaption")
        view.addSubview(statCloud)
        let statHotkeys = StatPillView(frame: NSRect(x: 218, y: 354, width: 58, height: 42))
        statHotkeys.valueText = LocalizedText.value("statHotkeys")
        statHotkeys.labelText = LocalizedText.value("statHotkeysCaption")
        view.addSubview(statHotkeys)
        let statOutput = StatPillView(frame: NSRect(x: 282, y: 354, width: 56, height: 42))
        statOutput.valueText = LocalizedText.value("statOutput")
        statOutput.labelText = LocalizedText.value("statOutputCaption")
        view.addSubview(statOutput)
        
        areaButton = CyberpunkButton(frame: NSRect(x: 22, y: 294, width: 146, height: 50))
        areaButton.title = LocalizedText.value("crosshair")
        areaButton.glowColor = HUDPalette.cyan
        areaButton.target = self
        areaButton.action = #selector(captureAreaClicked)
        view.addSubview(areaButton)
        
        windowButton = CyberpunkButton(frame: NSRect(x: 192, y: 294, width: 146, height: 50))
        windowButton.title = LocalizedText.value("window")
        windowButton.glowColor = HUDPalette.violet
        windowButton.target = self
        windowButton.action = #selector(captureWindowClicked)
        view.addSubview(windowButton)
        
        captureModeLabel = createLabel(text: LocalizedText.value("areaReady"), fontSize: 11, weight: .medium)
        captureModeLabel.alignment = .center
        captureModeLabel.textColor = HUDPalette.mint
        captureModeLabel.frame = NSRect(x: 22, y: 268, width: 316, height: 18)
        view.addSubview(captureModeLabel)
        
        let chipOne = createChip(text: LocalizedText.value("chipOcr"), x: 22, y: 242, width: 142)
        view.addSubview(chipOne)
        let chipTwo = createChip(text: LocalizedText.value("chipShortcuts"), x: 174, y: 242, width: 164)
        view.addSubview(chipTwo)
        let chipThree = createChip(text: LocalizedText.value("chipEffects"), x: 22, y: 218, width: 142)
        view.addSubview(chipThree)
        let chipFour = createChip(text: LocalizedText.value("chipEsc"), x: 174, y: 218, width: 164)
        view.addSubview(chipFour)
        
        featuresTitleLabel = createLabel(text: LocalizedText.value("featuresTitle"), fontSize: 13, weight: .bold)
        featuresTitleLabel.frame = NSRect(x: 22, y: 196, width: 316, height: 16)
        view.addSubview(featuresTitleLabel)
        
        localFeature = FeatureCardView(frame: NSRect(x: 22, y: 158, width: 316, height: 34))
        localFeature.configure(icon: "◈", title: LocalizedText.value("featureLocal"), body: LocalizedText.value("featureLocalBody"), glow: HUDPalette.cyan)
        view.addSubview(localFeature)
        
        privateFeature = FeatureCardView(frame: NSRect(x: 22, y: 122, width: 316, height: 34))
        privateFeature.configure(icon: "◇", title: LocalizedText.value("featurePrivate"), body: LocalizedText.value("featurePrivateBody"), glow: HUDPalette.mint)
        view.addSubview(privateFeature)
        
        speedFeature = FeatureCardView(frame: NSRect(x: 22, y: 86, width: 154, height: 34))
        speedFeature.configure(icon: "⌁", title: LocalizedText.value("featureFast"), body: LocalizedText.value("featureFastBody"), glow: HUDPalette.violet)
        view.addSubview(speedFeature)
        
        globalFeature = FeatureCardView(frame: NSRect(x: 184, y: 86, width: 154, height: 34))
        globalFeature.configure(icon: "⚑", title: LocalizedText.value("featureGlobal"), body: LocalizedText.value("featureGlobalBody"), glow: HUDPalette.amber)
        view.addSubview(globalFeature)
        
        socialProofCard = CyberpunkCard(frame: NSRect(x: 22, y: 48, width: 316, height: 34))
        socialProofCard.glowColor = HUDPalette.cyan
        view.addSubview(socialProofCard)
        let proofTitle = createLabel(text: LocalizedText.value("socialProofTitle"), fontSize: 10, weight: .bold)
        proofTitle.frame = NSRect(x: 12, y: 19, width: 292, height: 12)
        socialProofCard.addSubview(proofTitle)
        let proofBody = createLabel(text: LocalizedText.value("socialProofBody"), fontSize: 8.5, weight: .regular)
        proofBody.textColor = HUDPalette.mutedText
        proofBody.frame = NSRect(x: 12, y: 6, width: 292, height: 12)
        socialProofCard.addSubview(proofBody)
        
        let searchButton = CyberpunkButton(frame: NSRect(x: 22, y: 16, width: 140, height: 30))
        searchButton.title = "Search Vault"
        searchButton.glowColor = HUDPalette.amber
        searchButton.target = self
        searchButton.action = #selector(searchClicked)
        view.addSubview(searchButton)
        
        settingsButton = CyberpunkButton(frame: NSRect(x: 166, y: 16, width: 120, height: 30))
        settingsButton.title = LocalizedText.value("settings")
        settingsButton.glowColor = HUDPalette.cyan
        settingsButton.target = self
        settingsButton.action = #selector(settingsClicked)
        view.addSubview(settingsButton)
        
        quitButton = CyberpunkButton(frame: NSRect(x: 290, y: 16, width: 60, height: 30))
        quitButton.title = "Quit"
        quitButton.glowColor = NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.48, alpha: 1.0)
        quitButton.target = self
        quitButton.action = #selector(quitClicked)
        view.addSubview(quitButton)
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
    
    private func createChip(text: String, x: CGFloat, y: CGFloat, width: CGFloat) -> NSTextField {
        let chip = NSTextField()
        chip.stringValue = text
        chip.font = NSFont.monospacedSystemFont(ofSize: 8.8, weight: .semibold)
        chip.textColor = HUDPalette.mutedText
        chip.backgroundColor = .clear
        chip.isBordered = false
        chip.isEditable = false
        chip.isSelectable = false
        chip.wantsLayer = true
        chip.layer?.cornerRadius = 9
        chip.layer?.borderColor = HUDPalette.cyan.withAlphaComponent(0.22).cgColor
        chip.layer?.borderWidth = 1
        chip.layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.55).cgColor
        chip.frame = NSRect(x: x, y: y, width: width, height: 18)
        return chip
    }
    
    func refreshLanguageButton() {
        languageAvatar.languageCode = SettingsManager.shared.languageCode
    }
    
    func updateCaptureModeIndicator() {
        let mode = SettingsManager.shared.captureMode
        if mode == .area {
            captureModeLabel.stringValue = LocalizedText.value("areaReady")
            captureModeLabel.textColor = HUDPalette.mint
        } else {
            captureModeLabel.stringValue = LocalizedText.value("windowReady")
            captureModeLabel.textColor = HUDPalette.violet
        }
        flagMenuView.updateSelected(mode: mode == .area ? CaptureMode.area : .window)
        areaButton.isSelected = mode == .area
        windowButton.isSelected = mode == .window
    }
    
    private func refreshLocalizedUI(animated: Bool = true) {
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                view.animator().alphaValue = 0
                view.layer?.transform = CATransform3DMakeScale(0.985, 0.985, 1)
            } completionHandler: { [weak self] in
                self?.applyLocalizedStrings()
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.24
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self?.view.animator().alphaValue = 1
                    self?.view.layer?.transform = CATransform3DIdentity
                }
            }
        } else {
            applyLocalizedStrings()
        }
    }
    
    private func applyLocalizedStrings() {
        titleLabel.stringValue = LocalizedText.value("app")
        subtitleLabel.stringValue = LocalizedText.value("subtitle")
        flagMenuView.buttonTitle = LocalizedText.value("flagMenu")
        headlineLabel.stringValue = LocalizedText.value("heroHeadline")
        subheadlineLabel.stringValue = LocalizedText.value("heroSubheading")
        areaButton.title = LocalizedText.value("crosshair")
        windowButton.title = LocalizedText.value("window")
        featuresTitleLabel.stringValue = LocalizedText.value("featuresTitle")
        localFeature.configure(icon: "◈", title: LocalizedText.value("featureLocal"), body: LocalizedText.value("featureLocalBody"), glow: HUDPalette.cyan)
        privateFeature.configure(icon: "◇", title: LocalizedText.value("featurePrivate"), body: LocalizedText.value("featurePrivateBody"), glow: HUDPalette.mint)
        speedFeature.configure(icon: "⌁", title: LocalizedText.value("featureFast"), body: LocalizedText.value("featureFastBody"), glow: HUDPalette.violet)
        globalFeature.configure(icon: "⚑", title: LocalizedText.value("featureGlobal"), body: LocalizedText.value("featureGlobalBody"), glow: HUDPalette.amber)
        settingsButton.title = LocalizedText.value("settings")
        quitButton.title = "Quit"
    }
    
    @objc private func languageAvatarClicked() {
        UXSoundPlayer.shared.play(.select)
        let picker = LanguagePickerViewController()
        picker.onLanguageSelected = { [weak self] language in
            guard let self else { return }
            let confirmation = LanguageConfirmationWindowController(language: language) {
                SettingsManager.shared.languageCode = language.code
                self.refreshLocalizedUI(animated: true)
                self.refreshLanguageButton()
                self.updateCaptureModeIndicator()
            } cancel: {
                self.refreshLanguageButton()
            }
            confirmation.show()
        }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = picker
        popover.contentSize = NSSize(width: 420, height: 360)
        popover.show(relativeTo: languageAvatar.bounds, of: languageAvatar, preferredEdge: .minY)
    }
    
    @objc private func captureAreaClicked() {
        SettingsManager.shared.captureMode = .area
        UXSoundPlayer.shared.play(.select)
        onCaptureArea?()
    }
    
    @objc private func captureWindowClicked() {
        SettingsManager.shared.captureMode = .window
        UXSoundPlayer.shared.play(.select)
        onCaptureWindow?()
    }

    @objc private func searchClicked() {
        UXSoundPlayer.shared.play(.select)
        onOpenSearch?()
    }

    @objc private func settingsClicked() {
        onOpenSettings?()
    }
    
    @objc private func quitClicked() {
        onQuit?()
    }
}
