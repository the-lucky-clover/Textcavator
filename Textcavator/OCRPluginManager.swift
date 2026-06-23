import Foundation
import AppKit

class OCRPluginManager {
    static let shared = OCRPluginManager()

    private var plugins: [OCRPlugin] = []
    private var activePlugin: OCRPlugin?

    private init() {
        registerDefaultPlugins()
    }

    private func registerDefaultPlugins() {
        let vision = VisionOCRPlugin()
        plugins.append(vision)
        plugins.append(TesseractOCRPlugin())
        plugins.sort { $0.priority < $1.priority }
        activePlugin = plugins.first { $0.isAvailable }
    }

    func availablePlugins() -> [OCRPlugin] {
        return plugins.filter { $0.isAvailable }
    }

    func activeEngine() -> OCRPlugin? {
        return activePlugin
    }

    func selectPlugin(named pluginName: String) {
        if let plugin = plugins.first(where: { $0.name == pluginName && $0.isAvailable }) {
            activePlugin = plugin
        }
    }

    func recognizeText(in image: NSImage, language: String = "en-US") async throws -> OCRResult {
        guard let plugin = activePlugin else {
            throw OCRError.pluginNotAvailable
        }
        return try await plugin.recognizeText(in: image, language: language)
    }
}
