import Foundation

struct KnowledgeRelation: Codable, Identifiable {
    let id: UUID
    let sourceId: UUID
    let targetId: UUID
    let relationType: RelationType
    let weight: Double
    let createdAt: Date

    init(id: UUID = UUID(), sourceId: UUID, targetId: UUID, relationType: RelationType, weight: Double = 1.0) {
        self.id = id
        self.sourceId = sourceId
        self.targetId = targetId
        self.relationType = relationType
        self.weight = weight
        self.createdAt = Date()
    }
}

enum RelationType: String, Codable {
    case similarContent = "similar_content"
    case sameApp = "same_app"
    case timeProximity = "time_proximity"
    case semanticMatch = "semantic_match"
    case userLinked = "user_linked"
}

class KnowledgeGraphManager {
    static let shared = KnowledgeGraphManager()

    private var relations: [UUID: [KnowledgeRelation]] = [:]
    private var nodes: [UUID: GraphNode] = [:]

    struct GraphNode: Codable, Identifiable {
        let id: UUID
        var degree: Int = 0
        var cluster: Int = 0
    }

    private init() {}

    func addRelation(_ relation: KnowledgeRelation) {
        relations[relation.sourceId, default: []].append(relation)
        relations[relation.targetId, default: []].append(relation)
        nodes[relation.sourceId, default: GraphNode(id: relation.sourceId)].degree += 1
        nodes[relation.targetId, default: GraphNode(id: relation.targetId)].degree += 1
    }

    func relations(for nodeId: UUID) -> [KnowledgeRelation] {
        return relations[nodeId] ?? []
    }

    func neighbors(of nodeId: UUID) -> [UUID] {
        let rels = relations[nodeId] ?? []
        return rels.flatMap { [$0.sourceId, $0.targetId] }.filter { $0 != nodeId }
    }

    func shortestPath(from start: UUID, to end: UUID, maxDepth: Int = 4) -> [UUID]? {
        guard maxDepth > 0 else { return nil }
        var queue: [(current: UUID, path: [UUID])] = [(start, [start])]
        var visited: Set<UUID> = [start]

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            if current == end { return path }
            for neighbor in neighbors(of: current) where !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append((neighbor, path + [neighbor]))
            }
        }
        return nil
    }

    func clusterFor(nodeId: UUID) -> Int {
        return nodes[nodeId]?.cluster ?? 0
    }

    func assignClusters() {
        var clusterId = 0
        let sortedNodes = nodes.keys.sorted { nodes[$0]!.degree > nodes[$1]!.degree }

        for node in sortedNodes where nodes[node]?.cluster == 0 {
            clusterId += 1
            var visited: Set<UUID> = [node]
            var queue: [UUID] = [node]

            while !queue.isEmpty {
                let current = queue.removeFirst()
                nodes[current]?.cluster = clusterId
                for neighbor in neighbors(of: current) where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
    }

    func relatedNodes(to nodeId: UUID, limit: Int = 10) -> [(nodeId: UUID, score: Double)] {
        let rels = relations[nodeId] ?? []
        var scores: [UUID: Double] = [:]
        for rel in rels {
            let other = rel.sourceId == nodeId ? rel.targetId : rel.sourceId
            scores[other, default: 0] += rel.weight
        }
        return scores.sorted { $0.value > $1.value }.prefix(limit).map { (nodeId: $0.key, score: $0.value) }
    }
}
