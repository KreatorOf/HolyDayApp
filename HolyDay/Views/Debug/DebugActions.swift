//
//  DebugActions.swift
//  HolyDay
//
//  Menu développeur — compilé uniquement en DEBUG, exclu du binaire de production.
//  Libellés volontairement en dur (hors prod) : exception assumée à la règle de localisation.
//

#if DEBUG

  import SwiftData
  import SwiftUI

  @MainActor
  enum DebugActions {

    // MARK: - Resets

    static func resetPrayerRecord() {
      PrayerRecordService.shared.reset()
    }

    static func clearPrayers(in context: ModelContext) {
      try? context.delete(model: PrayerEntry.self)
    }

    static func clearIntentions(in context: ModelContext) {
      try? context.delete(model: PrayerIntention.self)
    }

    // MARK: - Seed

    private static let freeTexts = [
      "Seigneur, merci pour cette journée et pour ta présence à chaque instant.",
      "Je remets entre tes mains ce qui m'inquiète. Donne-moi la paix.",
      "Apprends-moi à aimer comme tu aimes, sans condition.",
      "Merci pour ma famille, veille sur chacun d'eux aujourd'hui.",
      "Je veux marcher avec toi, pas à pas, sans me presser.",
    ]

    private static let guidedTexts = [
      "Je t'adore pour ta fidélité qui ne change jamais.",
      "Je reconnais mes manques et je reçois ton pardon.",
      "Merci pour les petites grâces de cette semaine.",
      "Je te confie ceux que j'aime et ceux qui souffrent.",
      "Tu es bon, et ta bonté me poursuit chaque jour.",
    ]

    private static let emotions: [Emotion] = [
      .joy, .peace, .gratitude, .hope, .sadness, .fatigue, .fear, .anger,
    ]

    /// Injecte ~14 jours de prières variées (guidées + libres, émotions, certaines exaucées)
    /// pour peupler journal, graphe d'émotions et statistiques sans saisie manuelle.
    static func seedDemoPrayers(in context: ModelContext) {
      let steps = PrayerStep.defaultSteps
      let calendar = Calendar.current

      for dayOffset in 0..<14 {
        guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
        let entriesForDay = dayOffset % 3 == 0 ? 2 : 1

        for index in 0..<entriesForDay {
          let seed = dayOffset + index
          let emotion = emotions[seed % emotions.count]
          let isFree = seed % 4 == 0

          let entry: PrayerEntry
          if isFree {
            entry = PrayerEntry(
              stepTitle: "Prière libre",
              stepIcon: "square.and.pencil",
              stepColorName: "adorationPurple",
              text: freeTexts[seed % freeTexts.count],
              date: day,
              duration: TimeInterval(120 + dayOffset * 15),
              emotion: emotion
            )
          } else {
            let step = steps[seed % steps.count]
            entry = PrayerEntry(
              stepTitle: step.title,
              stepIcon: step.icon,
              stepColorName: step.colorName,
              text: guidedTexts[seed % guidedTexts.count],
              date: day,
              duration: TimeInterval(90 + dayOffset * 10),
              emotion: emotion
            )
          }
          context.insert(entry)
        }
      }

      let answered = PrayerIntention(text: "Trouver la paix intérieure")
      answered.isAnswered = true
      answered.answeredAt = .now
      for intention in [
        PrayerIntention(text: "Pour la santé de ma famille"),
        answered,
        PrayerIntention(text: "Sagesse pour une décision importante"),
      ] {
        context.insert(intention)
      }
    }
  }

#endif
