import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let book: String
    let location: String?
    let dateHighlighted: String?
    let importedAt: Date
}
