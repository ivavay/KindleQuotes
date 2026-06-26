import Foundation

enum WidgetQuoteStore {
    static let appGroupIdentifier = "group.work.ivychen.KindleQuotes"
    static let macOSAppGroupIdentifier = "489463TQ2X.work.ivychen.KindleQuotes"
    static let quotesFileName = "quotes.json"
    static let bundledQuotesFileName = "BundledQuotes"
    static let sharedQuotesDataKey = "SharedQuotesJSONData"

    static let appGroupIdentifiers = [
        appGroupIdentifier,
        macOSAppGroupIdentifier
    ]

    static func loadQuotes(fileManager: FileManager = .default) -> [Quote] {
        loadResult(fileManager: fileManager).quotes
    }

    static func loadResult(fileManager: FileManager = .default) -> LoadResult {
        var diagnostics: [String] = []

        for groupIdentifier in appGroupIdentifiers {
            if let data = UserDefaults(suiteName: groupIdentifier)?.data(forKey: sharedQuotesDataKey) {
                do {
                    let quotes = try JSONDecoder.quoteDecoder.decode([Quote].self, from: data)
                    if !quotes.isEmpty {
                        return LoadResult(quotes: quotes, message: "Loaded \(quotes.count) quotes")
                    }

                    diagnostics.append("\(groupIdentifier): shared data is empty")
                } catch {
                    diagnostics.append("\(groupIdentifier): \(error.localizedDescription)")
                }
            } else {
                diagnostics.append("\(groupIdentifier): no shared widget data")
            }
        }

        for url in candidateQuotesFileURLs(fileManager: fileManager) {
            guard fileManager.fileExists(atPath: url.path) else { continue }

            do {
                let data = try Data(contentsOf: url)
                let quotes = try JSONDecoder.quoteDecoder.decode([Quote].self, from: data)
                if !quotes.isEmpty {
                    return LoadResult(quotes: quotes, message: "Loaded \(quotes.count) quotes")
                }

                diagnostics.append("Empty JSON at \(url.lastPathComponent)")
            } catch {
                diagnostics.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if let bundledQuotes = loadBundledQuotes() {
            return LoadResult(quotes: bundledQuotes, message: "Loaded \(bundledQuotes.count) bundled quotes")
        }

        return LoadResult(
            quotes: [],
            message: diagnostics.isEmpty ? "No quotes.json visible to widget" : diagnostics.joined(separator: " | ")
        )
    }

    private static func loadBundledQuotes() -> [Quote]? {
        guard let url = Bundle.main.url(forResource: bundledQuotesFileName, withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let quotes = try JSONDecoder.quoteDecoder.decode([Quote].self, from: data)
            return quotes.isEmpty ? nil : quotes
        } catch {
            return nil
        }
    }

    private static func candidateQuotesFileURLs(fileManager: FileManager) -> [URL] {
        var urls: [URL] = []

        for groupIdentifier in appGroupIdentifiers {
            if let sharedContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
                urls.append(sharedContainerURL.appendingPathComponent(quotesFileName))
            }
        }

        for groupIdentifier in appGroupIdentifiers {
            let debugSharedURL = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(groupIdentifier)
                .appendingPathComponent(quotesFileName)
            urls.append(debugSharedURL)
        }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        urls.append(documentsURL.appendingPathComponent(quotesFileName))

        return urls
    }
}

struct LoadResult {
    let quotes: [Quote]
    let message: String
}

extension JSONDecoder {
    static var quoteDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
