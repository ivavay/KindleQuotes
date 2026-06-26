import Foundation
import Combine
import WidgetKit

@MainActor
final class QuoteStore: ObservableObject {
    static let appGroupIdentifier = "group.work.ivychen.KindleQuotes"
    static let macOSAppGroupIdentifier = "489463TQ2X.work.ivychen.KindleQuotes"
    static let quotesFileName = "quotes.json"
    static let sharedQuotesDataKey = "SharedQuotesJSONData"

    static let appGroupIdentifiers = [
        appGroupIdentifier,
        macOSAppGroupIdentifier
    ]

    @Published private(set) var quotes: [Quote] = []
    @Published private(set) var statusMessage = "No highlights imported yet."
    @Published private(set) var selectedFilePath: String?

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let injectedBaseDirectory: URL?

    private let selectedFilePathKey = "SelectedClippingsPath"
    private let selectedFileBookmarkKey = "SelectedClippingsBookmark"

    init(
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard,
        baseDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.injectedBaseDirectory = baseDirectory
        self.selectedFilePath = userDefaults.string(forKey: selectedFilePathKey)
        self.quotes = loadQuotes()
        updateStatus(importedCount: 0)
    }

    var previewQuote: Quote? {
        quotes.first
    }

    func rememberSelectedFile(_ url: URL) throws {
        selectedFilePath = url.path
        userDefaults.set(url.path, forKey: selectedFilePathKey)

        let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        userDefaults.set(bookmark, forKey: selectedFileBookmarkKey)
        statusMessage = "Selected \(url.lastPathComponent). Ready to sync."
    }

    func syncSavedFile() {
        guard let fileURL = savedFileURL() else {
            statusMessage = "Choose My Clippings.txt first."
            return
        }

        do {
            let importedCount = try importQuotes(from: fileURL)
            updateStatus(importedCount: importedCount)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            if !quotes.isEmpty {
                do {
                    try saveQuotes()
                    statusMessage = "Could not read My Clippings.txt, but refreshed the widget with \(quotes.count) saved quotes. Choose the clippings file again to import new highlights."
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    statusMessage = "Sync failed: \(error.localizedDescription)"
                }
            } else {
                statusMessage = "Sync failed: \(error.localizedDescription). Choose My Clippings.txt again."
            }
        }
    }

    func showError(_ message: String) {
        statusMessage = message
    }

    func loadQuotes() -> [Quote] {
        let url = quotesFileURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder.quoteDecoder.decode([Quote].self, from: data)
        } catch {
            statusMessage = "Could not load saved quotes."
            return []
        }
    }

    func saveQuotes() throws {
        let url = quotesFileURL()
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.quoteEncoder.encode(quotes)
        try data.write(to: url, options: [.atomic])
        try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)

        // Widgets can read App Group UserDefaults without opening the JSON file
        // directly. Keeping this copy makes the widget more reliable while the
        // JSON file remains the source stored on disk.
        for groupIdentifier in Self.appGroupIdentifiers {
            if let sharedContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
                let sharedFileURL = sharedContainerURL.appendingPathComponent(Self.quotesFileName)
                try? fileManager.createDirectory(at: sharedFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? data.write(to: sharedFileURL, options: [.atomic])
                try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: sharedFileURL.path)
            }

            let sharedDefaults = UserDefaults(suiteName: groupIdentifier)
            sharedDefaults?.set(data, forKey: Self.sharedQuotesDataKey)
            sharedDefaults?.synchronize()
        }
    }

    @discardableResult
    func importQuotes(from fileURL: URL) throws -> Int {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let parsedQuotes = KindleClippingsParser.parse(contents)
        var seenIDs = Set(quotes.map(\.id))
        let newQuotes = parsedQuotes.filter { quote in
            guard !seenIDs.contains(quote.id) else { return false }
            seenIDs.insert(quote.id)
            return true
        }

        guard !newQuotes.isEmpty else {
            try saveQuotes()
            return 0
        }

        quotes.append(contentsOf: newQuotes)
        try saveQuotes()
        return newQuotes.count
    }

    func quotesFileURL() -> URL {
        if let injectedBaseDirectory {
            return injectedBaseDirectory.appendingPathComponent(Self.quotesFileName)
        }

        for groupIdentifier in Self.appGroupIdentifiers {
            if let sharedContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
                return sharedContainerURL.appendingPathComponent(Self.quotesFileName)
            }
        }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(Self.quotesFileName)
    }

    private func savedFileURL() -> URL? {
        if let bookmarkData = userDefaults.data(forKey: selectedFileBookmarkKey) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return url
            }
        }

        guard let selectedFilePath else { return nil }
        return URL(fileURLWithPath: selectedFilePath)
    }

    private func updateStatus(importedCount: Int) {
        if importedCount > 0 {
            statusMessage = "Imported \(importedCount) new quotes. Total: \(quotes.count)."
        } else if quotes.isEmpty {
            statusMessage = "No highlights imported yet."
        } else {
            statusMessage = "No new quotes. Total: \(quotes.count)."
        }
    }
}

extension JSONDecoder {
    static var quoteDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var quoteEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
