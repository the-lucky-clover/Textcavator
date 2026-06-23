import Foundation

protocol SummarizationPlugin {
    var name: String { get }
    var isAvailable: Bool { get }
    var priority: Int { get }

    func summarize(_ text: String, maxLength: Int) async throws -> SummaryResult
    func summarizeBatch(_ texts: [String], maxLength: Int) async throws -> [SummaryResult]
}

struct SummaryResult {
    let summary: String
    let originalLength: Int
    let summaryLength: Int
    let compressionRatio: Double
    let modelVersion: String
    let processingTime: TimeInterval
}

enum SummarizationError: LocalizedError {
    case textTooShort
    case modelNotAvailable
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .textTooShort: return "Text too short to summarize"
        case .modelNotAvailable: return "Summarization model not available"
        case .processingFailed: return "Summarization processing failed"
        }
    }
}
