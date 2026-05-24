import XCTest

@testable import HolyDay

final class VerseTests: XCTestCase {

  func test_init_storesAllFields() {
    let verse = Verse(text: "Test", reference: "Jean 3:16", book: "Jean", chapter: 3, verse: 16)
    XCTAssertEqual(verse.text, "Test")
    XCTAssertEqual(verse.reference, "Jean 3:16")
    XCTAssertEqual(verse.book, "Jean")
    XCTAssertEqual(verse.chapter, 3)
    XCTAssertEqual(verse.verse, 16)
  }

  func test_init_generatesUniqueIds() {
    let v1 = Verse(text: "A", reference: "A 1:1", book: "A", chapter: 1, verse: 1)
    let v2 = Verse(text: "B", reference: "B 1:1", book: "B", chapter: 1, verse: 1)
    XCTAssertNotEqual(v1.id, v2.id)
  }

  func test_codable_roundtrip() throws {
    let original = Verse(
      text: "Je puis tout", reference: "Phil 4:13", book: "Philippiens", chapter: 4, verse: 13)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Verse.self, from: data)

    XCTAssertEqual(decoded.id, original.id)
    XCTAssertEqual(decoded.text, original.text)
    XCTAssertEqual(decoded.reference, original.reference)
    XCTAssertEqual(decoded.chapter, original.chapter)
    XCTAssertEqual(decoded.verse, original.verse)
  }

  func test_idStability_whenProvidedExplicitly() {
    let fixedId = UUID()
    let verse = Verse(id: fixedId, text: "X", reference: "X 1:1", book: "X", chapter: 1, verse: 1)
    XCTAssertEqual(verse.id, fixedId)
  }
}
