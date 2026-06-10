import XCTest

@testable import HolyDay

@MainActor
final class PrayerGuideViewModelTests: XCTestCase {

  var sut: PrayerGuideViewModel!

  override func setUp() {
    super.setUp()
    sut = PrayerGuideViewModel()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: - État initial

  func test_init_loadsFourSteps() {
    XCTAssertEqual(sut.prayerSteps.count, 4)
  }

  func test_init_progressIsZero() {
    XCTAssertEqual(sut.progressPercentage, 0.0, accuracy: 0.001)
  }

  func test_init_isAllCompletedIsFalse() {
    XCTAssertFalse(sut.isAllCompleted)
  }

  func test_init_noExpandedStep() {
    XCTAssertNil(sut.expandedStepId)
  }

  // MARK: - Progression

  func test_markCompleted_addsToCompletedSet() {
    let step = sut.prayerSteps[0]
    sut.markCompleted(step)
    XCTAssertTrue(sut.completedSteps.contains(step.id))
  }

  func test_markCompleted_oneStep_progressIs25Percent() {
    sut.markCompleted(sut.prayerSteps[0])
    XCTAssertEqual(sut.progressPercentage, 0.25, accuracy: 0.001)
  }

  func test_markCompleted_twoSteps_progressIs50Percent() {
    sut.markCompleted(sut.prayerSteps[0])
    sut.markCompleted(sut.prayerSteps[1])
    XCTAssertEqual(sut.progressPercentage, 0.50, accuracy: 0.001)
  }

  func test_markCompleted_allSteps_isAllCompletedIsTrue() {
    sut.prayerSteps.forEach { sut.markCompleted($0) }
    XCTAssertTrue(sut.isAllCompleted)
    XCTAssertEqual(sut.progressPercentage, 1.0, accuracy: 0.001)
  }

  func test_isCompleted_returnsFalseBeforeMark() {
    let step = sut.prayerSteps[0]
    XCTAssertFalse(sut.isCompleted(step))
  }

  func test_isCompleted_returnsTrueAfterMark() {
    let step = sut.prayerSteps[0]
    sut.markCompleted(step)
    XCTAssertTrue(sut.isCompleted(step))
  }

  // MARK: - Expansion

  func test_toggleStep_expandsStep() {
    let step = sut.prayerSteps[0]
    sut.toggleStep(step)
    XCTAssertTrue(sut.isExpanded(step))
  }

  func test_toggleStep_collapsesIfAlreadyExpanded() {
    let step = sut.prayerSteps[0]
    sut.toggleStep(step)
    sut.toggleStep(step)
    XCTAssertFalse(sut.isExpanded(step))
  }

  func test_toggleStep_onlyOneStepExpandedAtATime() {
    let s1 = sut.prayerSteps[0]
    let s2 = sut.prayerSteps[1]
    sut.toggleStep(s1)
    sut.toggleStep(s2)
    XCTAssertFalse(sut.isExpanded(s1))
    XCTAssertTrue(sut.isExpanded(s2))
  }

  func test_markCompleted_collapsesExpandedStep() {
    let step = sut.prayerSteps[0]
    sut.toggleStep(step)
    sut.markCompleted(step)
    XCTAssertNil(sut.expandedStepId)
  }

  // MARK: - Reset

  func test_resetProgress_clearsCompletedSteps() {
    sut.prayerSteps.forEach { sut.markCompleted($0) }
    sut.resetProgress()
    XCTAssertTrue(sut.completedSteps.isEmpty)
  }

  func test_resetProgress_clearsPrayerTexts() {
    sut.prayerTexts[sut.prayerSteps[0].id] = "texte de prière"
    sut.resetProgress()
    XCTAssertTrue(sut.prayerTexts.isEmpty)
  }

  func test_resetProgress_resetsProgress() {
    sut.prayerSteps.forEach { sut.markCompleted($0) }
    sut.resetProgress()
    XCTAssertEqual(sut.progressPercentage, 0.0, accuracy: 0.001)
    XCTAssertFalse(sut.isAllCompleted)
  }

  func test_resetProgress_closesExpandedStep() {
    sut.toggleStep(sut.prayerSteps[0])
    sut.resetProgress()
    XCTAssertNil(sut.expandedStepId)
  }
}
