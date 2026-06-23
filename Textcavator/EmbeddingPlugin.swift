import Foundation

protocol EmbeddingPlugin {
    var name: String { get }
    var dimensions: Int { get }
    var isAvailable: Bool { get }
    var priority: Int { get }

    func embed(_ text: String) async throws -> [Float]
    func embedBatch(_ texts: [String]) async throws -> [[Float]]
}
