import Foundation
import SwiftData

@Model
final class IntentionUpdate {
  var text: String
  var createdAt: Date
  var intention: PrayerIntention?

  init(text: String, createdAt: Date = .now, intention: PrayerIntention? = nil) {
    self.text = text
    self.createdAt = createdAt
    self.intention = intention
  }
}
