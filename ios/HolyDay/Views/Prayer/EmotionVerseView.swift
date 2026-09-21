//
//  EmotionVerseView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftData
import SwiftUI

/// Verset « nu » accompagnant une émotion : serif italique centré, révélé mot à mot comme une
/// parole qui se pose, puis la référence apparaît une fois le verset complet.
struct EmotionVerseView: View {
  let verse: Verse
  var accent: Color

  @Environment(\.modelContext) private var modelContext
  @Query private var savedVerses: [SavedVerse]
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var revealedCount = 0

  init(verse: Verse, accent: Color) {
    self.verse = verse
    self.accent = accent
  }

  // Les guillemets sont des tokens à part entière : « apparaît en premier, » en dernier, ce qui
  // évite un guillemet fermant flottant pendant la révélation.
  private var tokens: [String] {
    var result: [String] = ["«"]
    result.append(contentsOf: verse.text.split(separator: " ").map(String.init))
    result.append("»")
    return result
  }

  private var revealedText: String {
    tokens.prefix(revealedCount).joined(separator: " ")
  }

  private var isComplete: Bool { revealedCount >= tokens.count }

  var body: some View {
    VStack(spacing: 14) {
      Text(revealedText)
        .font(.system(.title3, design: .serif).italic())
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .contentTransition(.opacity)
        .animation(.easeOut(duration: 0.25), value: revealedCount)

      HStack(spacing: 12) {
        Text(verse.reference)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(accent)

        Button {
          toggleSaved()
        } label: {
          Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
            .frame(width: 44, height: 44)
        }
        .accessibilityLabel(
          String(localized: isSaved ? "savedVerses.remove" : "savedVerses.add"))
      }
      .opacity(isComplete ? 1 : 0)
      .animation(.easeOut(duration: 0.4), value: isComplete)
    }
    .padding(.horizontal, 32)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(verse.text) — \(verse.reference)")
    .task(id: verse.id) { await reveal() }
  }

  private var matchingSavedVerse: SavedVerse? {
    savedVerses.first { $0.text == verse.text && $0.reference == verse.reference }
  }

  private var isSaved: Bool { matchingSavedVerse != nil }

  private func toggleSaved() {
    if let matchingSavedVerse {
      modelContext.delete(matchingSavedVerse)
    } else {
      modelContext.insert(SavedVerse(text: verse.text, reference: verse.reference))
    }
  }

  private func reveal() async {
    guard !reduceMotion else {
      revealedCount = tokens.count
      return
    }
    revealedCount = 0
    for index in 1...tokens.count {
      try? await Task.sleep(for: .milliseconds(110))
      revealedCount = index
    }
  }
}

#Preview {
  ZStack {
    AppBackground()
    EmotionVerseView(
      verse: Verse(
        text: "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets.",
        reference: "Ésaïe 41:10", book: "Ésaïe", chapter: 41, verse: 10
      ),
      accent: AppTheme.adorationPurple
    )
  }
  .preferredColorScheme(.dark)
}
