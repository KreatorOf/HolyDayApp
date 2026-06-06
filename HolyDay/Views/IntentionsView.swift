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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Query(sort: \PrayerIntention.createdAt, order: .reverse) private var intentions:
    [PrayerIntention]
  @State private var segment: Segment = .active
  @State private var newText = ""
  @State private var editingIntention: PrayerIntention?
  @State private var editText = ""
  // Ligne en cours de glissement « exaucée » avant que la bascule ne la retire des actives.
  @State private var departingID: PersistentIdentifier?
  // Phase suivante : le 🙏, resté en place ~1 s, glisse à son tour vers la droite.
  @State private var handsLeavingID: PersistentIdentifier?
  @State private var answeredHaptic = 0
  // Intention ciblée par l'appui long → affiche la boîte de décision centrée.
  @State private var actionTarget: PrayerIntention?
  @State private var pressHaptic = 0
  @FocusState private var isFocused: Bool

  private enum Segment { case active, answered }

  // Distance suffisante pour sortir la ligne par la droite quelle que soit la largeur du sheet.
  private let departOffset: CGFloat = 900

  private var active: [PrayerIntention] { intentions.filter { !$0.isAnswered } }
  private var answered: [PrayerIntention] { intentions.filter(\.isAnswered) }
  private var shown: [PrayerIntention] { segment == .active ? active : answered }

  var body: some View {
    NavigationStack {
      ZStack {
        AppBackground()
        VStack(spacing: 0) {
          segmentedControl
          content
          if segment == .active { inputBar }
        }

        if let target = actionTarget {
          decisionOverlay(for: target)
        }
      }
      .sensoryFeedback(.success, trigger: answeredHaptic)
      .sensoryFeedback(.impact, trigger: pressHaptic)
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

  // MARK: - Segmented control

  private var segmentedControl: some View {
    GlassEffectContainer(spacing: 12) {
      HStack(spacing: 12) {
        segmentButton(.active, label: "intentions.segment.active", count: active.count)
        segmentButton(.answered, label: "intentions.section.answered", count: answered.count)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  private func segmentButton(_ seg: Segment, label: LocalizedStringKey, count: Int) -> some View {
    let selected = segment == seg
    return Button {
      withAnimation(.smooth(duration: 0.3)) { segment = seg }
    } label: {
      HStack(spacing: 6) {
        Text(label)
          .font(.subheadline.weight(.semibold))
        Text("\(count)")
          .font(.caption.weight(.semibold))
          .opacity(0.6)
      }
      .foregroundStyle(selected ? AppTheme.textPrimary : AppTheme.textSecondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 10)
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .glassEffect(
      selected
        ? .regular.tint(AppTheme.adorationPurple.opacity(0.35)).interactive()
        : .regular.interactive(),
      in: .capsule
    )
  }

  // MARK: - Content

  @ViewBuilder
  private var content: some View {
    if shown.isEmpty {
      emptyState
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List {
        ForEach(shown) { intentionRow($0) }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
    }
  }

  @ViewBuilder
  private var emptyState: some View {
    switch segment {
    case .active:
      ContentUnavailableView {
        Label("intentions.empty.title", systemImage: "heart.text.square.fill")
      } description: {
        Text("intentions.empty.subtitle")
      }
    case .answered:
      ContentUnavailableView {
        Label("intentions.empty.answered.title", systemImage: "checkmark.seal")
      } description: {
        Text("intentions.empty.answered.subtitle")
      }
    }
  }

  private func intentionRow(_ intention: PrayerIntention) -> some View {
    let isDeparting = departingID == intention.persistentModelID
    let handsLeaving = handsLeavingID == intention.persistentModelID
    // On affiche l'état « exaucé » dès le tap (sceau plein, barré) pendant que la ligne s'en va.
    let answered = intention.isAnswered || isDeparting
    return ZStack {
      // Mains jointes : éclosent en place quand la ligne part, tiennent ~1 s, puis sortent à droite.
      Text(verbatim: "🙏")
        .font(.system(size: 34))
        .scaleEffect(isDeparting ? 1 : 0.2)
        .opacity(isDeparting ? 1 : 0)
        .offset(x: handsLeaving && !reduceMotion ? departOffset : 0)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(intention.text)
          .font(.subheadline)
          .foregroundStyle(answered ? AppTheme.textSecondary : AppTheme.textPrimary)
          .strikethrough(answered, color: AppTheme.textTertiary)

        Text(subtitle(for: intention))
          .font(.caption2)
          .foregroundStyle(answered ? AppTheme.supplicationGreen : AppTheme.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 18)
      .padding(.vertical, 16)
      .background {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
          }
      }
      .offset(x: isDeparting && !reduceMotion ? departOffset : 0)
      .opacity(isDeparting ? 0 : 1)
      .accessibilityElement(children: .combine)
      .accessibilityValue(
        String(
          localized: intention.isAnswered
            ? "intentions.section.answered" : "intentions.section.active"))
    }
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    .onLongPressGesture {
      pressHaptic += 1
      withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { actionTarget = intention }
    }
  }

  // MARK: - Boîte de décision (appui long)

  @ViewBuilder
  private func decisionOverlay(for intention: PrayerIntention) -> some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { closeDecision() }

      VStack(spacing: 0) {
        Text(intention.text)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.textPrimary)
          .multilineTextAlignment(.center)
          .lineLimit(3)
          .padding(.horizontal, 20)
          .padding(.vertical, 16)

        Divider().overlay(AppTheme.cardStroke)

        if intention.isAnswered {
          decisionButton(
            "intentions.action.restore", icon: "arrow.uturn.backward",
            tint: AppTheme.adorationPurple
          ) { toggle(intention) }
        } else {
          decisionButton(
            "intentions.action.glory", icon: "hands.sparkles.fill",
            tint: AppTheme.supplicationGreen
          ) { answer(intention) }
        }

        Divider().overlay(AppTheme.cardStroke)
        decisionButton("intentions.action.edit", icon: "pencil", tint: AppTheme.textPrimary) {
          startEdit(intention)
        }

        Divider().overlay(AppTheme.cardStroke)
        decisionButton("common.delete", icon: "trash", tint: .red, role: .destructive) {
          modelContext.delete(intention)
        }
      }
      .frame(maxWidth: 300)
      .background {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.regularMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
          }
      }
      .padding(40)
    }
    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.92)))
    .zIndex(1)
  }

  private func decisionButton(
    _ titleKey: LocalizedStringKey, icon: String, tint: Color, role: ButtonRole? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(role: role) {
      closeDecision()
      action()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .frame(width: 24)
        Text(titleKey)
        Spacer(minLength: 0)
      }
      .font(.subheadline.weight(.medium))
      .foregroundStyle(tint)
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func closeDecision() {
    withAnimation(.easeOut(duration: 0.2)) { actionTarget = nil }
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

  // MARK: - Helpers

  private func subtitle(for intention: PrayerIntention) -> String {
    if intention.isAnswered, let date = intention.answeredAt {
      return
        "\(String(localized: "intentions.answered.label")) · \(date.formatted(.dateTime.day().month()))"
    }
    return durationText(since: intention.createdAt)
  }

  private func durationText(since date: Date) -> String {
    let calendar = Calendar.current
    let days =
      calendar.dateComponents(
        [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: .now)
      ).day ?? 0
    if days <= 0 { return String(localized: "intentions.duration.today") }
    if days == 1 { return String(localized: "intentions.duration.yesterday") }
    return String(format: String(localized: "intentions.duration.days"), days)
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
    if intention.isAnswered {
      // Annulation : retour direct dans les actives, sans effet.
      intention.isAnswered = false
      intention.answeredAt = nil
    } else {
      answer(intention)
    }
  }

  // Fait glisser la ligne hors de l'écran, puis bascule l'intention en exaucée une fois hors champ,
  // pour que la sortie soit visible avant que `@Query` ne la retire de la liste des actives.
  private func answer(_ intention: PrayerIntention) {
    let id = intention.persistentModelID
    answeredHaptic += 1
    // Phase A : la ligne glisse à droite, les mains jointes éclosent à sa place.
    withAnimation(.easeIn(duration: 0.4)) { departingID = id }

    Task {
      // On laisse les mains jointes bien visibles ~1 s avant de les faire sortir.
      try? await Task.sleep(for: .seconds(1))
      // Phase B : les mains jointes suivent vers la droite.
      withAnimation(.easeIn(duration: 0.4)) { handsLeavingID = id }
      try? await Task.sleep(for: .milliseconds(400))
      // Une fois hors champ, on bascule réellement l'intention en exaucée.
      withAnimation(.easeOut(duration: 0.2)) {
        intention.isAnswered = true
        intention.answeredAt = .now
      }
      departingID = nil
      handsLeavingID = nil
    }
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
