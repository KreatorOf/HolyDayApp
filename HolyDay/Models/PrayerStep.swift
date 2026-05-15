//
//  PrayerStep.swift
//  Kairos
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation
import SwiftUI

struct PrayerStep: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let colorName: String
    let order: Int
    
    var color: Color {
        AppTheme.color(for: colorName)
    }
    
    init(id: UUID = UUID(), title: String, description: String, icon: String, colorName: String, order: Int) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.colorName = colorName
        self.order = order
    }
    
    static let defaultSteps: [PrayerStep] = [
        PrayerStep(
            title: "Adoration",
            description: "Prenez un moment pour reconnaître qui est Dieu. Méditez sur Sa grandeur, Sa bonté et Sa sainteté.",
            icon: "hands.sparkles",
            colorName: "adorationPurple",
            order: 1
        ),
        PrayerStep(
            title: "Confession",
            description: "Examinez votre cœur et confessez vos péchés. Recevez le pardon et la grâce de Dieu.",
            icon: "heart.circle",
            colorName: "confessionBlue",
            order: 2
        ),
        PrayerStep(
            title: "Reconnaissance",
            description: "Exprimez votre gratitude pour les bénédictions reçues. Remerciez Dieu pour Sa fidélité.",
            icon: "star.circle",
            colorName: "thanksgivingGold",
            order: 3
        ),
        PrayerStep(
            title: "Supplication",
            description: "Présentez vos demandes à Dieu. Priez pour vos besoins et ceux des autres.",
            icon: "bubble.left.and.bubble.right",
            colorName: "supplicationGreen",
            order: 4
        )
    ]
}
