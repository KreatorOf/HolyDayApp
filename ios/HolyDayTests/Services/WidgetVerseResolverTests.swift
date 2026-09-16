import XCTest

@testable import HolyDay

@MainActor
final class WidgetVerseResolverTests: XCTestCase {

  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
    return calendar
  }()

  private func date(_ day: Int, hour: Int = 9) throws -> Date {
    try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour)))
  }

  // Verset d'émotion tel que l'app l'écrit : texte localisé, référence avec sigle.
  private var peaceVerse: SharedVerse {
    let entry = VerseCorpus.all[2]
    return SharedVerse(
      text: entry.text(french: true), reference: "\(entry.referenceFR) (LSG)", emotionTag: "peace")
  }

  private func resolve(on day: Date, receivedOn received: Date?, skips: Int = 0) -> WidgetVerse {
    WidgetVerseResolver.resolve(
      on: day, lastVerse: received == nil ? nil : peaceVerse, lastVerseDate: received,
      skips: skips, french: true, calendar: calendar)
  }

  func test_emotionVerseReceivedToday_isShownAsIs() throws {
    let verse = resolve(on: try date(17, hour: 20), receivedOn: try date(17, hour: 8))
    XCTAssertEqual(verse.source, .emotion)
    XCTAssertEqual(verse.text, peaceVerse.text)
    XCTAssertEqual(verse.reference, peaceVerse.reference)
  }

  func test_emotionVerseFromYesterday_fallsBackToDailyVerse() throws {
    let verse = resolve(on: try date(18), receivedOn: try date(17))
    XCTAssertEqual(verse.source, .daily)
    XCTAssertEqual(verse.emotionTag, "")
  }

  func test_noVerseEver_showsDailyVerse() throws {
    let verse = resolve(on: try date(18), receivedOn: nil)
    XCTAssertEqual(verse.source, .daily)
    XCTAssertFalse(verse.text.isEmpty)
    XCTAssertTrue(verse.reference.hasSuffix("(LSG)"))
  }

  func test_dailyVerse_changesFromOneDayToTheNext() throws {
    XCTAssertNotEqual(
      resolve(on: try date(18), receivedOn: nil).text,
      resolve(on: try date(19), receivedOn: nil).text)
  }

  func test_skipOnEmotionVerse_changesTextAndKeepsTheme() throws {
    let today = try date(17)
    let skipped = resolve(on: today, receivedOn: today, skips: 1)
    XCTAssertEqual(skipped.source, .emotion)
    XCTAssertEqual(skipped.emotionTag, "peace")
    XCTAssertNotEqual(skipped.text, peaceVerse.text)
    let match = VerseCorpus.all.first { $0.textFR == skipped.text }
    XCTAssertEqual(match?.emotionTags.contains("peace"), true)
  }

  func test_skipOnDailyVerse_changesText() throws {
    let day = try date(18)
    XCTAssertNotEqual(
      resolve(on: day, receivedOn: nil).text,
      resolve(on: day, receivedOn: nil, skips: 1).text)
  }

  func test_routes_roundTripThroughURL() {
    for route in [AppRoute.pray, .freePrayer, .intentions, .journal] {
      XCTAssertEqual(AppRoute(url: route.url), route)
    }
    XCTAssertEqual(AppRoute(url: URL(fileURLWithPath: "/")), .pray)
  }

  func test_legacyVerseLink_opensPrayTab() throws {
    XCTAssertEqual(AppRoute(url: try XCTUnwrap(URL(string: "holyday://verse"))), .pray)
  }
}
