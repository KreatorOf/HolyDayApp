//
//  VerseRecallView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 08/06/2026.
//

import SwiftUI

/// Rappel du verset en cours, affiché en tête des feuilles de prière (libre et guidée) pour garder
/// le contexte émotionnel pendant la saisie ou le parcours.
struct VerseRecallView: View {
  let verse: Verse
  var accent: Color = AppTheme.adorationPurple

  var body: some View {
    VStack(spacing: 10) {
      Text(verbatim: "« \(verse.text) »")
        .font(.system(.callout, design: .serif).italic())
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(6)
      Text(verse.reference)
        .font(.caption.weight(.semibold))
        .foregroundStyle(accent)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(verse.text) — \(verse.reference)")
  }
}

#Preview {
  ZStack {
    AppBackground()
    VerseRecallView(
      verse: Verse(
        text: "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets.",
        reference: "Ésaïe 41:10", book: "Ésaïe", chapter: 41, verse: 10
      ),
      accent: AppTheme.adorationPurple
    )
    .padding(.horizontal, 28)
  }
  .preferredColorScheme(.dark)
}
