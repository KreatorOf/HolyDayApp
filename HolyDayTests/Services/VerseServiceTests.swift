import XCTest

@testable import HolyDay

@MainActor
final class VerseServiceTests: XCTestCase {

  func test_verseForEmotion_returnsNonEmptyText_forAllEmotions() {
    for emotion in Emotion.allCases {
      let verse = VerseService.shared.verse(for: emotion)
      XCTAssertFalse(verse.text.isEmpty, "Texte vide pour \(emotion.rawValue)")
    }
  }

  func test_verseForEmotion_hasValidReference_forAllEmotions() {
    for emotion in Emotion.allCases {
      let verse = VerseService.shared.verse(for: emotion)
      XCTAssertFalse(verse.reference.isEmpty, "Référence vide pour \(emotion.rawValue)")
      XCTAssertFalse(verse.book.isEmpty, "Livre vide pour \(emotion.rawValue)")
      XCTAssertGreaterThan(verse.chapter, 0)
      XCTAssertGreaterThan(verse.verse, 0)
    }
  }

  // Chaque émotion doit avoir au moins deux versets : c'est ce qui garantit que re-taper une
  // émotion propose un autre verset (comportement documenté de la pioche).
  func test_corpus_coversEveryEmotionWithAtLeastTwoVerses() {
    for emotion in Emotion.allCases {
      let pool = VerseCorpus.all.filter { $0.emotionTags.contains(emotion.rawValue) }
      XCTAssertGreaterThanOrEqual(
        pool.count, 2, "Le thème \(emotion.rawValue) a moins de deux versets")
    }
  }

  func test_verseForEmotion_avoidsImmediateRepetition() {
    for emotion in Emotion.allCases {
      let v1 = VerseService.shared.verse(for: emotion)
      let v2 = VerseService.shared.verse(for: emotion)
      XCTAssertNotEqual(
        v1.reference, v2.reference,
        "Répétition immédiate pour \(emotion.rawValue)")
    }
  }

  // Épuise plusieurs fois la pioche de chaque thème : le re-mélange ne doit jamais sortir des
  // bornes du corpus ni boucler à vide.
  func test_verseForEmotion_survivesDeckExhaustion() {
    for emotion in Emotion.allCases {
      for _ in 0..<(VerseCorpus.all.count * 3) {
        let verse = VerseService.shared.verse(for: emotion)
        XCTAssertFalse(verse.text.isEmpty)
      }
    }
  }
}
