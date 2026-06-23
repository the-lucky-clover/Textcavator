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

        execute(createCaptures)
        execute(createFTS)
        execute(createIndex)
        execute(createIndex2)
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
}
