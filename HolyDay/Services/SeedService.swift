//
//  SeedService.swift
//  HolyDay
//

#if DEBUG
import Foundation
import SwiftData

enum SeedService {
    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<PrayerEntry>())) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        let today = Date()
        guard
            let firstOfLastMonth = calendar.date(
                from: calendar.dateComponents([.year, .month],
                from: calendar.date(byAdding: .month, value: -1, to: today)!)
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
            ""
        ]

        for day in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: day, to: firstOfLastMonth) else { continue }
            let stepCount = Int.random(in: 1...4)
            for (i, step) in steps.shuffled().prefix(stepCount).enumerated() {
                let hour = 7 + i * 2
                let entryDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) ?? date
                let text = sampleTexts.randomElement()!
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
}
#endif
