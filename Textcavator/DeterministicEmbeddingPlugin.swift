import Foundation

class DeterministicEmbeddingPlugin: EmbeddingPlugin {
    let name = "Deterministic Hash Embeddings"
    let dimensions = 128
    let isAvailable = true
    let priority = 1

    private let primes: [UInt64] = [
        11400714785074694791,
        14029467366897019727,
        16095879293928354161,
    ]

    private func hash(_ string: String, seed: UInt64) -> UInt64 {
        var h = seed
        for char in string.utf8 {
            h = (h &* 0x100000001b3) ^ UInt64(char)
        }
        return h
    }

    private func nextFloat(from bits: UInt64) -> Float {
        let normalized = Double(bits & 0xFFFF) / Double(0xFFFF)
        return Float(normalized) * 2.0 - 1.0
    }

    func embed(_ text: String) async throws -> [Float] {
        let lowercased = text.lowercased()
        var vector = Array(repeating: Float(0), count: dimensions)

        for i in 0..<dimensions {
            let h1 = hash(lowercased, primes[i % primes.count])
            let h2 = hash(lowercased, primes[(i + 1) % primes.count])
            let combined = h1 ^ (h2 << 1)
            vector[i] = nextFloat(from: combined)
        }

        let magnitude = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }

    func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        results.reserveCapacity(texts.count)
        for text in texts {
            results.append(try await embed(text))
        }
        return results
    }
}
