import Foundation

enum KindleClippingsParser {
    static func parse(_ contents: String, importedAt: Date = Date()) -> [Quote] {
        contents
            .components(separatedBy: "==========")
            .compactMap { parseClipping($0, importedAt: importedAt) }
    }

    private static func parseClipping(_ rawClipping: String, importedAt: Date) -> Quote? {
        let lines = rawClipping
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        let nonEmptyLines = lines.filter { !$0.isEmpty }
        guard nonEmptyLines.count >= 3 else { return nil }

        let book = nonEmptyLines[0]
        let metadata = nonEmptyLines[1]
        guard isHighlight(metadata) else { return nil }

        let text = nonEmptyLines.dropFirst(2).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        return Quote(
            text: text,
            book: book,
            location: extractLocation(from: metadata),
            dateHighlighted: extractDate(from: metadata),
            importedAt: importedAt
        )
    }

    private static func isHighlight(_ metadata: String) -> Bool {
        let lowercased = metadata.lowercased()

        if lowercased.contains("note") || metadata.contains("笔记") || metadata.contains("註記") || metadata.contains("注释") {
            return false
        }

        if lowercased.contains("bookmark") || metadata.contains("书签") || metadata.contains("書籤") {
            return false
        }

        return lowercased.contains("highlight") || metadata.contains("标注") || metadata.contains("標註")
    }

    private static func extractLocation(from metadata: String) -> String? {
        let patterns = [
            #"(?i)location\s+([0-9,\-]+)"#,
            #"(?i)loc\.\s+([0-9,\-]+)"#,
            #"位置\s*([0-9,\-]+)"#
        ]

        for pattern in patterns {
            if let match = firstCapture(in: metadata, pattern: pattern) {
                return match
            }
        }

        return nil
    }

    private static func extractDate(from metadata: String) -> String? {
        let separators = ["Added on ", "添加于", "加入於", "新增於"]

        for separator in separators {
            if let range = metadata.range(of: separator, options: .caseInsensitive) {
                let dateText = metadata[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                return dateText.isEmpty ? nil : dateText
            }
        }

        return nil
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges > 1,
            let captureRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
