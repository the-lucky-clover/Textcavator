import Foundation

class EmbeddingManager {
    static let shared = EmbeddingManager()

    private var plugin: EmbeddingPlugin?
    private var cache: [String: [Float]] = [:]
    private let cacheLimit = 10_000

    private init() {
        plugin = DeterministicEmbeddingPlugin()
    }

    func activePlugin() -> EmbeddingPlugin? {
        return plugin
    }

    func availablePlugins() -> [EmbeddingPlugin] {
        return [DeterministicEmbeddingPlugin()]
    }

    func selectPlugin(_ newPlugin: EmbeddingPlugin?) {
        plugin = newPlugin
    }

    func embed(_ text: String) async throws -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        if let cached = cache[trimmed] { return cached }
        guard let plugin = plugin else { throw NSError(domain: "Embedding", code: 1, userInfo: [NSLocalizedDescriptionKey: "No embedding plugin available"]) }
        let vector = try await plugin.embed(trimmed)
        if cache.count < cacheLimit {
            cache[trimmed] = vector
        }
        return vector
    }

    func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        guard let plugin = plugin else { throw NSError(domain: "Embedding", code: 1, userInfo: [NSLocalizedDescriptionKey: "No embedding plugin available"]) }
        let trimmed = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var results: [[Float]] = []
        var uncached: [(index: Int, text: String)] = []
        for (i, text) in trimmed.enumerated() {
            if let cached = cache[text] {
                results.append(cached)
            } else {
                uncached.append((i, text))
                results.append([])
            }
        }
        let embeddings = try await plugin.embedBatch(uncached.map { $0.text })
        for (idx, vector) in zip(uncached, embeddings) {
            results[idx.index] = vector
            if cache.count < cacheLimit {
                cache[uncached[idx.index].text] = vector
            }
        }
        return results
    }

    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Double = 0
        var magA: Double = 0
        var magB: Double = 0
        for i in 0..<a.count {
            dot += Double(a[i]) * Double(b[i])
            magA += Double(a[i]) * Double(a[i])
            magB += Double(b[i]) * Double(b[i])
        }
        guard magA > 0, magB > 0 else { return 0 }
        return dot / (sqrt(magA) * sqrt(magB))
    }
}
