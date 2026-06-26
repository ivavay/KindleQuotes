import Foundation
import CryptoKit

struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let book: String
    let location: String?
    let dateHighlighted: String?
    let importedAt: Date

    init(
        text: String,
        book: String,
        location: String?,
        dateHighlighted: String?,
        importedAt: Date = Date()
    ) {
        self.text = text
        self.book = book
        self.location = location
        self.dateHighlighted = dateHighlighted
        self.importedAt = importedAt
        self.id = Quote.makeID(book: book, location: location, text: text)
    }

    init(
        id: String,
        text: String,
        book: String,
        location: String?,
        dateHighlighted: String?,
        importedAt: Date
    ) {
        self.id = id
        self.text = text
        self.book = book
        self.location = location
        self.dateHighlighted = dateHighlighted
        self.importedAt = importedAt
    }

    static func makeID(book: String, location: String?, text: String) -> String {
        let rawID = "\(book.trimmingCharacters(in: .whitespacesAndNewlines))|\(location ?? "")|\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
        let digest = SHA256.hash(data: Data(rawID.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
