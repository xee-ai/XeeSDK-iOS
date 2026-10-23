//
//  EventsDatabase.swift
//  XeeSDK
//

import Foundation
import SQLite3

private let log = Log.storage
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// The SDK's event queue on disk, in SQLite: one row per event, so adding or sending an event never
/// rewrites the others. Rows keep their order (`id`); the default events go before the system log.
/// If the file cannot be opened the queue lives in memory for this launch.
@EventsManagerActor
final class EventsDatabase {
    enum Kind: Int32, CaseIterable, Sendable {
        case `default` = 0
        case sysLog = 1
    }

    struct Row: Sendable {
        let id: Int64
        let kind: Kind
        let name: String
        let data: Data
    }

    static let shared = EventsDatabase(url: defaultURL())

    private var db: OpaquePointer?

    init(url: URL?) {
        if let url, open(url) { return }
        log.error("EventsDatabase: the queue is kept in memory for this launch")
        _ = sqlite3_open(":memory:", &db)
        createTable()
    }

    private static func defaultURL() -> URL? {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("XeeSDK", isDirectory: true)
        else { return nil }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        var url = dir
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return dir.appendingPathComponent("events.sqlite")
    }

    private func open(_ url: URL) -> Bool {
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            log.error("EventsDatabase: cannot open \(url.lastPathComponent): \(message)")
            sqlite3_close(db)
            db = nil
            return false
        }
        // Events are sent from the background too, so the file stays readable after the first unlock.
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
        execute("PRAGMA journal_mode=WAL;")
        return createTable()
    }

    @discardableResult
    private func createTable() -> Bool {
        execute("CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, kind INTEGER NOT NULL, name TEXT NOT NULL, data BLOB NOT NULL);")
            && execute("CREATE INDEX IF NOT EXISTS events_kind_id ON events (kind, id);")
    }

    private var message: String { db.map { String(cString: sqlite3_errmsg($0)) } ?? "no database" }

    @discardableResult
    private func execute(_ sql: String) -> Bool {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            log.error("EventsDatabase: \(message)")
            return false
        }
        return true
    }

    /// Prepares `sql`, lets `bind` set its parameters, steps it once per row through `row`, and finalizes.
    @discardableResult
    private func run(_ sql: String, bind: (OpaquePointer) -> Void = { _ in }, row: (OpaquePointer) -> Bool = { _ in true }) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            log.error("EventsDatabase: \(message)")
            return false
        }
        defer { sqlite3_finalize(statement) }
        bind(statement)
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                if !row(statement) { return true }
            case SQLITE_DONE:
                return true
            default:
                log.error("EventsDatabase: \(message)")
                return false
            }
        }
    }

    @discardableResult
    func insert(kind: Kind, name: String, data: Data) -> Bool {
        run("INSERT INTO events (kind, name, data) VALUES (?, ?, ?);", bind: { s in
            sqlite3_bind_int(s, 1, kind.rawValue)
            sqlite3_bind_text(s, 2, name, -1, SQLITE_TRANSIENT)
            _ = data.withUnsafeBytes { sqlite3_bind_blob(s, 3, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT) }
        })
    }

    var isEmpty: Bool {
        var any = false
        run("SELECT 1 FROM events LIMIT 1;", row: { _ in any = true; return false })
        return !any
    }

    /// The oldest rows, default events first, up to `maxCount` rows and `maxBytes` of data. The first
    /// row is taken even when it alone is larger, so one big event cannot stop the queue.
    func rows(maxCount: Int, maxBytes: Int) -> [Row] {
        var out: [Row] = []
        var bytes = 0
        for kind in Kind.allCases {
            var full = false
            run("SELECT id, name, data FROM events WHERE kind = ? ORDER BY id LIMIT ?;", bind: { s in
                sqlite3_bind_int(s, 1, kind.rawValue)
                sqlite3_bind_int(s, 2, Int32(maxCount - out.count))
            }) { s in
                let size = Int(sqlite3_column_bytes(s, 2))
                if !out.isEmpty, bytes + size > maxBytes {
                    full = true
                    return false
                }
                let data = sqlite3_column_blob(s, 2).map { Data(bytes: $0, count: size) } ?? Data()
                let name = sqlite3_column_text(s, 1).map { String(cString: $0) } ?? ""
                out.append(Row(id: sqlite3_column_int64(s, 0), kind: kind, name: name, data: data))
                bytes += size
                return out.count < maxCount
            }
            if full || out.count >= maxCount { break }
        }
        return out
    }

    func delete(ids: [Int64]) {
        for chunk in stride(from: 0, to: ids.count, by: 500).map({ Array(ids[$0 ..< min($0 + 500, ids.count)]) }) {
            let marks = Array(repeating: "?", count: chunk.count).joined(separator: ",")
            run("DELETE FROM events WHERE id IN (\(marks));", bind: { s in
                for (i, id) in chunk.enumerated() { sqlite3_bind_int64(s, Int32(i + 1), id) }
            })
        }
    }

    func delete(name: String) {
        run("DELETE FROM events WHERE name = ?;", bind: { s in sqlite3_bind_text(s, 1, name, -1, SQLITE_TRANSIENT) })
    }

    func deleteAll() {
        execute("DELETE FROM events;")
    }

    /// Keeps the newest `keep` rows of `kind`; returns how many were dropped.
    @discardableResult
    func trim(kind: Kind, keep: Int) -> Int {
        let ok = run(
            "DELETE FROM events WHERE kind = ?1 AND id NOT IN (SELECT id FROM events WHERE kind = ?1 ORDER BY id DESC LIMIT ?2);",
            bind: { s in
                sqlite3_bind_int(s, 1, kind.rawValue)
                sqlite3_bind_int(s, 2, Int32(keep))
            }
        )
        return ok ? Int(sqlite3_changes(db)) : 0
    }
}
