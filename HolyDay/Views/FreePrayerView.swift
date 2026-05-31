//
//  FreePrayerView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftData
import SwiftUI

struct FreePrayerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var tipService = TipService.shared
  @State private var text = ""
  @State private var detected: [String] = []
  @State private var selected: Set<String> = []
  @State private var showSuggestions = false
  @State private var isProcessing = false
  @FocusState private var isFocused: Bool

  private var canSave: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        contentLayer
        if isProcessing { processingOverlay }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("prayer.free.nav.title")
            .font(.system(.callout, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
    .sheet(isPresented: $showSuggestions, onDismiss: { dismiss() }) {
      suggestionSheet
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        isFocused = true
      }
    }
  }

  // MARK: - Content

  private var contentLayer: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        if text.isEmpty {
          Text("prayer.free.placeholder")
            .font(.body)
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .allowsHitTesting(false)
        }
        TextEditor(text: $text)
          .font(.body)
          .foregroundStyle(AppTheme.textPrimary)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 16)
          .focused($isFocused)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Button {
        save()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "hands.sparkles.fill")
          Text("prayer.free.amen")
        }
        .font(.system(.callout, design: .serif, weight: .bold))
        .tracking(1.0)
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
      }
      .buttonStyle(.plain)
      .glassEffect(
        .regular.tint(AppTheme.adorationPurple.opacity(canSave ? 0.5 : 0.15)), in: Capsule()
      )
      .disabled(!canSave)
      .animation(.easeInOut(duration: 0.2), value: canSave)
      .padding(.bottom, 32)
    }
    .padding(.top, 8)
  }

  private var processingOverlay: some View {
    ZStack {
      Color.black.opacity(0.15).ignoresSafeArea()
      ProgressView()
        .tint(AppTheme.adorationPurple)
        .scaleEffect(1.3)
    }
  }

  // MARK: - Suggestion sheet

  private var suggestionSheet: some View {
    VStack(spacing: 0) {
      VStack(spacing: 6) {
        Text("intentions.suggest.title")
          .font(.system(.title3, design: .serif, weight: .semibold))
          .foregroundStyle(AppTheme.textPrimary)
        Text("intentions.suggest.subtitle")
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
          .multilineTextAlignment(.center)
      }
      .padding(.top, 28)
      .padding(.horizontal, 24)

      ScrollView {
        VStack(spacing: 8) {
          ForEach(detected, id: \.self) { intention in
            suggestionRow(intention)
          }
        }
        .padding(16)
      }

      VStack(spacing: 10) {
        Button {
          addSelected()
        } label: {
          Text("intentions.suggest.add")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
              AppTheme.adorationPurple,
              in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(selected.isEmpty)
        .opacity(selected.isEmpty ? 0.4 : 1)

        Button {
          showSuggestions = false
        } label: {
          Text("intentions.suggest.skip")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .background(AppTheme.backgroundPrimary.ignoresSafeArea())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func suggestionRow(_ intention: String) -> some View {
    let isOn = selected.contains(intention)
    return Button {
      if isOn { selected.remove(intention) } else { selected.insert(intention) }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
          .font(.title3)
          .foregroundStyle(isOn ? AppTheme.adorationPurple : AppTheme.textTertiary)
        Text(intention)
          .font(.body)
          .foregroundStyle(AppTheme.textPrimary)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(intention)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }

  // MARK: - Helpers

  private func save() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let entry = PrayerEntry(
      stepTitle: String(localized: "prayer.free.title"),
      stepIcon: "square.and.pencil",
      stepColorName: "adorationPurple",
      text: trimmed
    )
    modelContext.insert(entry)
    StreakService.shared.recordPrayer()

    // Only the AI tier gets intention detection; otherwise dismiss immediately.
    guard tipService.hasAIFeature else {
      dismiss()
      return
    }
    Task { await detectIntentions(in: trimmed) }
  }

  private func detectIntentions(in text: String) async {
    isProcessing = true
    let found = (try? await AIAssistantService.shared.detectIntentions(in: text)) ?? []
    isProcessing = false
    guard !found.isEmpty else {
      dismiss()
      return
    }
    detected = found
    selected = Set(found)
    showSuggestions = true
  }

  private func addSelected() {
    for intention in detected where selected.contains(intention) {
      modelContext.insert(PrayerIntention(text: intention))
    }
    showSuggestions = false
  }
}
