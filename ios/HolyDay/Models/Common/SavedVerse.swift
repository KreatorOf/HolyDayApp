import Foundation
import SwiftData

@Model
final class SavedVerse {
  var text: String
  var reference: String
  var note: String
  var savedAt: Date

  init(text: String, reference: String, note: String = "", savedAt: Date = .now) {
    self.text = text
    self.reference = reference
    self.note = note
    self.savedAt = savedAt
  }
}
