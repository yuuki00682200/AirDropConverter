import Foundation

struct FileStamp: Equatable, Sendable {
    let size: Int
    let modified: Date
    let identifier: String

    static func read(_ url: URL) throws -> Self {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .fileResourceIdentifierKey])
        guard values.isRegularFile == true else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        return Self(size: values.fileSize ?? 0, modified: values.contentModificationDate ?? .distantPast,
                    identifier: String(describing: values.fileResourceIdentifier))
    }
}

/// Tracks arrivals independently of UI prompts. Only unchanged, nonempty files are candidates.
struct FileArrivalTracker {
    private var known: [URL: FileStamp] = [:]
    private(set) var pending: [URL: Int] = [:]

    mutating func reset(to files: [URL: FileStamp]) {
        known = files
        pending.removeAll()
    }

    mutating func update(_ files: [URL: FileStamp]) -> [URL] {
        for (url, stamp) in files where known[url] != stamp { pending[url] = 0 }
        pending = pending.filter { files[$0.key] != nil }
        for url in Array(pending.keys) where files[url] == known[url] && (files[url]?.size ?? 0) > 0 {
            pending[url, default: 0] += 1
        }
        known = files
        return pending.filter { $0.value >= 2 }.map(\.key)
    }

    mutating func handled(_ url: URL) { pending.removeValue(forKey: url) }
}

enum AirDropMetadata {
    static func isAirDropFile(at url: URL) -> Bool {
        let length = getxattr(url.path, "com.apple.quarantine", nil, 0, 0, 0)
        guard length > 0 else { return false }
        var buffer = [UInt8](repeating: 0, count: length)
        let count = getxattr(url.path, "com.apple.quarantine", &buffer, length, 0, 0)
        guard count > 0, let value = String(bytes: buffer.prefix(count), encoding: .utf8) else { return false }
        let fields = value.split(separator: ";", omittingEmptySubsequences: false)
        return fields.count >= 3 && fields[2] == "sharingd"
    }

}
