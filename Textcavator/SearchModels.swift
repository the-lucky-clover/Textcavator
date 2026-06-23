import Foundation

struct SearchFilter: Codable, Equatable {
    var query: String = ""
    var app: String?
    var language: String?
    var minConfidence: Double?
    var maxConfidence: Double?
    var dateFrom: Date?
    var dateTo: Date?
    var tags: [String] = []
    var hasEmbedding: Bool = false
    var captureMode: String?

    func toPredicate() -> NSPredicate {
        var format = ""
        var args: [Any] = []

        if !query.isEmpty {
            format += "ocrText CONTAINS[cd] %@"
            args.append(query)
        }
        if let app = app {
            format += args.isEmpty ? "sourceApp == %@" : " AND sourceApp == %@"
            args.append(app)
        }
        if let lang = language {
            format += args.isEmpty ? "language == %@" : " AND language == %@"
            args.append(lang)
        }
        if let minC = minConfidence {
            format += args.isEmpty ? "confidence >= %f" : " AND confidence >= %f"
            args.append(minC)
        }
        if let maxC = maxConfidence {
            format += args.isEmpty ? "confidence <= %f" : " AND confidence <= %f"
            args.append(maxC)
        }
        if let from = dateFrom {
            let t = from.timeIntervalSince1970
            format += args.isEmpty ? "capturedAt >= %f" : " AND capturedAt >= %f"
            args.append(t)
        }
        if let to = dateTo {
            let t = to.timeIntervalSince1970
            format += args.isEmpty ? "capturedAt <= %f" : " AND capturedAt <= %f"
            args.append(t)
        }

        return NSPredicate(format: format, argumentArray: args)
    }

    func isEmpty() -> Bool {
        return query.isEmpty && app == nil && language == nil && minConfidence == nil && maxConfidence == nil && dateFrom == nil && dateTo == nil && tags.isEmpty
    }
}

struct SavedSearch: Codable, Identifiable {
    let id: UUID
    var name: String
    var filter: SearchFilter
    var createdAt: Date
    var lastUsed: Date
    var useCount: Int

    init(id: UUID = UUID(), name: String, filter: SearchFilter) {
        self.id = id
        self.name = name
        self.filter = filter
        self.createdAt = Date()
        self.lastUsed = Date()
        self.useCount = 0
    }
}

struct SmartCollection: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var filter: SearchFilter
    var icon: String
    var color: String
    var autoUpdate: Bool
    var createdAt: Date

    init(id: UUID = UUID(), name: String, description: String, filter: SearchFilter, icon: String, color: String, autoUpdate: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.filter = filter
        self.icon = icon
        self.color = color
        self.autoUpdate = autoUpdate
        self.createdAt = Date()
    }
}
