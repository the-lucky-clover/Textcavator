import Foundation

struct CaptureRecord: Identifiable, Codable {
    let id: UUID
    let imagePath: String
    let thumbnailPath: String?
    let width: Int
    let height: Int
    let sourceApp: String
    let capturedAt: Date
    let ocrText: String?
    let confidence: Double?
    let language: String?
    let ocrStatus: String

    init(id: UUID = UUID(), imagePath: String, thumbnailPath: String? = nil, width: Int, height: Int, sourceApp: String, capturedAt: Date = Date(), ocrText: String? = nil, confidence: Double? = nil, language: String? = nil, ocrStatus: String = "pending") {
        self.id = id
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.width = width
        self.height = height
        self.sourceApp = sourceApp
        self.capturedAt = capturedAt
        self.ocrText = ocrText
        self.confidence = confidence
        self.language = language
        self.ocrStatus = ocrStatus
    }
}
