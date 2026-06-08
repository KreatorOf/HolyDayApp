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

  @State private var showFreePrayer = false
  @State private var showStructuredPrayer = false
  @State private var showIntentions = false

  @State private var showSupportPrompt = false
  @State private var showPaywallFromPrompt = false
  @State private var openPaywallAfterPrompt = false
  // Jeton de streak avant l'ouverture de la prière structurée : permet de savoir, à sa fermeture,
  // si une nouvelle prière a réellement été enregistrée pendant la session.
  @State private var streakTokenBeforeStructured: UUID?
  // Pendant équivalent pour la prière libre (présentée en feuille depuis le menu « Prier »).
  @State private var streakTokenBeforeFree: UUID?

  @AppStorage("holyday.userName") private var userName = ""
  // Tour guidé post-onboarding, joué une seule fois. `tourStep` = étape courante (nil = inactif).
  @AppStorage("holyday.hasSeenTour") private var hasSeenTour = false
  @State private var tourStep: Int?

  // Hauteur réservée à la zone du verset : dimensionnée pour les versets courts (la majorité), afin
  // qu'apparition et révélation mot à mot ne déplacent jamais les éléments voisins.
  private let verseSlotHeight: CGFloat = 168

  var body: some View {
    NavigationStack {
      ZStack {
        composerLayer
      }
      .background { AppBackground() }
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) { brandingTitle }
        ToolbarItem(placement: .topBarTrailing) {
          intentionsButton.tourAnchor(.intentions)
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
      StructuredPrayerSheet(
        verse: emotionVerse,
        accent: selectedEmotion?.color ?? AppTheme.adorationPurple
      )
    }
    .sheet(
      isPresented: $showFreePrayer,
      onDismiss: {
        // Même logique que la prière structurée : une nouvelle prière a-t-elle été enregistrée ?
        if streak.lastIncrementToken != streakTokenBeforeFree {
          presentSupportPromptIfEligible()
        }
      }
    ) {
      FreePrayerSheet(
        verse: emotionVerse,
        accent: selectedEmotion?.color ?? AppTheme.adorationPurple,
        onSave: saveFreePrayer
      )
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
    // ScrollView + minHeight = hauteur du viewport : le contenu reste centré au repos et reste
    // accessible sur petits écrans ou en grandes tailles Dynamic Type. Le bouton « Prier » est
    // ancré en bas (safeAreaInset) : il ne se déplace pas quand le verset apparaît au-dessus.
    GeometryReader { geo in
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

          // Emplacement réservé : hauteur fixe et verset ancré en haut, pour que la révélation mot
          // à mot s'écrive « vers le bas » sans décaler le ruban au-dessus ni le reste en dessous.
          ZStack(alignment: .top) {
            if let emotionVerse {
              EmotionVerseView(
                verse: emotionVerse,
                accent: selectedEmotion?.color ?? AppTheme.adorationPurple
              )
              .transition(.opacity)
            }
          }
          .frame(maxWidth: .infinity, minHeight: verseSlotHeight, alignment: .top)

          Spacer(minLength: 0)
        }
        .frame(minHeight: geo.size.height)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: emotionVerse?.id)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom) {
      prayButton
        .tourAnchor(.pray)
        .padding(.bottom, 28)
    }
  }

  // CTA principal : ouvre un menu natif (HIG) proposant la prière libre ou la prière guidée.
  // Toujours visible — les deux modes restent accessibles même sans émotion sélectionnée.
  private var prayButton: some View {
    Menu {
      Button {
        streakTokenBeforeFree = streak.lastIncrementToken
        showFreePrayer = true
      } label: {
        Label("prayer.free.title", systemImage: "square.and.pencil")
      }
      Button {
        streakTokenBeforeStructured = streak.lastIncrementToken
        showStructuredPrayer = true
      } label: {
        Label("prayer.guided.title", systemImage: "hands.sparkles")
      }
    } label: {
      Label("home.pray.cta", systemImage: "hands.sparkles")
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 26)
        .padding(.vertical, 14)
    }
    .glassEffect(.regular.interactive(), in: .capsule)
    .accessibilityLabel(String(localized: "home.pray.cta"))
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

  private var intentionsButton: some View {
    Button {
      showIntentions = true
    } label: {
      Image(systemName: "list.bullet")
        .foregroundStyle(AppTheme.textPrimary)
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
    case .intentions: return CGRect(x: proxy.size.width - 50, y: 2, width: 40, height: 40)
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

  // Enregistre la prière libre saisie dans `FreePrayerSheet`. La sollicitation de don éventuelle est
  // déclenchée à la fermeture de la feuille (cf. `onDismiss`), pour ne pas empiler deux feuilles.
  private func saveFreePrayer(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

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
    resetSelection()
  }

  // Présente la sollicitation de don si l'état le permet, et démarre alors son délai de repos.
  private func presentSupportPromptIfEligible() {
    guard SupportPromptService.shared.shouldPrompt else { return }
    SupportPromptService.shared.markShown()
    showSupportPrompt = true
  }

  private func resetSelection() {
    withAnimation(.easeInOut(duration: 0.3)) {
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
