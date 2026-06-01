//
//  ContentView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var streak = StreakService.shared

  @State private var selectedEmotion: Emotion?
  @State private var emotionVerse: Verse?
  @State private var prayerText = ""
  @FocusState private var isComposerFocused: Bool

  @State private var showStructuredPrayer = false
  @State private var showIntentions = false

  @AppStorage("holyday.userName") private var userName = ""

  private let verseAnchorID = "verse"

  private var canSave: Bool {
    !prayerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      ZStack {
        composerLayer
      }
      .contentShape(Rectangle())
      .onTapGesture { isComposerFocused = false }
      .background { AppBackground() }
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) { brandingTitle }
        ToolbarItem(placement: .topBarTrailing) { intentionsButton }
        ToolbarItem(placement: .topBarTrailing) { structuredPrayerButton }
      }
    }
    .fullScreenCover(isPresented: $showStructuredPrayer) {
      StructuredPrayerSheet()
    }
    .sheet(isPresented: $showIntentions) {
      IntentionsView()
    }
  }

  // MARK: - Composer layer

  private var composerLayer: some View {
    // ScrollView + minHeight = hauteur du viewport : le contenu reste centré au repos, et devient
    // défilable quand le clavier réduit l'espace. On défile alors vers le verset pour qu'il reste
    // entièrement visible au-dessus du champ de saisie.
    GeometryReader { geo in
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 28) {
            Spacer(minLength: 0)

            Text(feelingQuestion)
              .font(.system(.title2, design: .serif).weight(.semibold))
              .foregroundStyle(AppTheme.textPrimary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)

            EmotionRibbonView { select($0) }

            if let emotionVerse {
              EmotionVerseView(
                verse: emotionVerse,
                accent: selectedEmotion?.color ?? AppTheme.adorationPurple
              )
              .id(verseAnchorID)
              .transition(.opacity)
            }

            composer

            Spacer(minLength: 0)
            Spacer(minLength: 0)
          }
          .frame(minHeight: geo.size.height)
          .animation(.spring(response: 0.45, dampingFraction: 0.85), value: emotionVerse?.id)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: isComposerFocused) { _, focused in
          guard focused, emotionVerse != nil else { return }
          withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(verseAnchorID, anchor: .top)
          }
        }
      }
    }
  }

  private var composer: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("prayer.free.placeholder", text: $prayerText, axis: .vertical)
        .font(.body)
        .foregroundStyle(AppTheme.textPrimary)
        .focused($isComposerFocused)
        .lineLimit(1...6)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(
          .regular.interactive(),
          in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )

      Button {
        save()
      } label: {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: 34))
          .foregroundStyle(canSave ? AppTheme.adorationPurple : AppTheme.textTertiary.opacity(0.4))
          .frame(width: 44, height: 44)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(!canSave)
      .animation(.easeInOut(duration: 0.2), value: canSave)
      .accessibilityLabel(String(localized: "prayer.free.amen"))
    }
    .padding(.horizontal, 20)
  }

  // MARK: - Toolbar

  private var brandingTitle: some View {
    HStack(spacing: 0) {
      Text("Holy")
        .font(.system(.title, design: .serif, weight: .bold).italic())
        .foregroundStyle(AppTheme.textPrimary)
      Text("Day")
        .font(.system(.title, design: .serif, weight: .thin))
        .foregroundStyle(AppTheme.textPrimary)
    }
    #if DEBUG
      .onTapGesture(count: 3) {
        streak.resetTodaysPrayer()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
      }
    #endif
  }

  // Filet discret pour qui ne sait pas quoi dire : lance la prière structurée.
  private var structuredPrayerButton: some View {
    Button {
      showStructuredPrayer = true
    } label: {
      Image(systemName: "hands.sparkles")
        .font(.body.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
    }
    .accessibilityLabel(String(localized: "home.guided.cta"))
  }

  private var intentionsButton: some View {
    Button {
      showIntentions = true
    } label: {
      Image(systemName: "heart.text.square")
        .font(.body.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
    }
    .accessibilityLabel(String(localized: "intentions.nav.title"))
  }

  // MARK: - Actions

  private func select(_ emotion: Emotion) {
    UISelectionFeedbackGenerator().selectionChanged()
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
      selectedEmotion = emotion
      emotionVerse = VerseService.shared.verse(for: emotion)
    }
  }

  private func save() {
    let trimmed = prayerText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    isComposerFocused = false

    let entry = PrayerEntry(
      stepTitle: String(localized: "prayer.free.title"),
      stepIcon: "square.and.pencil",
      stepColorName: "adorationPurple",
      text: trimmed,
      emotion: selectedEmotion,
      verseReference: emotionVerse?.reference
    )
    modelContext.insert(entry)
    StreakService.shared.recordPrayer()
    resetComposer()
  }

  private func resetComposer() {
    withAnimation(.easeInOut(duration: 0.3)) {
      prayerText = ""
      selectedEmotion = nil
      emotionVerse = nil
    }
  }

  // MARK: - Helpers

  private var feelingQuestion: String {
    if userName.isEmpty {
      return String(localized: "home.feeling.question")
    }
    return String(format: String(localized: "home.feeling.question.named"), userName)
  }
}

#Preview {
  ContentView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
    .preferredColorScheme(.dark)
}
