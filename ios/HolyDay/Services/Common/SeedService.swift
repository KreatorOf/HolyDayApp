//
//  SeedService.swift
//  HolyDay
//

import Foundation
import SwiftData

enum SeedService {
  #if DEBUG
    static func seedIfNeeded(in context: ModelContext) {
      let existing = (try? context.fetchCount(FetchDescriptor<PrayerEntry>())) ?? 0
      guard existing == 0 else { return }

      let calendar = Calendar.current
      let today = Date()
      guard
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today),
        let firstOfLastMonth = calendar.date(
          from: calendar.dateComponents([.year, .month], from: lastMonth)
        ),
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfLastMonth)?.count
      else { return }

      let steps = PrayerStep.defaultSteps
      let sampleTexts: [String] = [
        "Seigneur, je te loue pour ta grandeur et ta bonté infinie. Tu es digne de toute gloire.",
        "Pardonne-moi pour mes manquements d'aujourd'hui, Seigneur.",
        "Merci pour cette belle journée et les personnes que tu mets sur ma route.",
        "Je te confie ma famille et mes proches dans le besoin.",
        "Guide mes pas et éclaire mon chemin dans les décisions à venir.",
        "Je te rends grâce pour ta fidélité chaque matin.",
        "Que ta paix règne dans mon cœur et dans ma maison.",
        "Seigneur, sois avec ceux qui souffrent et qui cherchent ton visage.",
        "",
      ]

      for day in 0..<daysInMonth {
        guard let date = calendar.date(byAdding: .day, value: day, to: firstOfLastMonth) else {
          continue
        }
        let stepCount = Int.random(in: 1...4)
        for (i, step) in steps.shuffled().prefix(stepCount).enumerated() {
          let hour = 7 + i * 2
          let entryDate =
            calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date)
            ?? date
          let text = sampleTexts.randomElement() ?? ""
          let entry = PrayerEntry(
            stepTitle: step.title,
            stepIcon: step.icon,
            stepColorName: step.colorName,
            text: text,
            date: entryDate
          )
          context.insert(entry)
        }
      }

      try? context.save()
    }
  #endif

  private static var freeTexts: [String] {
    [
      String(localized: "demo.prayer.free.gratitude"),
      String(localized: "demo.prayer.free.peace"),
    ]
  }

  private static var guidedTexts: [String] {
    [
      String(localized: "demo.prayer.guided.faithfulness"),
      String(localized: "demo.prayer.guided.lovedOnes"),
    ]
  }

  /// Ajoute un jeu cohérent sans supprimer les données présentes. Cette méthode est compilée en
  /// Release pour TestFlight, mais son unique point d'entrée UI est protégé par `isTestFlight`.
  @MainActor
  static func seedDemoData(in context: ModelContext) {
    let steps = PrayerStep.defaultSteps
    let emotions = Emotion.allCases
    let calendar = Calendar.current

    for dayOffset in 0..<30 where dayOffset % 5 != 3 {
      guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
      let entriesForDay = dayOffset % 6 == 0 ? 2 : 1

      for index in 0..<entriesForDay {
        let seed = dayOffset + index
        let emotion = emotions[seed % emotions.count]
        let isFree = seed % 4 == 0
        let entry: PrayerEntry

        if isFree {
          entry = PrayerEntry(
            stepTitle: String(localized: "prayer.free.title"),
            stepIcon: "square.and.pencil",
            stepColorName: "adorationPurple",
            text: freeTexts[seed % freeTexts.count],
            date: day,
            duration: TimeInterval(120 + dayOffset * 15),
            emotion: emotion
          )
          entry.customTitle = PrayerEntry.fallbackTitle(from: entry.text)
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

    let family = PrayerIntention(text: String(localized: "demo.intention.family"))
    family.updates.append(
      IntentionUpdate(text: String(localized: "demo.intention.family.update"), intention: family))
    let answered = PrayerIntention(text: String(localized: "demo.intention.peace"))
    answered.isAnswered = true
    answered.answeredAt = calendar.date(byAdding: .day, value: -2, to: .now)

    for intention in [
      family,
      answered,
      PrayerIntention(text: String(localized: "demo.intention.wisdom")),
    ] {
      context.insert(intention)
    }

    try? context.save()
    PrayerRecordService.shared.refresh()
  }
}
