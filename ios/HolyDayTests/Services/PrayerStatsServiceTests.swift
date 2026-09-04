import XCTest

@testable import HolyDay

final class PrayerStatsServiceTests: XCTestCase {

  func test_answeredIntentions_withNoIntentions_returnsZeroedStats() {
    let stats = PrayerStats.answeredIntentions([])
    XCTAssertEqual(stats.answeredCount, 0)
    XCTAssertEqual(stats.totalCount, 0)
    XCTAssertNil(stats.medianDelayDays)
  }

  func test_answeredIntentions_countsAnsweredSeparatelyFromTotal() {
    let intentions = [
      PrayerIntention(text: "Active"),
      PrayerIntention(
        text: "Exaucée", createdAt: daysAgo(10), isAnswered: true, answeredAt: daysAgo(2)),
    ]
    let stats = PrayerStats.answeredIntentions(intentions)
    XCTAssertEqual(stats.answeredCount, 1)
    XCTAssertEqual(stats.totalCount, 2)
  }

  func test_answeredIntentions_ignoresAnsweredIntentionsWithoutAnsweredDate() {
    let intention = PrayerIntention(text: "Exaucée sans date")
    intention.isAnswered = true
    let stats = PrayerStats.answeredIntentions([intention])
    XCTAssertEqual(stats.answeredCount, 1)
    XCTAssertNil(stats.medianDelayDays)
  }

  func test_answeredIntentions_medianDelay_forOddCount_isMiddleValue() {
    let intentions = [
      answered(createdDaysAgo: 30, answeredDaysAgo: 25),  // délai 5
      answered(createdDaysAgo: 30, answeredDaysAgo: 10),  // délai 20
      answered(createdDaysAgo: 30, answeredDaysAgo: 0),  // délai 30
    ]
    let stats = PrayerStats.answeredIntentions(intentions)
    XCTAssertEqual(stats.medianDelayDays, 20)
  }

  // MARK: - Helpers

  private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
  }

  private func answered(createdDaysAgo: Int, answeredDaysAgo: Int) -> PrayerIntention {
    PrayerIntention(
      text: "Intention", createdAt: daysAgo(createdDaysAgo), isAnswered: true,
      answeredAt: daysAgo(answeredDaysAgo))
  }
}
