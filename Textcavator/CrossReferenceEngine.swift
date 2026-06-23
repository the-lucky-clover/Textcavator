import Foundation

class CrossReferenceEngine {
    static let shared = CrossReferenceEngine()

    private let graph = KnowledgeGraphManager.shared
    private let embeddingManager = EmbeddingManager.shared

    private init() {}

    func analyzeCapture(_ captureId: UUID, text: String, app: String, existingCaptureIds: [UUID]) async {
        let similarityThreshold: Double = 0.75
        let appWeight: Double = 3.0
        let semanticWeight: Double = 2.0
        let temporalWeight: Double = 1.0

        for otherId in existingCaptureIds where otherId != captureId {
            let relation = KnowledgeRelation(
                sourceId: captureId,
                targetId: otherId,
                relationType: .sameApp,
                weight: appWeight
            )
            graph.addRelation(relation)
        }

        if !text.isEmpty {
            do {
                let queryVector = try await embeddingManager.embed(text)
                for otherId in existingCaptureIds where otherId != captureId {
                    let otherText = getText(for: otherId)
                    if !otherText.isEmpty {
                        let otherVector = try await embeddingManager.embed(otherText)
                        let similarity = embeddingManager.cosineSimilarity(queryVector, otherVector)
                        if similarity > similarityThreshold {
                            let relation = KnowledgeRelation(
                                sourceId: captureId,
                                targetId: otherId,
                                relationType: .semanticMatch,
                                weight: semanticWeight * similarity
                            )
                            graph.addRelation(relation)
                        }
                    }
                }
            } catch {
                // Embedding failed, skip semantic analysis
            }
        }

        graph.assignClusters()
    }

    func findRelated(to captureId: UUID, limit: Int = 5) -> [UUID] {
        return graph.relatedNodes(to: captureId, limit: limit).map { $0.nodeId }
    }

    func getCluster(for captureId: UUID) -> Int {
        return graph.clusterFor(nodeId: captureId)
    }

    private func getText(for captureId: UUID) -> String {
        let records = TextcavatorDatabase.shared.recentCaptures(limit: 1000)
        if let record = records.first(where: { $0.id == captureId }) {
            return record.ocrText ?? ""
        }
        return ""
    }
}
