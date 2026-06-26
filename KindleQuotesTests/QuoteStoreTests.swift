import XCTest
@testable import KindleQuotes

@MainActor
final class QuoteStoreTests: XCTestCase {
    func testImportPreventsDuplicates() throws {
        let directory = try makeTemporaryDirectory()
        let clippingsURL = directory.appendingPathComponent("My Clippings.txt")
        try duplicateSample.write(to: clippingsURL, atomically: true, encoding: .utf8)

        let store = QuoteStore(baseDirectory: directory)

        let firstImportCount = try store.importQuotes(from: clippingsURL)
        let secondImportCount = try store.importQuotes(from: clippingsURL)

        XCTAssertEqual(firstImportCount, 1)
        XCTAssertEqual(secondImportCount, 0)
        XCTAssertEqual(store.quotes.count, 1)
    }

    func testLoadsAndSavesQuotesJSON() throws {
        let directory = try makeTemporaryDirectory()
        let store = QuoteStore(baseDirectory: directory)

        try store.importQuotes(from: try writeSampleClippings(in: directory))

        let reloadedStore = QuoteStore(baseDirectory: directory)

        XCTAssertEqual(reloadedStore.quotes.count, 1)
        XCTAssertEqual(reloadedStore.quotes.first?.book, "A Book")
        XCTAssertEqual(reloadedStore.quotes.first?.text, "A saved highlight.")
    }

    private var duplicateSample: String {
        """
        A Book
        - Your Highlight on Location 42 | Added on Monday, January 1, 2024

        A saved highlight.
        ==========
        A Book
        - Your Highlight on Location 42 | Added on Monday, January 1, 2024

        A saved highlight.
        ==========
        """
    }

    private func writeSampleClippings(in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent("My Clippings.txt")
        try duplicateSample.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KindleQuotesTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
