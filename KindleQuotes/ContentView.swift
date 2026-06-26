//
//  ContentView.swift
//  KindleQuotes
//
//  Created by Ivy Chen on 6/25/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var quoteStore = QuoteStore()
    @State private var isShowingFileImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Kindle Quotes")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                Button("Choose My Clippings.txt") {
                    isShowingFileImporter = true
                }

                Button("Sync Highlights") {
                    quoteStore.syncSavedFile()
                }
            }

            if let selectedFilePath = quoteStore.selectedFilePath {
                Text(selectedFilePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(quoteStore.statusMessage)
                .font(.headline)

            Divider()

            previewView
        }
        .frame(minWidth: 520, minHeight: 360, alignment: .topLeading)
        .padding(28)
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
    }

    @ViewBuilder
    private var previewView: some View {
        if let quote = quoteStore.previewQuote {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("“\(quote.text)”")
                    .font(.title3)
                    .lineLimit(5)

                Text(quote.book)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        } else {
            ContentUnavailableView(
                "No Quotes Yet",
                systemImage: "quote.bubble",
                description: Text("Choose your Kindle My Clippings.txt file, then sync highlights.")
            )
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else { return }
            try quoteStore.rememberSelectedFile(fileURL)
        } catch {
            // Keep the message beginner-friendly and visible in the main window.
            quoteStore.showError("Could not choose file: \(error.localizedDescription)")
        }
    }
}
