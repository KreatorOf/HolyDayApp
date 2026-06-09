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
  @State private var addedHaptic = 0
  @State private var removedHaptic = 0
  @State private var restoredHaptic = 0
  // Intention dont la fiche détail est présentée (appui simple sur une ligne).
  @State private var detailTarget: PrayerIntention?
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
      }
      .sensoryFeedback(.success, trigger: answeredHaptic)
      .sensoryFeedback(.selection, trigger: segment)
      .sensoryFeedback(.selection, trigger: restoredHaptic)
      .sensoryFeedback(.impact(weight: .light), trigger: addedHaptic)
      .sensoryFeedback(.impact(weight: .medium), trigger: removedHaptic)
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
      .sheet(item: $detailTarget) { intention in
        IntentionDetailView(intention: intention)
      }
    }
  }

  // MARK: - Segmented control

  private var segmentedControl: some View {
    GlassEffectContainer(spacing: 20) {
      HStack(spacing: 20) {
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
          .font(.body)
          .foregroundStyle(answered ? AppTheme.textSecondary : AppTheme.textPrimary)
          .strikethrough(answered, color: AppTheme.textTertiary)

        Text(subtitle(for: intention))
          .font(.caption)
          .foregroundStyle(answered ? AppTheme.supplicationGreen : AppTheme.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 18)
      .padding(.vertical, 16)
      .background {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(AppTheme.cardSurface)
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
            ? "intentions.section.answered" : "intentions.section.active")
      )
    }
    .contentShape(.rect)
    .onTapGesture { detailTarget = intention }
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    // Toutes les actions (exaucer, modifier, supprimer…) passent par la fiche détail ouverte au tap.
    // Exposées aussi en actions d'accessibilité pour VoiceOver.
    .accessibilityActions { intentionMenu(for: intention) }
  }

  // MARK: - Menu contextuel (appui long)

  @ViewBuilder
  private func intentionMenu(for intention: PrayerIntention) -> some View {
    if intention.isAnswered {
      Button {
        toggle(intention)
      } label: {
        Label("intentions.action.restore", systemImage: "arrow.uturn.backward")
      }
    } else {
      Button {
        answer(intention)
      } label: {
        Label("intentions.action.glory", systemImage: "hands.sparkles.fill")
      }
    }

    Button {
      startEdit(intention)
    } label: {
      Label("intentions.action.edit", systemImage: "pencil")
    }

    Button(role: .destructive) {
      delete(intention)
    } label: {
      Label("common.delete", systemImage: "trash")
    }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)

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
    addedHaptic += 1
  }

  private func delete(_ intention: PrayerIntention) {
    removedHaptic += 1
    modelContext.delete(intention)
  }

  private func toggle(_ intention: PrayerIntention) {
    if intention.isAnswered {
      // Annulation : retour direct dans les actives, sans effet.
      intention.isAnswered = false
      intention.answeredAt = nil
      restoredHaptic += 1
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
