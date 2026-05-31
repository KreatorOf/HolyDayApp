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
  @State private var editingIntention: PrayerIntention?
  @State private var editText = ""
  @FocusState private var isFocused: Bool

  private var active: [PrayerIntention] { intentions.filter { !$0.isAnswered } }
  private var answered: [PrayerIntention] { intentions.filter(\.isAnswered) }

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        VStack(spacing: 0) {
          intentionList
          inputBar
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("intentions.nav.title")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
      .alert("intentions.edit.title", isPresented: editAlertBinding) {
        TextField("intentions.add.placeholder", text: $editText)
        Button("intentions.edit.save") { commitEdit() }
        Button("common.cancel", role: .cancel) {}
      }
    }
  }

  // MARK: - List

  @ViewBuilder
  private var intentionList: some View {
    if intentions.isEmpty {
      emptyState
    } else {
      List {
        if !active.isEmpty {
          Section {
            ForEach(active) { intentionRow($0) }
          } header: {
            sectionHeader(String(localized: "intentions.section.active"))
          }
        }
        if !answered.isEmpty {
          Section {
            ForEach(answered) { intentionRow($0) }
          } header: {
            sectionHeader(String(localized: "intentions.section.answered"))
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
    }
  }

  private func intentionRow(_ intention: PrayerIntention) -> some View {
    HStack(spacing: 12) {
      Button {
        toggle(intention)
      } label: {
        Image(systemName: intention.isAnswered ? "checkmark.seal.fill" : "circle")
          .font(.title3)
          .foregroundStyle(
            intention.isAnswered ? AppTheme.supplicationGreen : AppTheme.textTertiary
          )
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

      VStack(alignment: .leading, spacing: 2) {
        Text(intention.text)
          .font(.subheadline)
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
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button(role: .destructive) {
        modelContext.delete(intention)
      } label: {
        Label("common.delete", systemImage: "trash")
      }
      Button {
        startEdit(intention)
      } label: {
        Label("intentions.action.edit", systemImage: "pencil")
      }
      .tint(AppTheme.adorationPurple)
    }
  }

  private func sectionHeader(_ text: String) -> some View {
    Text(text)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(1.0)
      .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 6, trailing: 20))
  }

  // MARK: - Empty state

  private var emptyState: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: "hands.and.sparkles.fill")
        .font(.system(size: 32))
        .foregroundStyle(AppTheme.adorationPurple.opacity(0.7))
        .accessibilityHidden(true)
      Text("intentions.empty.title")
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
      Text("intentions.empty.subtitle")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
  }

  // MARK: - Input

  private var inputBar: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("intentions.add.placeholder", text: $newText, axis: .vertical)
        .font(.body)
        .foregroundStyle(AppTheme.textPrimary)
        .focused($isFocused)
        .lineLimit(1...5)
        .submitLabel(.send)
        .onSubmit(add)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
          Capsule()
            .fill(.ultraThinMaterial)
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke, lineWidth: 1) }
        }

      Button {
        add()
      } label: {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: 30))
          .foregroundStyle(canSend ? AppTheme.adorationPurple : AppTheme.textTertiary.opacity(0.4))
          .frame(width: 44, height: 44)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(!canSend)
      .accessibilityLabel(String(localized: "intentions.suggest.add"))
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
  }

  private var canSend: Bool {
    !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Actions

  private var editAlertBinding: Binding<Bool> {
    Binding(
      get: { editingIntention != nil },
      set: { if !$0 { editingIntention = nil } }
    )
  }

  private func add() {
    let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    modelContext.insert(PrayerIntention(text: trimmed))
    newText = ""
  }

  private func toggle(_ intention: PrayerIntention) {
    intention.isAnswered.toggle()
    intention.answeredAt = intention.isAnswered ? .now : nil
  }

  private func startEdit(_ intention: PrayerIntention) {
    editText = intention.text
    editingIntention = intention
  }

  private func commitEdit() {
    let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
    if let intention = editingIntention, !trimmed.isEmpty {
      intention.text = trimmed
    }
    editingIntention = nil
  }
}

#Preview {
  IntentionsView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
    .preferredColorScheme(.dark)
}
