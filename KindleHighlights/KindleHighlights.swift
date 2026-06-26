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
        let index = abs(rotationBucket) % quotes.count
        return quotes[index]
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
