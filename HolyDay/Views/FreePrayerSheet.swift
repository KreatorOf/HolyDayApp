//
//  FreePrayerSheet.swift
//  HolyDay
//
//  Created by Matthias Cadet on 08/06/2026.
//

import SwiftUI

/// Saisie de prière libre présentée en feuille depuis le menu « Prier ». Le verset et l'émotion en
/// cours sont rappelés en tête pour garder le contexte. L'enregistrement est délégué à l'appelant
/// via `onSave` : ainsi la logique de persistance, de streak et de sollicitation de don reste
/// centralisée dans `ContentView`.
struct FreePrayerSheet: View {
  let verse: Verse?
  let accent: Color
  var onSave: (String) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var prayerText = ""
  @State private var savedHaptic = 0
  @FocusState private var isFocused: Bool

  private var canSave: Bool {
    !prayerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          if let verse {
            VerseRecallView(verse: verse, accent: accent)
              .padding(.horizontal, 28)
          }
          composer
          amenButton
        }
        .padding(.top, 12)
      }
      .scrollDismissesKeyboard(.interactively)
      .background { AppBackground() }
      .navigationTitle("prayer.free.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("common.cancel") { dismiss() }
        }
      }
      .onAppear { isFocused = true }
      // Prière libre enregistrée : retour d'accomplissement, cohérent avec le « Prier » de la
      // prière guidée (PrayerStepView).
      .sensoryFeedback(.success, trigger: savedHaptic)
    }
  }

  // MARK: - Subviews

  private var composer: some View {
    TextField("prayer.free.placeholder", text: $prayerText, axis: .vertical)
      .font(.body)
      .foregroundStyle(AppTheme.textPrimary)
      .focused($isFocused)
      .lineLimit(4...14)
      .padding(16)
      .glassEffect(
        .regular.interactive(),
        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
      )
      .padding(.horizontal, 20)
  }

  // Compact, juste sous la zone de saisie : l'action de validation suit naturellement la prière.
  private var amenButton: some View {
    Button {
      savedHaptic += 1
      onSave(prayerText)
      dismiss()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "hands.sparkles")
        Text("prayer.free.amen")
      }
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 28)
      .padding(.vertical, 11)
      .background(AppTheme.adorationPurple, in: .capsule)
    }
    .buttonStyle(.plain)
    .disabled(!canSave)
    .opacity(canSave ? 1 : 0.45)
    .animation(.easeInOut(duration: 0.2), value: canSave)
  }
}

#Preview {
  FreePrayerSheet(
    verse: Verse(
      text: "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets.",
      reference: "Ésaïe 41:10", book: "Ésaïe", chapter: 41, verse: 10
    ),
    accent: AppTheme.adorationPurple,
    onSave: { _ in }
  )
  .preferredColorScheme(.dark)
}
