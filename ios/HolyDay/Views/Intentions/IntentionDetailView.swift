//
//  IntentionDetailView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 09/06/2026.
//

import SwiftData
import SwiftUI

// Fiche détail d'un sujet de prière, présentée en feuille depuis l'appui simple sur une ligne.
// Lecture du texte complet + métadonnées, et actions principales (exaucer/restaurer, modifier,
// supprimer) dans une barre ancrée en bas conforme aux HIG.
struct IntentionDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let intention: PrayerIntention

  @State private var isEditing = false
  @State private var draft = ""
  @State private var answeredHaptic = 0
  @State private var restoredHaptic = 0
  @State private var removedHaptic = 0
  @State private var savedHaptic = 0
  @State private var updateDraft = ""
  @FocusState private var isFocused: Bool

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ZStack {
        AppBackground()

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            statusBadge
            intentionText
            metadata
            updatesSection
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(24)
        }
        .scrollIndicators(.hidden)
      }
      .safeAreaInset(edge: .bottom) { actionBar }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          AppCloseButton { dismiss() }
        }
        if isEditing {
          ToolbarItem(placement: .topBarTrailing) {
            Button("intentions.edit.save") { commitEdit() }
              .fontWeight(.semibold)
              .disabled(draftIsEmpty)
          }
        }
      }
    }
    .sensoryFeedback(.success, trigger: answeredHaptic)
    .sensoryFeedback(.selection, trigger: restoredHaptic)
    .sensoryFeedback(.selection, trigger: savedHaptic)
    .sensoryFeedback(.impact(weight: .medium), trigger: removedHaptic)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  // MARK: - Pieces

  private var statusBadge: some View {
    let answered = intention.isAnswered
    return Label(
      answered
        ? String(localized: "intentions.section.answered")
        : String(localized: "intentions.section.active"),
      systemImage: answered ? "checkmark.seal.fill" : "hands.and.sparkles.fill"
    )
    .font(.caption.weight(.semibold))
    .foregroundStyle(answered ? AppTheme.supplicationGreen : AppTheme.adorationPurple)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .appGlassEffect(
      tint: (answered ? AppTheme.supplicationGreen : AppTheme.adorationPurple).opacity(0.18),
      in: .capsule)
  }

  @ViewBuilder
  private var intentionText: some View {
    if isEditing {
      TextField("intentions.add.placeholder", text: $draft, axis: .vertical)
        .font(.title3)
        .foregroundStyle(AppTheme.textPrimary)
        .focused($isFocused)
        .lineLimit(3...10)
        .padding(16)
        .background {
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppTheme.cardSurface)
            .overlay {
              RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
            }
        }
    } else {
      Text(intention.text)
        .font(.title3)
        .foregroundStyle(AppTheme.textPrimary)
        .strikethrough(intention.isAnswered, color: AppTheme.textTertiary)
        .textSelection(.enabled)
    }
  }

  private var metadata: some View {
    VStack(alignment: .leading, spacing: 8) {
      metadataRow(
        icon: "calendar",
        text: String(
          format: String(localized: "intentions.detail.added"),
          intention.createdAt.formatted(date: .long, time: .omitted)))

      if intention.isAnswered, let answeredAt = intention.answeredAt {
        metadataRow(
          icon: "checkmark.seal",
          text: String(
            format: String(localized: "intentions.detail.answered"),
            answeredAt.formatted(date: .long, time: .omitted)))
      }
    }
  }

  private func metadataRow(icon: String, text: String) -> some View {
    Label(text, systemImage: icon)
      .font(.subheadline)
      .foregroundStyle(AppTheme.textSecondary)
  }

  private var updatesSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("intentions.updates.title")
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)

      HStack(alignment: .bottom, spacing: 10) {
        TextField("intentions.updates.placeholder", text: $updateDraft, axis: .vertical)
          .lineLimit(1...4)
          .padding(12)
          .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14))
        Button {
          addUpdate()
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title2)
            .frame(width: 44, height: 44)
        }
        .disabled(updateDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityLabel(Text("intentions.updates.add"))
      }

      if intention.updates.isEmpty {
        Text("intentions.updates.empty")
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
      } else {
        ForEach(intention.updates.sorted { $0.createdAt > $1.createdAt }) { update in
          VStack(alignment: .leading, spacing: 5) {
            Text(update.text)
              .foregroundStyle(AppTheme.textPrimary)
            Text(update.createdAt.formatted(date: .abbreviated, time: .shortened))
              .font(.caption)
              .foregroundStyle(AppTheme.textTertiary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
          .contextMenu {
            Button("common.delete", systemImage: "trash", role: .destructive) {
              modelContext.delete(update)
            }
          }
        }
      }
    }
    .padding(.top, 8)
  }

  // MARK: - Action bar

  private var actionBar: some View {
    VStack(spacing: 12) {
      if intention.isAnswered {
        Button {
          restore()
        } label: {
          Label("intentions.action.restore", systemImage: "arrow.uturn.backward")
            .frame(maxWidth: .infinity)
        }
        .tint(AppTheme.adorationPurple)
      } else {
        Button {
          answer()
        } label: {
          Label("intentions.action.glory", systemImage: "hands.sparkles.fill")
            .frame(maxWidth: .infinity)
        }
        .tint(AppTheme.supplicationGreen)
      }

      HStack(spacing: 12) {
        Button {
          startEdit()
        } label: {
          Label("intentions.action.edit", systemImage: "pencil")
            .frame(maxWidth: .infinity)
        }
        .tint(AppTheme.textPrimary)

        Button(role: .destructive) {
          delete()
        } label: {
          Label("common.delete", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
        .tint(.red)
      }
    }
    .font(.headline)
    .appGlassButtonStyle()
    .controlSize(.large)
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
  }

  // MARK: - Actions

  private var draftIsEmpty: Bool {
    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func answer() {
    intention.isAnswered = true
    intention.answeredAt = .now
    answeredHaptic += 1
    dismiss()
  }

  private func addUpdate() {
    let trimmed = updateDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    intention.updates.append(IntentionUpdate(text: trimmed, intention: intention))
    updateDraft = ""
    savedHaptic += 1
  }

  private func restore() {
    intention.isAnswered = false
    intention.answeredAt = nil
    restoredHaptic += 1
    dismiss()
  }

  private func startEdit() {
    draft = intention.text
    withAnimation(.smooth(duration: 0.25)) { isEditing = true }
    isFocused = true
  }

  private func commitEdit() {
    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty { intention.text = trimmed }
    savedHaptic += 1
    withAnimation(.smooth(duration: 0.25)) { isEditing = false }
  }

  private func delete() {
    removedHaptic += 1
    modelContext.delete(intention)
    dismiss()
  }
}

#Preview {
  IntentionDetailView(intention: PrayerIntention(text: "Guérison de ma grand-mère"))
    .modelContainer(for: [PrayerIntention.self, IntentionUpdate.self], inMemory: true)
    .preferredColorScheme(.dark)
}
