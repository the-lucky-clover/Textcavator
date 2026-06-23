import Foundation
import AppKit
import Vision

class VisionOCRPlugin: OCRPlugin {
    let name = "Apple Vision OCR"
    let isAvailable = true
    let priority = 1

    func recognizeText(in image: NSImage, language: String) async throws -> OCRResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let regions = observations.compactMap { observation -> TextRegion? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return TextRegion(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                let fullText = regions.map(\.text).joined(separator: "\n")
                let avgConfidence = regions.map(\.confidence).reduce(0, +) / Double(max(regions.count, 1))
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime

                continuation.resume(returning: OCRResult(
                    text: fullText,
                    confidence: avgConfidence,
                    regions: regions,
                    processingTime: elapsed,
                    engineName: self.name
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            if let lang = BCP47LanguageTag(languageCode: language) {
                request.recognitionLanguages = [lang]
            } else {
                request.recognitionLanguages = ["en-US"]
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum OCRError: LocalizedError {
    case imageConversionFailed
    case noTextFound
    case pluginNotAvailable

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Failed to convert image for OCR"
        case .noTextFound: return "No text detected in image"
        case .pluginNotAvailable: return "OCR plugin not available"
        }
    }
}
