//
//  PrayerEntryDetailView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftData
import SwiftUI

struct PrayerEntryDetailView: View {
  let entry: PrayerEntry

  @State private var titleDraft = ""
  @State private var isRegenerating = false
  @FocusState private var titleFocused: Bool

  // Le titre est éditable pour toute prière libre — que l'IA l'ait nommée ou non (titre suggéré,
  // repli, ou aucun). Les étapes guidées gardent leur catégorie ACTS en titre figé.
  private var isTitleEditable: Bool { entry.isFreePrayer }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        entryHeader
        Divider()
          .overlay(Color.white.opacity(0.12))
        prayerContent
        if entry.stepColorName == "supplicationGreen" {
          answeredButton
        }
      }
      .padding(20)
    }
    .navigationBarTitleDisplayMode(.inline)
    .background { AppBackground() }
  }

  private var answeredButton: some View {
    Button {
      entry.isAnswered.toggle()
      entry.answeredAt = entry.isAnswered ? .now : nil
    } label: {
      HStack(spacing: 10) {
        Image(systemName: entry.isAnswered ? "checkmark.seal.fill" : "checkmark.seal")
          .font(.callout.weight(.semibold))
        Text(entry.isAnswered ? "entry.answered.label" : "entry.mark.answered.label")
          .font(.subheadline.weight(.semibold))
      }
      .foregroundStyle(entry.isAnswered ? Color.black.opacity(0.7) : AppTheme.supplicationGreen)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(
            entry.isAnswered ? AppTheme.supplicationGreen : AppTheme.supplicationGreen.opacity(0.12)
          )
          .overlay {
            if !entry.isAnswered {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.supplicationGreen.opacity(0.4), lineWidth: 1)
            }
          }
      }
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: entry.isAnswered)
  }

  private var entryHeader: some View {
    HStack(spacing: 14) {
      Image(systemName: entry.stepIcon)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(entry.accentColor)
        .frame(width: 50, height: 50)
        .background(entry.accentColor.opacity(0.15))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        titleRow
        subtitleRow
      }
      Spacer()
    }
    .onAppear { titleDraft = entry.displayTitle }
  }

  @ViewBuilder private var titleRow: some View {
    if isTitleEditable {
      HStack(spacing: 8) {
        TextField("entry.title.placeholder", text: $titleDraft, axis: .vertical)
          .font(.title3.weight(.bold))
          .textInputAutocapitalization(.sentences)
          .focused($titleFocused)
          .submitLabel(.done)
          .onSubmit(commitTitle)
          .onChange(of: titleFocused) { _, focused in
            if !focused { commitTitle() }
          }
        if showsRegenerate {
          regenerateButton
        }
      }
    } else {
      Text(entry.stepTitle)
        .font(.title3)
        .fontWeight(.bold)
    }
  }

  private var subtitleRow: some View {
    HStack(spacing: 6) {
      if entry.titleSource == .ai {
        Text("entry.title.suggested")
        Text(verbatim: "·")
      }
      Text(entry.date.formatted(date: .long, time: .shortened))
    }
    .font(.subheadline)
    .foregroundStyle(AppTheme.textSecondary)
  }

  // Régénération possible seulement tant que l'utilisateur n'a pas pris la main sur le titre, et si
  // le modèle on-device est réellement disponible.
  private var showsRegenerate: Bool {
    entry.titleSource != .user && AIAssistantService.shared.isAvailable && !entry.text.isEmpty
  }

  private var regenerateButton: some View {
    Button(action: regenerateTitle) {
      Image(systemName: "sparkles")
        .font(.callout.weight(.semibold))
        .foregroundStyle(entry.accentColor)
        .symbolEffect(.variableColor, isActive: isRegenerating)
    }
    .buttonStyle(.plain)
    .disabled(isRegenerating)
    .accessibilityLabel(Text("entry.title.regenerate"))
  }

  // MARK: - Title actions

  private func commitTitle() {
    let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      titleDraft = entry.displayTitle  // refus d'un titre vide : on rétablit l'existant
      return
    }
    guard trimmed != entry.customTitle else { return }
    entry.customTitle = trimmed
    entry.titleSource = .user
  }

  private func regenerateTitle() {
    guard !isRegenerating else { return }
    isRegenerating = true
    Task { @MainActor in
      defer { isRegenerating = false }
      if let aiTitle = await AIAssistantService.shared.generateTitle(for: entry.text),
        entry.titleSource != .user
      {
        entry.customTitle = aiTitle
        entry.titleSource = .ai
        titleDraft = aiTitle
      }
    }
  }

  private var prayerContent: some View {
    Group {
      if entry.text.isEmpty {
        Text("entry.no.text")
          .font(.body)
          .foregroundStyle(AppTheme.textSecondary)
          .italic()
      } else {
        Text(entry.text)
          .font(.body)
          .lineSpacing(8)
      }
    }
  }
}

#Preview {
  NavigationStack {
    PrayerEntryDetailView(
      entry: PrayerEntry(
        stepTitle: "Adoration",
        stepIcon: "hands.sparkles",
        stepColorName: "adorationPurple",
        text:
          "Seigneur, je te loue pour ta grandeur et ta bonté infinie. Tu es digne de toute gloire et de tout honneur.",
        date: .now
      ))
  }
  .preferredColorScheme(.dark)
}
