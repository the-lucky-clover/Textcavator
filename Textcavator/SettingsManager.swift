import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    enum OutputMode: String {
        case clipboard = "clipboard"
        case textFile = "textFile"
    }
    
    enum CaptureMode: String {
        case area = "area"
        case window = "window"
        case fullScreen = "fullScreen"
        case scroll = "scroll"
    }
    
    private enum Keys {
        static let outputMode = "textcavator.outputMode"
        static let outputFolder = "textcavator.outputFolder"
        static let launchAtLogin = "textcavator.launchAtLogin"
        static let showNotifications = "textcavator.showNotifications"
        static let captureMode = "textcavator.captureMode"
        static let soundEnabled = "textcavator.soundEnabled"
        static let effectsEnabled = "textcavator.effectsEnabled"
        static let languageCode = "textcavator.languageCode"
        static let minConfidence = "textcavator.minConfidence"
        static let autoSaveToDatabase = "textcavator.autoSaveToDatabase"
        static let darkPalette = "textcavator.darkPalette"
        static let showOCRReview = "textcavator.showOCRReview"
        static let autoDeleteScreenshot = "textcavator.autoDeleteScreenshot"
        static let scrollCaptureSteps = "textcavator.scrollCaptureSteps"
        static let shortcutArea = "textcavator.shortcutArea"
        static let shortcutWindow = "textcavator.shortcutWindow"
        static let shortcutFullScreen = "textcavator.shortcutFullScreen"
        static let shortcutScroll = "textcavator.shortcutScroll"
        static let showCapturePreview = "textcavator.showCapturePreview"
        static let batchCaptureCount = "textcavator.batchCaptureCount"
        static let batchCaptureInterval = "textcavator.batchCaptureInterval"
        static let enableHybridSearch = "textcavator.enableHybridSearch"
        static let enableSummarization = "textcavator.enableSummarization"
        static let enableCrossReference = "textcavator.enableCrossReference"
    }
    
    var outputMode: OutputMode {
        get {
            let raw = defaults.string(forKey: Keys.outputMode) ?? OutputMode.clipboard.rawValue
            return OutputMode(rawValue: raw) ?? .clipboard
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.outputMode)
        }
    }
    
    var outputFolder: URL? {
        get {
            defaults.string(forKey: Keys.outputFolder).flatMap { URL(string: $0) }
        }
        set {
            defaults.set(newValue?.absoluteString, forKey: Keys.outputFolder)
        }
    }
    
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
    
    var showNotifications: Bool {
        get { defaults.bool(forKey: Keys.showNotifications) }
        set { defaults.set(newValue, forKey: Keys.showNotifications) }
    }
    
    var captureMode: CaptureMode {
        get {
            let raw = defaults.string(forKey: Keys.captureMode) ?? CaptureMode.area.rawValue
            return CaptureMode(rawValue: raw) ?? .area
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.captureMode)
        }
    }
    
    var soundEnabled: Bool {
        get { defaults.bool(forKey: Keys.soundEnabled) }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }
    
    var effectsEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.effectsEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.effectsEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.effectsEnabled) }
    }
    
    var languageCode: String {
        get { defaults.string(forKey: Keys.languageCode) ?? "en-US" }
        set { defaults.set(newValue, forKey: Keys.languageCode) }
    }

    var minConfidence: Double {
        get { defaults.double(forKey: Keys.minConfidence) }
        set { defaults.set(newValue, forKey: Keys.minConfidence) }
    }

    var autoSaveToDatabase: Bool {
        get {
            if defaults.object(forKey: Keys.autoSaveToDatabase) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.autoSaveToDatabase)
        }
        set { defaults.set(newValue, forKey: Keys.autoSaveToDatabase) }
    }

    var darkPalette: Bool {
        get {
            if defaults.object(forKey: Keys.darkPalette) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.darkPalette)
        }
        set { defaults.set(newValue, forKey: Keys.darkPalette) }
    }

    var showOCRReview: Bool {
        get {
            if defaults.object(forKey: Keys.showOCRReview) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.showOCRReview)
        }
        set { defaults.set(newValue, forKey: Keys.showOCRReview) }
    }

    var autoDeleteScreenshot: Bool {
        get {
            if defaults.object(forKey: Keys.autoDeleteScreenshot) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.autoDeleteScreenshot)
        }
        set { defaults.set(newValue, forKey: Keys.autoDeleteScreenshot) }
    }

    var scrollCaptureSteps: Int {
        get { defaults.integer(forKey: Keys.scrollCaptureSteps) }
        set { defaults.set(newValue, forKey: Keys.scrollCaptureSteps) }
    }

    var shortcutArea: Int {
        get { defaults.integer(forKey: Keys.shortcutArea) }
        set { defaults.set(newValue, forKey: Keys.shortcutArea) }
    }

    var shortcutWindow: Int {
        get { defaults.integer(forKey: Keys.shortcutWindow) }
        set { defaults.set(newValue, forKey: Keys.shortcutWindow) }
    }

    var shortcutFullScreen: Int {
        get { defaults.integer(forKey: Keys.shortcutFullScreen) }
        set { defaults.set(newValue, forKey: Keys.shortcutFullScreen) }
    }

    var shortcutScroll: Int {
        get { defaults.integer(forKey: Keys.shortcutScroll) }
        set { defaults.set(newValue, forKey: Keys.shortcutScroll) }
    }

    func shortcutConflicts(for mode: CaptureMode, keyCode: Int) -> CaptureMode? {
        let map: [CaptureMode: Int] = [
            .area: shortcutArea,
            .window: shortcutWindow,
            .fullScreen: shortcutFullScreen,
            .scroll: shortcutScroll
        ]
        for (otherMode, otherKey) in map where otherMode != mode && otherKey == keyCode && keyCode != 0 {
            return otherMode
        }
        return nil
    }

    func setShortcut(_ keyCode: Int, for mode: CaptureMode) {
        switch mode {
        case .area: shortcutArea = keyCode
        case .window: shortcutWindow = keyCode
        case .fullScreen: shortcutFullScreen = keyCode
        case .scroll: shortcutScroll = keyCode
        }
    }

    func allShortcuts() -> [CaptureMode: Int] {
        return [
            .area: shortcutArea,
            .window: shortcutWindow,
            .fullScreen: shortcutFullScreen,
            .scroll: shortcutScroll
        ]
    }

    func resetShortcutsToDefaults() {
        shortcutArea = 18
        shortcutWindow = 19
        shortcutFullScreen = 20
        shortcutScroll = 21
    }

    var showCapturePreview: Bool {
        get {
            if defaults.object(forKey: Keys.showCapturePreview) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.showCapturePreview)
        }
        set { defaults.set(newValue, forKey: Keys.showCapturePreview) }
    }

    var batchCaptureCount: Int {
        get { defaults.integer(forKey: Keys.batchCaptureCount) }
        set { defaults.set(newValue, forKey: Keys.batchCaptureCount) }
    }

    var batchCaptureInterval: TimeInterval {
        get { defaults.double(forKey: Keys.batchCaptureInterval) }
        set { defaults.set(newValue, forKey: Keys.batchCaptureInterval) }
    }

    var enableHybridSearch: Bool {
        get {
            if defaults.object(forKey: Keys.enableHybridSearch) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.enableHybridSearch)
        }
        set { defaults.set(newValue, forKey: Keys.enableHybridSearch) }
    }

    var enableSummarization: Bool {
        get {
            if defaults.object(forKey: Keys.enableSummarization) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.enableSummarization)
        }
        set { defaults.set(newValue, forKey: Keys.enableSummarization) }
    }

    var enableCrossReference: Bool {
        get {
            if defaults.object(forKey: Keys.enableCrossReference) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.enableCrossReference)
        }
        set { defaults.set(newValue, forKey: Keys.enableCrossReference) }
    }

    private init() {
        registerDefaults()
    }
    
    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.outputMode: OutputMode.clipboard.rawValue,
            Keys.launchAtLogin: false,
            Keys.showNotifications: true,
            Keys.captureMode: CaptureMode.area.rawValue,
            Keys.soundEnabled: true,
            Keys.effectsEnabled: true,
            Keys.languageCode: "en-US",
            Keys.minConfidence: 0.5,
            Keys.autoSaveToDatabase: true,
            Keys.darkPalette: true,
            Keys.showOCRReview: false,
            Keys.autoDeleteScreenshot: true,
            Keys.scrollCaptureSteps: 50,
            Keys.shortcutArea: 18,
            Keys.shortcutWindow: 19,
            Keys.shortcutFullScreen: 20,
            Keys.shortcutScroll: 21,
            Keys.showCapturePreview: false,
            Keys.batchCaptureCount: 5,
            Keys.batchCaptureInterval: 2.0,
            Keys.enableHybridSearch: false,
            Keys.enableSummarization: false,
            Keys.enableCrossReference: false
        ])
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.outputMode)
        defaults.removeObject(forKey: Keys.outputFolder)
        defaults.removeObject(forKey: Keys.launchAtLogin)
        defaults.removeObject(forKey: Keys.showNotifications)
        defaults.removeObject(forKey: Keys.captureMode)
        defaults.removeObject(forKey: Keys.soundEnabled)
        defaults.removeObject(forKey: Keys.effectsEnabled)
        defaults.removeObject(forKey: Keys.languageCode)
        defaults.removeObject(forKey: Keys.minConfidence)
        defaults.removeObject(forKey: Keys.autoSaveToDatabase)
        defaults.removeObject(forKey: Keys.darkPalette)
        defaults.removeObject(forKey: Keys.showOCRReview)
        defaults.removeObject(forKey: Keys.autoDeleteScreenshot)
        defaults.removeObject(forKey: Keys.scrollCaptureSteps)
        defaults.removeObject(forKey: Keys.shortcutArea)
        defaults.removeObject(forKey: Keys.shortcutWindow)
        defaults.removeObject(forKey: Keys.shortcutFullScreen)
        defaults.removeObject(forKey: Keys.shortcutScroll)
        defaults.removeObject(forKey: Keys.showCapturePreview)
        defaults.removeObject(forKey: Keys.batchCaptureCount)
        defaults.removeObject(forKey: Keys.batchCaptureInterval)
        defaults.removeObject(forKey: Keys.enableHybridSearch)
        defaults.removeObject(forKey: Keys.enableSummarization)
        defaults.removeObject(forKey: Keys.enableCrossReference)
    }
}
