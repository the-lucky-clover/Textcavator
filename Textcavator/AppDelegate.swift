import AppKit
import Carbon
import Vision

enum CaptureMode {
    case area
    case window
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var progressPopover: ProgressPopoverWindowController!
    private var settingsWindow: SettingsWindowController?
    private var searchWindow: SearchWindowController?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isCapturing = false
    
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
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)
        
        if hasCommand && hasShift && !hasControl && !hasOption {
            if keyCode == 18 {
                DispatchQueue.main.async { [weak self] in
                    self?.captureScreenshot(mode: .area)
                }
                return nil
            } else if keyCode == 19 {
                DispatchQueue.main.async { [weak self] in
                    self?.captureScreenshot(mode: .window)
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
        isCapturing = true
        
        CaptureOverlayController.shared.start(mode: mode) { [weak self] image in
            self?.isCapturing = false
            guard let image else { return }
            self?.processImage(image)
        }
    }
    
    private func processImage(_ image: NSImage) {
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
        progressPopover.updateProgress(0.28, status: "Analyzing image locally...")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            progressPopover.updateProgress(1.0, status: "Failed to process image")
            progressPopover.complete()
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                guard let self, let progressPopover = self.progressPopover else { return }
                
                if let error = error {
                    progressPopover.updateProgress(1.0, status: "OCR Error: \(error.localizedDescription)")
                    progressPopover.complete()
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    progressPopover.updateProgress(1.0, status: "No text found")
                    progressPopover.complete()
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                let avgConfidence = observations.compactMap { obs in
                    obs.topCandidates(1).first?.confidence
                }.reduce(0.0, +) / Double(observations.count)

                self.handleOutput(text: recognizedText, confidence: avgConfidence)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        progressPopover.updateProgress(0.52, status: "Extracting text with Vision OCR...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self, let progressPopover = self.progressPopover else { return }
                    progressPopover.updateProgress(1.0, status: "OCR Error")
                    progressPopover.complete()
                }
            }
        }
    }
    
    private func handleOutput(text: String, confidence: Double = 0.0) {
        guard let progressPopover = progressPopover else { return }
        progressPopover.updateProgress(0.88, status: "Saving output...")

        let settings = SettingsManager.shared

        saveToDatabase(text: text, confidence: confidence)

        switch settings.outputMode {
        case .clipboard:
            copyToClipboard(text: text)
        case .textFile:
            saveToTextFile(text: text)
        }

        progressPopover.updateProgress(1.0, status: "Done")
        progressPopover.complete()
        UXSoundPlayer.shared.play(.complete)
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
