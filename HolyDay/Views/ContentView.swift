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

  @State private var showSupportPrompt = false
  @State private var showPaywallFromPrompt = false
  @State private var openPaywallAfterPrompt = false
  // Jeton de streak avant l'ouverture de la prière structurée : permet de savoir, à sa fermeture,
  // si une nouvelle prière a réellement été enregistrée pendant la session.
  @State private var streakTokenBeforeStructured: UUID?

  @AppStorage("holyday.userName") private var userName = ""
  // Tour guidé post-onboarding, joué une seule fois. `tourStep` = étape courante (nil = inactif).
  @AppStorage("holyday.hasSeenTour") private var hasSeenTour = false
  @State private var tourStep: Int?

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
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 4) {
            intentionsButton.tourAnchor(.intentions)
            structuredPrayerButton.tourAnchor(.guidedPrayer)
          }
        }
      }
    }
    .fullScreenCover(
      isPresented: $showStructuredPrayer,
      onDismiss: {
        // Une prière structurée a-t-elle été enregistrée pendant la session ?
        if streak.lastIncrementToken != streakTokenBeforeStructured {
          presentSupportPromptIfEligible()
        }
      }
    ) {
      StructuredPrayerSheet()
    }
    .sheet(isPresented: $showIntentions) {
      IntentionsView()
    }
    .sheet(
      isPresented: $showSupportPrompt,
      onDismiss: {
        // Enchaîne sur le paywall seulement après la fermeture complète de la feuille.
        if openPaywallAfterPrompt {
          openPaywallAfterPrompt = false
          showPaywallFromPrompt = true
        }
      }
    ) {
      SupportPromptView(
        onSupport: {
          openPaywallAfterPrompt = true
          showSupportPrompt = false
        },
        onLater: { showSupportPrompt = false },
        onDontAskAgain: {
          SupportPromptService.shared.dontAskAgain()
          showSupportPrompt = false
        }
      )
    }
    .sheet(isPresented: $showPaywallFromPrompt) {
      HolyDayPaywallView()
    }
    .overlayPreferenceValue(TourAnchorKey.self) { anchors in
      GeometryReader { proxy in
        tourOverlay(anchors: anchors, proxy: proxy)
      }
    }
    .onAppear {
      // Tour guidé joué une seule fois, après l'onboarding. Déclenchement synchrone (un .task
      // asynchrone pouvait être annulé pendant le lancement et ne jamais démarrer le tour).
      if !hasSeenTour, tourStep == nil { tourStep = 0 }
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
              .tourAnchor(.emotions)

            if let emotionVerse {
              EmotionVerseView(
                verse: emotionVerse,
                accent: selectedEmotion?.color ?? AppTheme.adorationPurple
              )
              .id(verseAnchorID)
              .transition(.opacity)
            }

            composer
              .tourAnchor(.composer)

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
  }

  // Filet discret pour qui ne sait pas quoi dire : lance la prière structurée.
  private var structuredPrayerButton: some View {
    Button {
      streakTokenBeforeStructured = streak.lastIncrementToken
      showStructuredPrayer = true
    } label: {
      Image(systemName: "hands.sparkles")
        .foregroundStyle(AppTheme.textSecondary)
        .padding(8)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(String(localized: "home.guided.cta"))
  }

  private var intentionsButton: some View {
    Button {
      showIntentions = true
    } label: {
      Image(systemName: "heart.text.square")
        .foregroundStyle(AppTheme.textSecondary)
        .padding(8)
        .contentShape(Rectangle())
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

  // MARK: - Tour guidé

  @ViewBuilder
  private func tourOverlay(anchors: [Int: Anchor<CGRect>], proxy: GeometryProxy) -> some View {
    if let raw = tourStep, let step = TourStep(rawValue: raw) {
      TourOverlayView(
        step: step,
        targetRect: tourRect(step: step, raw: raw, anchors: anchors, proxy: proxy),
        screen: proxy.size,
        index: raw,
        total: TourStep.allCases.count,
        onNext: advanceTour,
        onSkip: endTour
      )
    }
  }

  private func tourRect(
    step: TourStep, raw: Int, anchors: [Int: Anchor<CGRect>], proxy: GeometryProxy
  ) -> CGRect? {
    if let anchor = anchors[raw] { return proxy[anchor] }
    // Repli si l'ancre d'un bouton de la barre de navigation n'est pas propagée : coin haut-droit.
    switch step {
    case .intentions: return CGRect(x: proxy.size.width - 96, y: 2, width: 40, height: 40)
    case .guidedPrayer: return CGRect(x: proxy.size.width - 50, y: 2, width: 40, height: 40)
    default: return nil
    }
  }

  private func advanceTour() {
    guard let raw = tourStep else { return }
    if raw + 1 < TourStep.allCases.count {
      withAnimation(.easeInOut(duration: 0.25)) { tourStep = raw + 1 }
    } else {
      endTour()
    }
  }

  private func endTour() {
    withAnimation(.easeInOut(duration: 0.3)) { tourStep = nil }
    hasSeenTour = true
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
    let didRecordNewDay = StreakService.shared.recordPrayer()
    resetComposer()
    if didRecordNewDay {
      presentSupportPromptIfEligible()
    }
  }

  // Présente la sollicitation de don si l'état le permet, et démarre alors son délai de repos.
  private func presentSupportPromptIfEligible() {
    guard SupportPromptService.shared.shouldPrompt else { return }
    SupportPromptService.shared.markShown()
    showSupportPrompt = true
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
