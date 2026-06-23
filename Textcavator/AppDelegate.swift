import AppKit
import Carbon
import Vision

enum CaptureMode {
    case area
    case window
    case fullScreen
    case scroll
    case batch
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var progressPopover: ProgressPopoverWindowController!
    private var settingsWindow: SettingsWindowController?
    private var searchWindow: SearchWindowController?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isCapturing = false
    private var batchRemaining: Int = 0
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupGlobalHotKeys()
        runPrivacySanityCheck()
        checkFirstLaunch()
        
        if SettingsManager.shared.showNotifications {
            showNotification(title: "Textcavator", message: LocalizedText.value("launchNotification"))
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanupEventTap()
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            showOnboarding()
        }
    }
    
    private func showOnboarding() {
        let alert = NSAlert()
        alert.messageText = LocalizedText.value("welcome")
        alert.informativeText = LocalizedText.value("onboarding")
        alert.addButton(withTitle: LocalizedText.value("openSettings"))
        alert.addButton(withTitle: LocalizedText.value("later"))
        
        if alert.runModal() == .alertFirstButtonReturn {
            openSystemSettings()
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func setupStatusBar() {
        statusBarController = StatusBarController()
        
        statusBarController.onCaptureArea = { [weak self] in
            self?.captureScreenshot(mode: .area)
        }
        
        statusBarController.onCaptureWindow = { [weak self] in
            self?.captureScreenshot(mode: .window)
        }

        statusBarController.onCaptureFullScreen = { [weak self] in
            self?.captureFullScreen()
        }

        statusBarController.onCaptureScroll = { [weak self] in
            self?.captureScreenshot(mode: .scroll)
        }

        statusBarController.onCaptureBatch = { [weak self] in
            self?.captureScreenshot(mode: .batch)
        }
        
        statusBarController.onOpenSearch = { [weak self] in
            self?.openSearch()
        }
        
        statusBarController.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        
        statusBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func setupGlobalHotKeys() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
            return appDelegate.handleKeyEvent(proxy: proxy, type: type, event: event)
        }
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            checkAccessibilityPermissions()
        }
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let hasCommand = flags.contains(.maskCommand)
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        if hasCommand && hasControl && hasOption {
            let shortcuts = SettingsManager.shared.allShortcuts()
            for (mode, shortcutKey) in shortcuts where shortcutKey == keyCode && shortcutKey != 0 {
                switch mode {
                case .area:
                    DispatchQueue.main.async { [weak self] in
                        self?.captureScreenshot(mode: .area)
                    }
                case .window:
                    DispatchQueue.main.async { [weak self] in
                        self?.captureScreenshot(mode: .window)
                    }
                case .fullScreen:
                    DispatchQueue.main.async { [weak self] in
                        self?.captureFullScreen()
                    }
                case .scroll:
                    DispatchQueue.main.async { [weak self] in
                        self?.captureScreenshot(mode: .scroll)
                    }
                }
                return nil
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            print("Textcavator needs Accessibility permissions for global hotkeys.")
        }
    }
    
    private func cleanupEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    private func captureScreenshot(mode: CaptureMode) {
        guard !isCapturing else {
            UXSoundPlayer.shared.play(.cancel)
            return
        }

        if mode == .batch {
            batchRemaining = max(1, SettingsManager.shared.batchCaptureCount)
            isCapturing = true
            startBatchCapture(mode: .area)
            return
        }

        isCapturing = true

        CaptureOverlayController.shared.start(mode: mode) { [weak self] image in
            self?.isCapturing = false
            guard let image else { return }
            self?.processImage(image)
        }
    }

    private func startBatchCapture(mode: CaptureMode) {
        guard batchRemaining > 0 else {
            isCapturing = false
            progressPopover?.complete()
            UXSoundPlayer.shared.play(.complete)
            return
        }

        CaptureOverlayController.shared.start(mode: mode) { [weak self] image in
            guard let self = self else { return }
            guard let image else {
                self.batchRemaining = 0
                self.isCapturing = false
                self.progressPopover?.complete()
                return
            }
            self.processImage(image)
            self.batchRemaining -= 1
            if self.batchRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + SettingsManager.shared.batchCaptureInterval) {
                    self.startBatchCapture(mode: mode)
                }
            } else {
                self.isCapturing = false
                self.progressPopover?.updateProgress(1.0, status: "Batch complete")
                self.progressPopover?.complete()
                UXSoundPlayer.shared.play(.complete)
            }
        }
    }

    private func captureFullScreen() {
        guard !isCapturing else {
            UXSoundPlayer.shared.play(.cancel)
            return
        }
        isCapturing = true
        guard showProgressPopover() else {
            isCapturing = false
            return
        }
        progressPopover.updateProgress(0.08, status: "Capturing all screens...")

        let screens = NSScreen.screens
        guard let first = screens.first else {
            isCapturing = false
            progressPopover.updateProgress(1.0, status: "No screens found")
            progressPopover.complete()
            return
        }
        var combinedRect = first.frame
        screens.dropFirst().forEach { combinedRect = combinedRect.union($0.frame) }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let cgImage = CGWindowListCreateImage(combinedRect, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution]) else {
                DispatchQueue.main.async {
                    self?.isCapturing = false
                    self?.progressPopover?.updateProgress(1.0, status: "Capture failed")
                    self?.progressPopover?.complete()
                }
                return
            }
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            DispatchQueue.main.async {
                self?.processImage(image)
                self?.isCapturing = false
            }
        }
    }
    
    private func processImage(_ image: NSImage) {
        let tempPath = "/tmp/textcavator_last_capture.png"
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [.compressionFactor: 0.8]) {
            try? pngData.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
        }

        if SettingsManager.shared.showCapturePreview {
            let preview = CapturePreviewWindowController(image: image)
            preview.onConfirm = { [weak self] in
                self?.continueWithOCR(image: image)
            }
            preview.onRetake = { [weak self] in
                self?.progressPopover?.complete()
            }
            preview.showAndWait()
        } else {
            continueWithOCR(image: image)
        }
    }

    private func continueWithOCR(image: NSImage) {
        guard showProgressPopover() else { return }
        progressPopover.updateProgress(0.08, status: "Image buffered locally")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.performOCR(on: image)
        }
    }
    
    private func showProgressPopover() -> Bool {
        guard let button = statusBarController.statusItem.button else { return false }
        progressPopover = ProgressPopoverWindowController()
        progressPopover.show(relativeTo: button.bounds, of: button)
        return true
    }
    
    private func performOCR(on image: NSImage) {
        guard let progressPopover = progressPopover else { return }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            progressPopover.updateProgress(1.0, status: "Failed to process image")
            progressPopover.complete()
            return
        }

        let lang = SettingsManager.shared.languageCode
        let engine = OCRPluginManager.shared.activeEngine()?.name ?? "Unknown"

        progressPopover.updateProgress(0.32, status: "Extracting text with \(engine)...")

        Task { @MainActor in
            do {
                let result = try await OCRPluginManager.shared.recognizeText(in: image, language: lang)
                self.handleOutput(
                    text: result.text,
                    confidence: result.confidence,
                    observations: result.regions.enumerated().compactMap { idx, region in
                        let obs = VNRecognizedTextObservation()
                        obs.boundingBox = region.boundingBox
                        let candidate = VNRecognizedTextCandidateSpecifier()
                        candidate.string = region.text
                        candidate.confidence = region.confidence
                        obs.topCandidates = [candidate]
                        return obs
                    },
                    image: image
                )
            } catch {
                progressPopover.updateProgress(1.0, status: "OCR Error: \(error.localizedDescription)")
                progressPopover.complete()
                UXSoundPlayer.shared.play(.cancel)
            }
        }
    }
    
    private func handleOutput(text: String, confidence: Double = 0.0, observations: [VNRecognizedTextObservation] = [], image: NSImage? = nil) {
        guard let progressPopover = progressPopover else { return }
        let settings = SettingsManager.shared

        if settings.showOCRReview, let image = image, !observations.isEmpty {
            progressPopover.updateProgress(0.95, status: "Awaiting review...")
            showOCRReviewWindow(image: image, observations: observations, text: text, confidence: confidence)
        } else {
            progressPopover.updateProgress(0.88, status: "Saving output...")
            finalizeOutput(text: text, confidence: confidence)
            progressPopover.updateProgress(1.0, status: "Done")
            progressPopover.complete()
            UXSoundPlayer.shared.play(.complete)
        }
    }

    private func showOCRReviewWindow(image: NSImage, observations: [VNRecognizedTextObservation], text: String, confidence: Double) {
        let reviewWindow = OCRReviewWindowController(
            image: image,
            observations: observations
        ) { [weak self] confirmedText, _ in
            guard let self = self else { return }
            self.finalizeOutput(text: confirmedText, confidence: confidence)
            if SettingsManager.shared.autoDeleteScreenshot {
                self.autoDeleteLastCapture()
            }
            self.progressPopover?.updateProgress(1.0, status: "Done")
            self.progressPopover?.complete()
            UXSoundPlayer.shared.play(.complete)
        } rescan: { [weak self] in
            guard let self = self else { return }
            self.progressPopover?.updateProgress(0.52, status: "Re-scanning image...")
            self.rerunOCR(on: image)
        } cancel: { [weak self] in
            guard let self = self else { return }
            self.progressPopover?.updateProgress(1.0, status: "Cancelled")
            self.progressPopover?.complete()
            UXSoundPlayer.shared.play(.cancel)
        }
        reviewWindow.show()
    }

    private func rerunOCR(on image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error {
                    self.progressPopover?.updateProgress(1.0, status: "Rescan Error: \(error.localizedDescription)")
                    self.progressPopover?.complete()
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    self.progressPopover?.updateProgress(1.0, status: "No text found on rescan")
                    self.progressPopover?.complete()
                    return
                }
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                let avgConfidence = observations.compactMap { $0.topCandidates(1).first?.confidence }.reduce(0.0, +) / Double(observations.count)
                self.handleOutput(text: text, confidence: avgConfidence, observations: observations, image: image)
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func finalizeOutput(text: String, confidence: Double) {
        let settings = SettingsManager.shared
        saveToDatabase(text: text, confidence: confidence)

        Task { @MainActor in
            if let lastCaptureId = TextcavatorDatabase.shared.recentCaptures(limit: 1).first?.id {
                if settings.enableHybridSearch || settings.enableCrossReference {
                    let embeddings = try? await EmbeddingManager.shared.embed(text)
                    if settings.enableHybridSearch, let embedding = embeddings {
                        TextcavatorDatabase.shared.saveKnowledgeAsset(
                            captureId: lastCaptureId,
                            assetType: "embedding",
                            content: nil,
                            embedding: embedding,
                            modelVersion: EmbeddingManager.shared.activePlugin()?.name ?? "unknown"
                        )
                    }
                    if settings.enableCrossReference {
                        let allIds = TextcavatorDatabase.shared.recentCaptures(limit: 1000).map(\.id)
                        await CrossReferenceEngine.shared.analyzeCapture(
                            lastCaptureId,
                            text: text,
                            app: "Unknown",
                            existingCaptureIds: allIds
                        )
                        for relation in CrossReferenceEngine.shared.findRelated(to: lastCaptureId, limit: 5) {
                            // Relations are already stored in the graph manager
                            // We could persist them here if needed
                        }
                    }
                }
            }
        }

        switch settings.outputMode {
        case .clipboard:
            copyToClipboard(text: text)
        case .textFile:
            saveToTextFile(text: text)
        }
    }

    private func autoDeleteLastCapture() {
        let tempPath = "/tmp/textcavator_last_capture.png"
        try? FileManager.default.removeItem(atPath: tempPath)
    }

    private func saveToDatabase(text: String, confidence: Double) {
        guard SettingsManager.shared.autoSaveToDatabase else { return }

        let minConfidence = SettingsManager.shared.minConfidence
        let shouldSave = confidence >= minConfidence || minConfidence == 0.0

        let status: String
        if shouldSave {
            status = "complete"
        } else {
            status = "filtered"
        }

        let record = CaptureRecord(
            imagePath: "/tmp/textcavator_last_capture.png",
            width: 0,
            height: 0,
            sourceApp: "Unknown",
            capturedAt: Date(),
            ocrText: shouldSave ? text : nil,
            confidence: confidence,
            language: SettingsManager.shared.languageCode,
            ocrStatus: status
        )

        TextcavatorDatabase.shared.saveCapture(record)
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        if SettingsManager.shared.showNotifications {
            showNotification(title: "Textcavator", message: LocalizedText.value("copied"))
        }
    }
    
    private func saveToTextFile(text: String) {
        let settings = SettingsManager.shared
        let folder: String
        if let outputFolder = settings.outputFolder {
            folder = outputFolder.path
        } else {
            folder = NSTemporaryDirectory()
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "textcavator_\(dateFormatter.string(from: Date())).txt"
        let filePath = (folder as NSString).appendingPathComponent(filename)
        
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
            
            if SettingsManager.shared.showNotifications {
                showNotification(title: "Textcavator", message: LocalizedText.value("saved") + filename)
            }
        } catch {
            showNotification(title: "Textcavator", message: LocalizedText.value("failedSave") + error.localizedDescription)
        }
    }
    
    private func openSearch() {
        if searchWindow == nil {
            searchWindow = SearchWindowController()
            searchWindow?.onCaptureArea = { [weak self] in
                self?.captureScreenshot(mode: .area)
            }
            searchWindow?.onCaptureWindow = { [weak self] in
                self?.captureScreenshot(mode: .window)
            }
        }
        searchWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.onCaptureArea = { [weak self] in
            self?.settingsWindow?.window?.orderOut(nil)
            self?.captureScreenshot(mode: .area)
        }
        settingsWindow?.onCaptureWindow = { [weak self] in
            self?.settingsWindow?.window?.orderOut(nil)
            self?.captureScreenshot(mode: .window)
        }
        settingsWindow?.showWindow()
    }
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func runPrivacySanityCheck() {
        print(LocalizedText.value("privacy"))
    }
}
