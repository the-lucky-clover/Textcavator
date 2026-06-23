import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let outputMode = "textcavator.outputMode"
        static let outputFolder = "textcavator.outputFolder"
        static let launchAtLogin = "textcavator.launchAtLogin"
        static let showNotifications = "textcavator.showNotifications"
        static let captureMode = "textcavator.captureMode" // "area" or "window"
        static let soundEnabled = "textcavator.soundEnabled"
        static let effectsEnabled = "textcavator.effectsEnabled"
        static let languageCode = "textcavator.languageCode"
    }
    
    enum OutputMode: String {
        case clipboard = "clipboard"
        case textFile = "textFile"
    }
    
    enum CaptureMode: String {
        case area = "area"
        case window = "window"
    }
    
    // MARK: - Properties
    
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
            if let path = defaults.string(forKey: Keys.outputFolder) {
                return URL(fileURLWithPath: path)
            }
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        }
        set {
            defaults.set(newValue?.path ?? "", forKey: Keys.outputFolder)
        }
    }
    
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
    
    var showNotifications: Bool {
        get {
            if defaults.object(forKey: Keys.showNotifications) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.showNotifications)
        }
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
        get {
            if defaults.object(forKey: Keys.soundEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
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
            Keys.languageCode: "en-US"
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
    }
}