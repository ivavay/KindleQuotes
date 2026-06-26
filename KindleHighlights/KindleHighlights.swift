//
//  KindleHighlights.swift
//  KindleHighlights
//
//  Created by Ivy Chen on 6/25/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let rotationIntervalHours = 2

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: Quote.placeholder, message: "Preview")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let result = WidgetQuoteStore.loadResult()
        let quote = result.quotes.first ?? Quote.placeholder
        completion(QuoteEntry(date: Date(), quote: quote, message: result.message))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let result = WidgetQuoteStore.loadResult()
        let quotes = result.quotes
        let currentDate = Date()

        var entries = [
            QuoteEntry(date: currentDate, quote: quote(for: currentDate, in: quotes), message: result.message)
        ]

        let firstRotationDate = nextRotationDate(after: currentDate)
        entries += (0..<12).map { index in
            let entryDate = Calendar.current.date(byAdding: .hour, value: index * rotationIntervalHours, to: firstRotationDate) ?? firstRotationDate
            return QuoteEntry(date: entryDate, quote: quote(for: entryDate, in: quotes), message: result.message)
        }

        completion(Timeline(entries: entries, policy: .after(entries.last?.date ?? currentDate)))
    }

    private func nextRotationDate(after date: Date) -> Date {
        let rotationIntervalSeconds = TimeInterval(rotationIntervalHours * 60 * 60)
        let nextBucket = floor(date.timeIntervalSince1970 / rotationIntervalSeconds) + 1
        return Date(timeIntervalSince1970: nextBucket * rotationIntervalSeconds)
    }

    private func quote(for date: Date, in quotes: [Quote]) -> Quote? {
        guard !quotes.isEmpty else { return nil }
        let rotationIntervalSeconds = TimeInterval(rotationIntervalHours * 60 * 60)
        let rotationBucket = Int(date.timeIntervalSince1970 / rotationIntervalSeconds)
        let index = shuffledIndex(for: rotationBucket, quoteCount: quotes.count)
        return quotes[index]
    }

    private func shuffledIndex(for rotationBucket: Int, quoteCount: Int) -> Int {
        guard quoteCount > 1 else { return 0 }

        let positionInCycle = positiveModulo(rotationBucket, quoteCount)
        let cycle = rotationBucket / quoteCount
        let shuffledIndexes = shuffledIndexes(count: quoteCount, seed: cycle)
        return shuffledIndexes[positionInCycle]
    }

    private func shuffledIndexes(count: Int, seed: Int) -> [Int] {
        var generator = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed)))
        var indexes = Array(0..<count)

        for currentIndex in stride(from: indexes.count - 1, through: 1, by: -1) {
            let randomIndex = Int.random(in: 0...currentIndex, using: &generator)
            indexes.swapAt(currentIndex, randomIndex)
        }

        return indexes
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
    let message: String
}

struct KindleHighlightsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: widgetFamily == .systemLarge ? 12 : 8) {
            if let quote = entry.quote {
                Text("“\(quote.text)”")
                    .font(quoteFont)
                    .fontWeight(.medium)
                    .lineLimit(quoteLineLimit)
                    .minimumScaleFactor(widgetFamily == .systemLarge ? 0.72 : 0.78)

                Spacer(minLength: 0)

                Text(quote.book)
                    .font(bookFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(widgetFamily == .systemLarge ? 3 : 2)
            } else {
                Text(entry.message)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(widgetFamily == .systemLarge ? 20 : 16)
    }

    private var quoteFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .callout
        case .systemLarge:
            return .title3
        default:
            return .title3
        }
    }

    private var bookFont: Font {
        switch widgetFamily {
        case .systemLarge:
            return .callout.weight(.semibold)
        default:
            return .caption.weight(.semibold)
        }
    }

    private var quoteLineLimit: Int {
        switch widgetFamily {
        case .systemSmall:
            return 5
        case .systemLarge:
            return 18
        default:
            return 7
        }
    }
}

struct KindleHighlights: Widget {
    let kind: String = "KindleHighlightsV3"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KindleHighlightsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kindle Quotes")
        .description("Shows one imported Kindle highlight at a time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private extension Quote {
    static let placeholder = Quote(
        id: "placeholder",
        text: "A favorite highlight will appear here after you import your Kindle clippings.",
        book: "Kindle Quotes",
        location: nil,
        dateHighlighted: nil,
        importedAt: Date()
    )
}
