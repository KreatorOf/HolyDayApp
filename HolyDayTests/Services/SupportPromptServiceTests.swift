import XCTest

@testable import HolyDay

@MainActor
final class SupportPromptServiceTests: XCTestCase {

  // Suite isolée par test pour ne jamais toucher aux préférences réelles.
  private func makeDefaults() throws -> UserDefaults {
    let suite = "test.support.\(UUID().uuidString)"
    return try XCTUnwrap(UserDefaults(suiteName: suite))
  }

  private let day: TimeInterval = 86_400
  private let base = Date(timeIntervalSince1970: 1_000_000)

  // MARK: - Seuil

  func test_belowThreshold_doesNotPrompt() throws {
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 4 },
      hasTippedProvider: { false }
    )
    XCTAssertFalse(service.shouldPrompt)
  }

  func test_atThreshold_promptsOnFirstEligibility() throws {
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false }
    )
    XCTAssertTrue(service.shouldPrompt)
  }

  // MARK: - Donateur & opt-out

  func test_tipper_isNeverPrompted() throws {
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 50 },
      hasTippedProvider: { true }
    )
    XCTAssertFalse(service.shouldPrompt)
  }

  func test_dontAskAgain_suppressesForever() throws {
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 50 },
      hasTippedProvider: { false }
    )
    XCTAssertTrue(service.shouldPrompt)
    service.dontAskAgain()
    XCTAssertFalse(service.shouldPrompt)
  }

  // MARK: - Délai de repos (backoff)

  func test_firstCooldown_blocksWithin30DaysThenAllows() throws {
    var current = base
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false },
      now: { current }
    )

    XCTAssertTrue(service.shouldPrompt)
    service.markShown()  // timesShown = 1

    current = base.addingTimeInterval(10 * day)
    XCTAssertFalse(service.shouldPrompt, "Délai de 30 j non écoulé")

    current = base.addingTimeInterval(31 * day)
    XCTAssertTrue(service.shouldPrompt, "Délai de 30 j écoulé")
  }

  func test_secondCooldown_isNinetyDays() throws {
    var current = base
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false },
      now: { current }
    )

    service.markShown()  // 1
    current = base.addingTimeInterval(31 * day)
    service.markShown()  // 2 → prochain délai = 90 j

    current = base.addingTimeInterval((31 + 31) * day)
    XCTAssertFalse(service.shouldPrompt, "Délai de 90 j non écoulé")

    current = base.addingTimeInterval((31 + 91) * day)
    XCTAssertTrue(service.shouldPrompt, "Délai de 90 j écoulé")
  }

  // MARK: - Plafond

  func test_cap_afterThreeShows_neverPromptsAgain() throws {
    var current = base
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false },
      now: { current }
    )

    service.markShown()  // 1
    current = base.addingTimeInterval(200 * day)
    service.markShown()  // 2
    current = base.addingTimeInterval(400 * day)
    service.markShown()  // 3 (= plafond)

    current = base.addingTimeInterval(5_000 * day)
    XCTAssertFalse(service.shouldPrompt, "Plafond de 3 sollicitations atteint")
  }

  // MARK: - Persistance

  func test_stateIsPersistedAcrossInstances() throws {
    let defaults = try makeDefaults()
    let first = SupportPromptService(
      defaults: defaults,
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false },
      now: { self.base }
    )
    first.markShown()

    // Nouvelle instance partageant le même stockage : le délai doit toujours s'appliquer.
    let second = SupportPromptService(
      defaults: defaults,
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false },
      now: { self.base.addingTimeInterval(5 * self.day) }
    )
    XCTAssertFalse(second.shouldPrompt, "L'état doit être relu depuis le stockage partagé")
  }

  // MARK: - Reset (effacement complet)

  func test_reset_restoresPromptability() throws {
    let service = SupportPromptService(
      defaults: try makeDefaults(),
      prayedDaysProvider: { 5 },
      hasTippedProvider: { false }
    )
    service.dontAskAgain()
    XCTAssertFalse(service.shouldPrompt)

    service.reset()
    XCTAssertTrue(service.shouldPrompt, "Après reset, la sollicitation est de nouveau autorisée")
  }
}
