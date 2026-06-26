import XCTest
@testable import KindleQuotes

final class KindleClippingsParserTests: XCTestCase {
    func testParsesEnglishAndChineseHighlights() {
        let sample = """
        Atomic Habits (James Clear)
        - Your Highlight on Location 123-124 | Added on Monday, January 1, 2024 8:00:00 PM

        You do not rise to the level of your goals. You fall to the level of your systems.
        ==========
        长安的荔枝 (马伯庸)
        - 您在位置 88-89的标注 | 添加于 2024年1月2日星期二 下午9:30:00

        既然已经上路，就只能往前走。
        ==========
        """

        let quotes = KindleClippingsParser.parse(sample)

        XCTAssertEqual(quotes.count, 2)
        XCTAssertEqual(quotes[0].book, "Atomic Habits (James Clear)")
        XCTAssertEqual(quotes[0].location, "123-124")
        XCTAssertEqual(quotes[0].dateHighlighted, "Monday, January 1, 2024 8:00:00 PM")
        XCTAssertEqual(quotes[1].book, "长安的荔枝 (马伯庸)")
        XCTAssertEqual(quotes[1].location, "88-89")
        XCTAssertEqual(quotes[1].dateHighlighted, "2024年1月2日星期二 下午9:30:00")
    }

    func testIgnoresNotesAndBookmarks() {
        let sample = """
        A Book
        - Your Note on Location 10 | Added on Monday, January 1, 2024

        This is a note.
        ==========
        A Book
        - Your Bookmark on Location 11 | Added on Monday, January 1, 2024

        ==========
        A Book
        - Your Highlight on Location 12 | Added on Monday, January 1, 2024

        This is a highlight.
        ==========
        """

        let quotes = KindleClippingsParser.parse(sample)

        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes.first?.text, "This is a highlight.")
    }
}
