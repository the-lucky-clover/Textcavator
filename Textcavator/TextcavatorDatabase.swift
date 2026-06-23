import Foundation
import sqlite3

class TextcavatorDatabase {
    static let shared = TextcavatorDatabase()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    deinit {
        closeDatabase()
    }

    private func databasePath() -> String {
        let fm = FileManager.default
        let folder = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Textcavator")
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("textcavator.db").path
    }

    private func openDatabase() {
        let path = databasePath()
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
            db = nil
        }
    }

    private func closeDatabase() {
        if let db = db {
            sqlite3_close(db)
        }
    }

    private func createTables() {
        let createCaptures = """
        CREATE TABLE IF NOT EXISTS captures (
            id TEXT PRIMARY KEY,
            image_path TEXT NOT NULL,
            thumbnail_path TEXT,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            source_app TEXT NOT NULL,
            captured_at REAL NOT NULL,
            ocr_text TEXT,
            confidence REAL,
            language TEXT,
            ocr_status TEXT NOT NULL DEFAULT 'pending'
        );
        """

        let createFTS = """
        CREATE VIRTUAL TABLE IF NOT EXISTS captures_fts USING fts5(
            id UNINDEXED,
            ocr_text,
            source_app UNINDEXED,
            content='captures',
            content_rowid='rowid'
        );
        """

        let createIndex = "CREATE INDEX IF NOT EXISTS idx_captures_app ON captures(source_app);"
        let createIndex2 = "CREATE INDEX IF NOT EXISTS idx_captures_date ON captures(captured_at DESC);"

        let createKnowledgeAssets = """
        CREATE TABLE IF NOT EXISTS knowledge_assets (
            id TEXT PRIMARY KEY,
            capture_id TEXT NOT NULL,
            asset_type TEXT NOT NULL,
            content TEXT,
            embedding_blob BLOB,
            model_version TEXT,
            created_at REAL NOT NULL
        );
        """

        let createKnowledgeRelations = """
        CREATE TABLE IF NOT EXISTS knowledge_relations (
            id TEXT PRIMARY KEY,
            source_id TEXT NOT NULL,
            target_id TEXT NOT NULL,
            relation_type TEXT NOT NULL,
            weight REAL NOT NULL DEFAULT 1.0,
            created_at REAL NOT NULL
        );
        """

        let createKnowledgeIndex = "CREATE INDEX IF NOT EXISTS idx_knowledge_assets_capture ON knowledge_assets(capture_id);"
        let createRelationsIndex = "CREATE INDEX IF NOT EXISTS idx_knowledge_relations_source ON knowledge_relations(source_id);"
        let createRelationsIndex2 = "CREATE INDEX IF NOT EXISTS idx_knowledge_relations_target ON knowledge_relations(target_id);"

        let createRedactionAudit = """
        CREATE TABLE IF NOT EXISTS redaction_audit_log (
            id TEXT PRIMARY KEY,
            capture_id TEXT NOT NULL,
            region_id TEXT NOT NULL,
            tool TEXT NOT NULL,
            rect_x REAL NOT NULL,
            rect_y REAL NOT NULL,
            rect_width REAL NOT NULL,
            rect_height REAL NOT NULL,
            note_text TEXT,
            applied_at REAL NOT NULL,
            exported_safe INTEGER NOT NULL DEFAULT 0
        );
        """

        let createRedactionTemplates = """
        CREATE TABLE IF NOT EXISTS redaction_templates (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            tool_set TEXT NOT NULL,
            config_json TEXT
        );
        """

        let createRedactionIndex = "CREATE INDEX IF NOT EXISTS idx_redaction_audit_capture ON redaction_audit_log(capture_id);"
        let createRedactionIndex2 = "CREATE INDEX IF NOT EXISTS idx_redaction_audit_exported ON redaction_audit_log(exported_safe);"

        execute(createCaptures)
        execute(createFTS)
        execute(createKnowledgeAssets)
        execute(createKnowledgeRelations)
        execute(createRedactionAudit)
        execute(createRedactionTemplates)
        execute(createIndex)
        execute(createIndex2)
        execute(createKnowledgeIndex)
        execute(createRelationsIndex)
        execute(createRelationsIndex2)
        execute(createRedactionIndex)
        execute(createRedactionIndex2)

        let createSavedSearches = """
        CREATE TABLE IF NOT EXISTS saved_searches (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            filter_json TEXT NOT NULL,
            created_at REAL NOT NULL,
            last_used REAL NOT NULL,
            use_count INTEGER NOT NULL DEFAULT 0
        );
        """

        let createSmartCollections = """
        CREATE TABLE IF NOT EXISTS smart_collections (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            filter_json TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            auto_update INTEGER NOT NULL DEFAULT 1,
            created_at REAL NOT NULL
        );
        """

        execute(createSavedSearches)
        execute(createSmartCollections)
        seedSmartCollections()

        seedRedactionTemplates()
    }

    private func execute(_ sql: String) {
        guard let db = db else { return }
        var errMsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown error"
            print("SQL error: \(msg)")
            sqlite3_free(errMsg)
        }
    }

    func saveCapture(_ record: CaptureRecord) {
        let insert = """
        INSERT OR REPLACE INTO captures (id, image_path, thumbnail_path, width, height, source_app, captured_at, ocr_text, confidence, language, ocr_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        guard let db = db else { return }
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insert, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, record.id.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, record.imagePath, -1, nil)
            sqlite3_bind_text(stmt, 3, record.thumbnailPath, -1, nil)
            sqlite3_bind_int(stmt, 4, Int32(record.width))
            sqlite3_bind_int(stmt, 5, Int32(record.height))
            sqlite3_bind_text(stmt, 6, record.sourceApp, -1, nil)
            sqlite3_bind_double(stmt, 7, record.capturedAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 8, record.ocrText, -1, nil)
            sqlite3_bind_double(stmt, 9, record.confidence ?? 0.0)
            sqlite3_bind_text(stmt, 10, record.language, -1, nil)
            sqlite3_bind_text(stmt, 11, record.ocrStatus, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Failed to insert capture")
            }
        }
        sqlite3_finalize(stmt)

        // Update FTS index if we have OCR text
        if let ocrText = record.ocrText, !ocrText.isEmpty {
            let ftsInsert = """
            INSERT OR REPLACE INTO captures_fts (id, ocr_text, source_app)
            VALUES (?, ?, ?);
            """
            var ftsStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, ftsInsert, -1, &ftsStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(ftsStmt, 1, record.id.uuidString, -1, nil)
                sqlite3_bind_text(ftsStmt, 2, ocrText, -1, nil)
                sqlite3_bind_text(ftsStmt, 3, record.sourceApp, -1, nil)
                sqlite3_step(ftsStmt)
            }
            sqlite3_finalize(ftsStmt)
        }
    }

    func search(query: String, limit: Int = 50) -> [(record: CaptureRecord, snippet: String)] {
        var results: [(CaptureRecord, String)] = []

        guard let db = db else { return results }

        let sql = """
        SELECT c.id, c.image_path, c.thumbnail_path, c.width, c.height, c.source_app, c.captured_at, c.ocr_text, c.confidence, c.language, c.ocr_status,
               snippet(captures_fts, 2, '<mark>', '</mark>', '...', 64) as snippet
        FROM captures c
        JOIN captures_fts fts ON c.id = fts.id
        WHERE captures_fts MATCH ?
        ORDER BY c.captured_at DESC
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, query, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let imagePath = String(cString: sqlite3_column_text(stmt, 1))
                let thumb = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
                let width = Int(sqlite3_column_int(stmt, 3))
                let height = Int(sqlite3_column_int(stmt, 4))
                let app = String(cString: sqlite3_column_text(stmt, 5))
                let date = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
                let text = sqlite3_column_text(stmt, 7).map { String(cString: $0) }
                let conf = sqlite3_column_double(stmt, 8)
                let lang = sqlite3_column_text(stmt, 9).map { String(cString: $0) }
                let status = String(cString: sqlite3_column_text(stmt, 10))
                let snippet = String(cString: sqlite3_column_text(stmt, 11))

                if let uuid = UUID(uuidString: idStr) {
                    let record = CaptureRecord(id: uuid, imagePath: imagePath, thumbnailPath: thumb, width: width, height: height, sourceApp: app, capturedAt: date, ocrText: text, confidence: conf, language: lang, ocrStatus: status)
                    results.append((record, snippet))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    func recentCaptures(limit: Int = 50) -> [CaptureRecord] {
        var results: [CaptureRecord] = []
        guard let db = db else { return results }

        let sql = "SELECT * FROM captures ORDER BY captured_at DESC LIMIT ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(limit))
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let imagePath = String(cString: sqlite3_column_text(stmt, 1))
                let thumb = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
                let width = Int(sqlite3_column_int(stmt, 3))
                let height = Int(sqlite3_column_int(stmt, 4))
                let app = String(cString: sqlite3_column_text(stmt, 5))
                let date = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
                let text = sqlite3_column_text(stmt, 7).map { String(cString: $0) }
                let conf = sqlite3_column_double(stmt, 8)
                let lang = sqlite3_column_text(stmt, 9).map { String(cString: $0) }
                let status = String(cString: sqlite3_column_text(stmt, 10))

                if let uuid = UUID(uuidString: idStr) {
                    results.append(CaptureRecord(id: uuid, imagePath: imagePath, thumbnailPath: thumb, width: width, height: height, sourceApp: app, capturedAt: date, ocrText: text, confidence: conf, language: lang, ocrStatus: status))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    func totalCount() -> Int {
        guard let db = db else { return 0 }
        var count = 0
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM captures;", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func saveKnowledgeAsset(captureId: UUID, assetType: String, content: String?, embedding: [Float]?, modelVersion: String) {
        guard let db = db else { return }
        let id = UUID().uuidString
        let embeddingBlob = embedding?.withUnsafeBufferPointer { Data(buffer: $0) }
        let sql = """
        INSERT OR REPLACE INTO knowledge_assets (id, capture_id, asset_type, content, embedding_blob, model_version, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, id, -1, nil)
            sqlite3_bind_text(stmt, 2, captureId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 3, assetType, -1, nil)
            if let content = content {
                sqlite3_bind_text(stmt, 4, content, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 4)
            }
            if let blob = embeddingBlob {
                blob.withUnsafeBytes { rawPtr in
                    sqlite3_bind_blob(stmt, 5, rawPtr.baseAddress, Int32(blob.count), nil)
                }
            } else {
                sqlite3_bind_null(stmt, 5)
            }
            sqlite3_bind_text(stmt, 6, modelVersion, -1, nil)
            sqlite3_bind_double(stmt, 7, Date().timeIntervalSince1970)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func saveKnowledgeRelation(_ relation: KnowledgeRelation) {
        guard let db = db else { return }
        let sql = """
        INSERT OR REPLACE INTO knowledge_relations (id, source_id, target_id, relation_type, weight, created_at)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, relation.id.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, relation.sourceId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 3, relation.targetId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 4, relation.relationType.rawValue, -1, nil)
            sqlite3_bind_double(stmt, 5, relation.weight)
            sqlite3_bind_double(stmt, 6, relation.createdAt.timeIntervalSince1970)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func relations(for captureId: UUID) -> [KnowledgeRelation] {
        var results: [KnowledgeRelation] = []
        guard let db = db else { return results }
        let sql = "SELECT id, source_id, target_id, relation_type, weight, created_at FROM knowledge_relations WHERE source_id = ? OR target_id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, captureId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, captureId.uuidString, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let sourceStr = String(cString: sqlite3_column_text(stmt, 1))
                let targetStr = String(cString: sqlite3_column_text(stmt, 2))
                let typeStr = String(cString: sqlite3_column_text(stmt, 3))
                let weight = sqlite3_column_double(stmt, 4)
                let created = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
                if let id = UUID(uuidString: idStr), let source = UUID(uuidString: sourceStr), let target = UUID(uuidString: targetStr), let type = RelationType(rawValue: typeStr) {
                    results.append(KnowledgeRelation(id: id, sourceId: source, targetId: target, relationType: type, weight: weight))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    func saveRedactionAuditEntry(_ entry: RedactionAuditEntry) {
        guard let db = db else { return }
        let sql = """
        INSERT OR REPLACE INTO redaction_audit_log (id, capture_id, region_id, tool, rect_x, rect_y, rect_width, rect_height, note_text, applied_at, exported_safe)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, entry.id.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, entry.captureId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 3, entry.regionId.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 4, entry.tool.rawValue, -1, nil)
            sqlite3_bind_double(stmt, 5, entry.rect.origin.x)
            sqlite3_bind_double(stmt, 6, entry.rect.origin.y)
            sqlite3_bind_double(stmt, 7, entry.rect.size.width)
            sqlite3_bind_double(stmt, 8, entry.rect.size.height)
            if let note = entry.noteText {
                sqlite3_bind_text(stmt, 9, note, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 9)
            }
            sqlite3_bind_double(stmt, 10, entry.appliedAt.timeIntervalSince1970)
            sqlite3_bind_int(stmt, 11, entry.exportedSafe ? 1 : 0)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func updateAuditEntryExport(_ entryId: UUID, exportedSafe: Bool) {
        guard let db = db else { return }
        let sql = "UPDATE redaction_audit_log SET exported_safe = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, exportedSafe ? 1 : 0)
            sqlite3_bind_text(stmt, 2, entryId.uuidString, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func auditLog(for captureId: UUID) -> [RedactionAuditEntry] {
        var results: [RedactionAuditEntry] = []
        guard let db = db else { return results }
        let sql = "SELECT id, capture_id, region_id, tool, rect_x, rect_y, rect_width, rect_height, note_text, applied_at, exported_safe FROM redaction_audit_log WHERE capture_id = ? ORDER BY applied_at DESC;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, captureId.uuidString, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let captureStr = String(cString: sqlite3_column_text(stmt, 1))
                let regionStr = String(cString: sqlite3_column_text(stmt, 2))
                let toolStr = String(cString: sqlite3_column_text(stmt, 3))
                let rx = sqlite3_column_double(stmt, 4)
                let ry = sqlite3_column_double(stmt, 5)
                let rw = sqlite3_column_double(stmt, 6)
                let rh = sqlite3_column_double(stmt, 7)
                let note = sqlite3_column_text(stmt, 8).map { String(cString: $0) }
                let applied = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 9))
                let exported = sqlite3_column_int(stmt, 10) != 0
                if let id = UUID(uuidString: idStr), let capture = UUID(uuidString: captureStr), let region = UUID(uuidString: regionStr) {
                    let rect = CGRect(x: rx, y: ry, width: rw, height: rh)
                    let tool = RedactionTool(rawValue: toolStr) ?? .solid
                    results.append(RedactionAuditEntry(id: id, captureId: capture, regionId: region, tool: tool, rect: rect, noteText: note, appliedAt: applied, exportedSafe: exported))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    private func seedRedactionTemplates() {
        let templates: [(String, RedactionTemplate)] = [
            ("HIPAA Default", .hipaa),
            ("GDPR Default", .gdpr),
            ("Legal Default", .legal)
        ]
        for (name, template) in templates {
            let id = UUID().uuidString
            let sql = "INSERT OR IGNORE INTO redaction_templates (id, name, tool_set, config_json) VALUES (?, ?, ?, ?);"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id, -1, nil)
                sqlite3_bind_text(stmt, 2, name, -1, nil)
                let toolSet = template.defaultTools.map { $0.rawValue }.joined(separator: ",")
                sqlite3_bind_text(stmt, 3, toolSet, -1, nil)
                sqlite3_bind_text(stmt, 4, "{}", -1, nil)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }

    // MARK: - Saved Searches

    func saveSearch(_ saved: SavedSearch) {
        guard let db = db, let filterData = try? JSONEncoder().encode(saved.filter) else { return }
        let filterJson = String(data: filterData, encoding: .utf8) ?? "{}"
        let sql = """
        INSERT OR REPLACE INTO saved_searches (id, name, filter_json, created_at, last_used, use_count)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, saved.id.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, saved.name, -1, nil)
            sqlite3_bind_text(stmt, 3, filterJson, -1, nil)
            sqlite3_bind_double(stmt, 4, saved.createdAt.timeIntervalSince1970)
            sqlite3_bind_double(stmt, 5, saved.lastUsed.timeIntervalSince1970)
            sqlite3_bind_int(stmt, 6, Int32(saved.useCount))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func savedSearches() -> [SavedSearch] {
        var results: [SavedSearch] = []
        guard let db = db else { return results }
        let sql = "SELECT id, name, filter_json, created_at, last_used, use_count FROM saved_searches ORDER BY use_count DESC, last_used DESC;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let filterJson = String(cString: sqlite3_column_text(stmt, 2))
                let created = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
                let lastUsed = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
                let useCount = Int(sqlite3_column_int(stmt, 5))
                if let id = UUID(uuidString: idStr), let data = filterJson.data(using: .utf8), let filter = try? JSONDecoder().decode(SearchFilter.self, from: data) {
                    results.append(SavedSearch(id: id, name: name, filter: filter))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    func deleteSavedSearch(_ id: UUID) {
        guard let db = db else { return }
        let sql = "DELETE FROM saved_searches WHERE id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, id.uuidString, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Smart Collections

    func saveSmartCollection(_ collection: SmartCollection) {
        guard let db = db, let filterData = try? JSONEncoder().encode(collection.filter) else { return }
        let filterJson = String(data: filterData, encoding: .utf8) ?? "{}"
        let sql = """
        INSERT OR REPLACE INTO smart_collections (id, name, description, filter_json, icon, color, auto_update, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, collection.id.uuidString, -1, nil)
            sqlite3_bind_text(stmt, 2, collection.name, -1, nil)
            sqlite3_bind_text(stmt, 3, collection.description, -1, nil)
            sqlite3_bind_text(stmt, 4, filterJson, -1, nil)
            sqlite3_bind_text(stmt, 5, collection.icon, -1, nil)
            sqlite3_bind_text(stmt, 6, collection.color, -1, nil)
            sqlite3_bind_int(stmt, 7, collection.autoUpdate ? 1 : 0)
            sqlite3_bind_double(stmt, 8, collection.createdAt.timeIntervalSince1970)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func smartCollections() -> [SmartCollection] {
        var results: [SmartCollection] = []
        guard let db = db else { return results }
        let sql = "SELECT id, name, description, filter_json, icon, color, auto_update, created_at FROM smart_collections ORDER BY name;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let desc = String(cString: sqlite3_column_text(stmt, 2))
                let filterJson = String(cString: sqlite3_column_text(stmt, 3))
                let icon = String(cString: sqlite3_column_text(stmt, 4))
                let color = String(cString: sqlite3_column_text(stmt, 5))
                let autoUpdate = sqlite3_column_int(stmt, 6) != 0
                let created = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 7))
                if let id = UUID(uuidString: idStr), let data = filterJson.data(using: .utf8), let filter = try? JSONDecoder().decode(SearchFilter.self, from: data) {
                    results.append(SmartCollection(id: id, name: name, description: desc, filter: filter, icon: icon, color: color, autoUpdate: autoUpdate))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    func deleteSmartCollection(_ id: UUID) {
        guard let db = db else { return }
        let sql = "DELETE FROM smart_collections WHERE id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, id.uuidString, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Search Suggestions

    func searchSuggestions(prefix: String, limit: Int = 10) -> [String] {
        var results: [String] = []
        guard let db = db, !prefix.isEmpty else { return results }
        let sql = """
        SELECT DISTINCT snippet(captures_fts, 2, '', '', '', 0) as term
        FROM captures_fts
        WHERE captures_fts MATCH ?
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, "\(prefix)*", -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(limit))
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let term = sqlite3_column_text(stmt, 0).map({ String(cString: $0) }), !term.isEmpty {
                    results.append(term)
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    // MARK: - Filtered Search

    func searchWithFilter(_ filter: SearchFilter, limit: Int = 50) -> [(record: CaptureRecord, snippet: String)] {
        var results: [(CaptureRecord, String)] = []
        guard let db = db else { return results }

        var clauses: [String] = []
        var args: [Any] = []

        if !filter.query.isEmpty {
            clauses.append("c.ocr_text LIKE ?")
            args.append("%\(filter.query)%")
        }
        if let app = filter.app {
            clauses.append("c.source_app = ?")
            args.append(app)
        }
        if let lang = filter.language {
            clauses.append("c.language = ?")
            args.append(lang)
        }
        if let minC = filter.minConfidence {
            clauses.append("c.confidence >= ?")
            args.append(NSNumber(value: minC))
        }
        if let maxC = filter.maxConfidence {
            clauses.append("c.confidence <= ?")
            args.append(NSNumber(value: maxC))
        }
        if let from = filter.dateFrom {
            clauses.append("c.captured_at >= ?")
            args.append(NSNumber(value: from.timeIntervalSince1970))
        }
        if let to = filter.dateTo {
            clauses.append("c.captured_at <= ?")
            args.append(NSNumber(value: to.timeIntervalSince1970))
        }

        let whereClause = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = """
        SELECT c.id, c.image_path, c.thumbnail_path, c.width, c.height, c.source_app, c.captured_at, c.ocr_text, c.confidence, c.language, c.ocr_status,
               COALESCE(snippet(captures_fts, 2, '<mark>', '</mark>', '...', 64), '') as snippet
        FROM captures c
        LEFT JOIN captures_fts fts ON c.id = fts.id
        \(whereClause)
        ORDER BY c.captured_at DESC
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            for (index, arg) in args.enumerated() {
                if let str = arg as? String {
                    sqlite3_bind_text(stmt, Int32(index + 1), str, -1, nil)
                } else if let num = arg as? NSNumber {
                    if strcmp(num.objCType, "f") == 0 || strcmp(num.objCType, "d") == 0 {
                        sqlite3_bind_double(stmt, Int32(index + 1), num.doubleValue)
                    } else {
                        sqlite3_bind_int(stmt, Int32(index + 1), Int32(num.intValue))
                    }
                }
            }
            sqlite3_bind_int(stmt, Int32(args.count + 1), Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(stmt, 0))
                let imagePath = String(cString: sqlite3_column_text(stmt, 1))
                let thumb = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
                let width = Int(sqlite3_column_int(stmt, 3))
                let height = Int(sqlite3_column_int(stmt, 4))
                let app = String(cString: sqlite3_column_text(stmt, 5))
                let date = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
                let text = sqlite3_column_text(stmt, 7).map { String(cString: $0) }
                let conf = sqlite3_column_double(stmt, 8)
                let lang = sqlite3_column_text(stmt, 9).map { String(cString: $0) }
                let status = String(cString: sqlite3_column_text(stmt, 10))
                let snippet = String(cString: sqlite3_column_text(stmt, 11))
                if let uuid = UUID(uuidString: idStr) {
                    results.append((CaptureRecord(id: uuid, imagePath: imagePath, thumbnailPath: thumb, width: width, height: height, sourceApp: app, capturedAt: date, ocrText: text, confidence: conf, language: lang, ocrStatus: status), snippet))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    private func seedSmartCollections() {
        let collections: [(String, SmartCollection)] = [
            ("Recent Captures", SmartCollection(name: "Recent Captures", description: "Last 24 hours", filter: SearchFilter(dateFrom: Calendar.current.date(byAdding: .day, value: -1, to: Date())), icon: "clock.fill", color: "#00D4FF")),
            ("High Confidence", SmartCollection(name: "High Confidence", description: "Confidence >= 90%", filter: SearchFilter(minConfidence: 0.9), icon: "star.fill", color: "#FFD60A")),
            ("Low Confidence", SmartCollection(name: "Low Confidence", description: "Needs review", filter: SearchFilter(maxConfidence: 0.5), icon: "exclamationmark.triangle.fill", color: "#FF453A"))
        ]
        for (_, collection) in collections {
            let id = UUID().uuidString
            let sql = "INSERT OR IGNORE INTO smart_collections (id, name, description, filter_json, icon, color, auto_update, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id, -1, nil)
                sqlite3_bind_text(stmt, 2, collection.name, -1, nil)
                sqlite3_bind_text(stmt, 3, collection.description, -1, nil)
                if let filterData = try? JSONEncoder().encode(collection.filter), let filterJson = String(data: filterData, encoding: .utf8) {
                    sqlite3_bind_text(stmt, 4, filterJson, -1, nil)
                } else {
                    sqlite3_bind_text(stmt, 4, "{}", -1, nil)
                }
                sqlite3_bind_text(stmt, 5, collection.icon, -1, nil)
                sqlite3_bind_text(stmt, 6, collection.color, -1, nil)
                sqlite3_bind_int(stmt, 7, collection.autoUpdate ? 1 : 0)
                sqlite3_bind_double(stmt, 8, collection.createdAt.timeIntervalSince1970)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
}
