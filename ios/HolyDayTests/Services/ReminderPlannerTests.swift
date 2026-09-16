import XCTest

@testable import HolyDay

@MainActor
final class ReminderPlannerTests: XCTestCase {

  // Calendrier figé : les règles « même jour » / dimanche ne doivent pas dépendre de la machine.
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
    return calendar
  }()

  private func date(_ day: Int, hour: Int = 8, month: Int = 9) throws -> Date {
    let components = DateComponents(year: 2026, month: month, day: day, hour: hour)
    return try XCTUnwrap(calendar.date(from: components))
  }

  private func kind(on fireDate: Date, _ context: ReminderContext) -> ReminderKind? {
    ReminderPlanner.kind(for: fireDate, context: context, calendar: calendar)
  }

  // MARK: - Silence

  func test_prayedEarlierThatDay_skipsReminder() throws {
    let context = ReminderContext(lastPrayerDate: try date(16, hour: 0))
    XCTAssertNil(kind(on: try date(16, hour: 21), context))
  }

  func test_prayedYesterday_keepsReminder() throws {
    let context = ReminderContext(lastPrayerDate: try date(15, hour: 22))
    XCTAssertEqual(kind(on: try date(16), context), .question)
  }

  // MARK: - Émotion

  func test_emotionFollowUp_offersVerseOfThatThemeForTwoDays() throws {
    var context = ReminderContext.empty
    context.lastEmotion = .sadness
    context.lastEmotionDate = try date(16, hour: 20)

    for day in [17, 18] {
      guard case .verse(let index) = kind(on: try date(day), context) else {
        return XCTFail("verset attendu le \(day)")
      }
      XCTAssertTrue(VerseCorpus.all[index].emotionTags.contains("sadness"))
    }
    XCTAssertEqual(kind(on: try date(19), context), .question)
  }

  func test_emotionFollowUp_winsOverSundayIntentions() throws {
    var context = ReminderContext.empty
    context.lastEmotion = .fear
    context.lastEmotionDate = try date(19)
    context.oldestOpenIntentionDate = try date(1)

    guard case .verse = kind(on: try date(20), context) else {
      return XCTFail("le verset d'émotion doit primer")
    }
  }

  func test_verseIndex_isDeterministicPerDay() throws {
    let first = ReminderPlanner.verseIndex(for: .hope, on: try date(18), calendar: calendar)
    let second = ReminderPlanner.verseIndex(for: .hope, on: try date(18), calendar: calendar)
    XCTAssertNotNil(first)
    XCTAssertEqual(first, second)
  }

  // MARK: - Intentions

  func test_oldOpenIntention_invitesOnSundayOnly() throws {
    var context = ReminderContext.empty
    context.oldestOpenIntentionDate = try date(1)

    XCTAssertEqual(kind(on: try date(20), context), .intentions)
    XCTAssertEqual(kind(on: try date(21), context), .question)
  }

  func test_recentIntention_doesNotInviteYet() throws {
    var context = ReminderContext.empty
    context.oldestOpenIntentionDate = try date(14)
    XCTAssertEqual(kind(on: try date(20), context), .question)
  }

  func test_noIntention_neverInvites() throws {
    XCTAssertEqual(kind(on: try date(20), .empty), .question)
  }
}
