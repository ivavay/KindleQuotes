# KindleQuotes

KindleQuotes is a native macOS SwiftUI app with a WidgetKit widget for displaying Kindle highlights from a local `My Clippings.txt` file.

The app imports highlights, saves them locally as JSON, and lets the widget rotate through quotes every 2 hours.

## Features

- Import Kindle `My Clippings.txt` using a SwiftUI file picker.
- Parse Kindle highlights while ignoring notes and bookmarks.
- Supports English and Chinese clippings text.
- Stores quotes locally in `quotes.json`.
- Prevents duplicate imports using a stable quote ID.
- Shares quote data between the macOS app and widget with an App Group.
- Widget supports small, medium, and large sizes.
- Large widget layout gives longer quotes more room.
- Unit tests cover parsing, duplicate prevention, and JSON load/save behavior.

## Project Structure

```text
KindleQuotes/
  Quote.swift
  KindleClippingsParser.swift
  QuoteStore.swift
  ContentView.swift

KindleHighlights/
  KindleHighlights.swift
  KindleHighlightsBundle.swift
  WidgetQuoteStore.swift
  Quote.swift

KindleQuotesTests/
  KindleClippingsParserTests.swift
  QuoteStoreTests.swift
```

## Requirements

- macOS with WidgetKit support
- Xcode
- Swift / SwiftUI
- A Kindle `My Clippings.txt` file

## App Group

The app and widget use an App Group shared container so the widget can read saved quote data.

Current App Group identifiers in the project:

```text
group.work.ivychen.KindleQuotes
489463TQ2X.work.ivychen.KindleQuotes
```

If you clone or fork this project, update the bundle identifiers, development team, and App Group identifiers to match your Apple Developer account.

## How To Use

1. Open `KindleQuotes.xcodeproj` in Xcode.
2. Select the `KindleQuotes` scheme.
3. Build and run the macOS app.
4. Click **Choose My Clippings.txt**.
5. Select your Kindle `My Clippings.txt` file.
6. Click **Sync Highlights**.
7. Add the **Kindle Quotes** widget from macOS widgets.

The widget rotates quotes every 2 hours.

## Finding `My Clippings.txt`

On many Kindle devices:

1. Plug the Kindle into your Mac with USB.
2. Open Finder.
3. Select the Kindle drive in the sidebar.
4. Open the `documents` folder.
5. Choose `My Clippings.txt`.

## Local Storage

Quotes are saved as JSON in the App Group shared container when available. If the App Group container is unavailable, the app falls back to the app documents directory.

The runtime quote file is named:

```text
quotes.json
```

Private quote data is not committed to the repository.

## Widget Behavior

The widget reads quote data in this order:

1. App Group shared `UserDefaults`
2. App Group `quotes.json`
3. Local debug fallback, if present

Timeline entries are generated every 2 hours.

## Tests

Run tests from Xcode, or from Terminal:

```sh
xcodebuild -project KindleQuotes.xcodeproj -scheme KindleQuotes -destination 'platform=macOS' test
```

## Troubleshooting

If the widget does not update:

- Remove and re-add the widget.
- Restart Notification Center.
- Rebuild the app from Xcode.
- Make sure the app and widget both have the same App Group entitlement.
- Make sure Xcode signing uses your Apple Development team.

If Xcode reports a codesign error, check:

- Xcode > Settings > Accounts
- Your Apple Development certificate
- Keychain Access certificate trust settings
- App Group capability on both the app target and widget extension target

## Privacy

Kindle highlights can contain personal reading data. Do not commit generated quote JSON files or bundled quote files to a public repository.
