//
//  IntentionsView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftData
import SwiftUI

struct IntentionsView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \PrayerIntention.createdAt, order: .reverse) private var intentions:
    [PrayerIntention]
  @State private var newText = ""
  @FocusState private var isInputFocused: Bool

  private var active: [PrayerIntention] { intentions.filter { !$0.isAnswered } }
  private var answered: [PrayerIntention] { intentions.filter(\.isAnswered) }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          addCard
          if intentions.isEmpty {
            emptyState
          } else {
            if !active.isEmpty {
              intentionSection(
                title: String(localized: "intentions.section.active"), items: active)
            }
            if !answered.isEmpty {
              intentionSection(
                title: String(localized: "intentions.section.answered"), items: answered)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 40)
      }
      .scrollIndicators(.hidden)
      .background { AnimatedMeshBackground().ignoresSafeArea() }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("intentions.nav.title")
            .font(.system(.callout, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
  }

  // MARK: - Add

  private var addCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "plus.circle.fill")
        .font(.title3)
        .foregroundStyle(AppTheme.adorationPurple)

      TextField("intentions.add.placeholder", text: $newText, axis: .vertical)
        .font(.body)
        .foregroundStyle(AppTheme.textPrimary)
        .focused($isInputFocused)
        .submitLabel(.done)
        .onSubmit(add)

      if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Button(action: add) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title3)
            .foregroundStyle(AppTheme.adorationPurple)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "intentions.suggest.add"))
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  // MARK: - Section

  private func intentionSection(title: String, items: [PrayerIntention]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(1.0)
        .padding(.horizontal, 4)

      VStack(spacing: 8) {
        ForEach(items) { intention in
          intentionRow(intention)
        }
      }
    }
  }

  private func intentionRow(_ intention: PrayerIntention) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Button {
        toggle(intention)
      } label: {
        Image(systemName: intention.isAnswered ? "checkmark.seal.fill" : "circle")
          .font(.title3)
          .foregroundStyle(
            intention.isAnswered ? AppTheme.supplicationGreen : AppTheme.textTertiary
          )
          .frame(width: 44, height: 44)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.success, trigger: intention.isAnswered)
      .accessibilityLabel(intention.text)
      .accessibilityValue(
        String(
          localized: intention.isAnswered
            ? "intentions.section.answered" : "intentions.section.active")
      )
      .accessibilityAddTraits(intention.isAnswered ? .isSelected : [])

      VStack(alignment: .leading, spacing: 3) {
        Text(intention.text)
          .font(.body)
          .foregroundStyle(intention.isAnswered ? AppTheme.textSecondary : AppTheme.textPrimary)
          .strikethrough(intention.isAnswered, color: AppTheme.textTertiary)

        if intention.isAnswered, let date = intention.answeredAt {
          Text(
            "\(String(localized: "intentions.answered.label")) · \(date.formatted(.dateTime.day().month()))"
          )
          .font(.caption2)
          .foregroundStyle(AppTheme.supplicationGreen)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
    .contextMenu {
      Button(role: .destructive) {
        modelContext.delete(intention)
      } label: {
        Label("common.delete", systemImage: "trash")
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: intention.isAnswered)
  }

  // MARK: - Empty state

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "hands.and.sparkles.fill")
        .font(.system(size: 32))
        .foregroundStyle(AppTheme.adorationPurple.opacity(0.7))
        .accessibilityHidden(true)
      Text("intentions.empty.title")
        .font(.system(.title3, design: .serif, weight: .semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("intentions.empty.subtitle")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 48)
    .padding(.horizontal, 16)
  }

  // MARK: - Actions

  private func add() {
    let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    modelContext.insert(PrayerIntention(text: trimmed))
    newText = ""
    isInputFocused = false
  }

  private func toggle(_ intention: PrayerIntention) {
    intention.isAnswered.toggle()
    intention.answeredAt = intention.isAnswered ? .now : nil
  }
}

#Preview {
  IntentionsView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
    .preferredColorScheme(.dark)
}
