import Foundation
import AppKit
import Vision

protocol OCRPlugin {
    var name: String { get }
    var isAvailable: Bool { get }
    var priority: Int { get }

    func recognizeText(in image: NSImage, language: String) async throws -> OCRResult
}

struct OCRResult {
    let text: String
    let confidence: Double
    let regions: [TextRegion]
    let processingTime: TimeInterval
    let engineName: String
}

struct TextRegion: Codable {
    let text: String
    let confidence: Double
    let boundingBox: CGRect
}
