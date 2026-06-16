//
//  ContentView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftData
import SwiftUI
import TipKit

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

  // Parcours de découverte (TipKit) : étape par étape, chaque tip fermé déclenche le suivant.
  private let emotionsTip = EmotionsTip()
  private let prayTip = PrayTip()
  private let intentionsTip = IntentionsTip()
  @State private var emotionsTipPresented = false
  @State private var prayTipPresented = false
  @State private var intentionsTipPresented = false

  // Hauteur réservée à la zone du verset : dimensionnée pour les versets courts (la majorité), afin
  // qu'apparition et révélation mot à mot ne déplacent jamais les éléments voisins.
  private let verseSlotHeight: CGFloat = 168

  var body: some View {
    NavigationStack {
      ZStack {
        composerLayer
      }
      .background { AppBackground() }
      // Sélection d'une émotion : retour haptique léger (API SwiftUI moderne, cohérente avec le
      // reste de l'app, plutôt qu'un UISelectionFeedbackGenerator impératif).
      .sensoryFeedback(.selection, trigger: selectedEmotion)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) { brandingTitle }
        ToolbarItem(placement: .topBarTrailing) {
          intentionsButton
            .popoverTip(intentionsTip, isPresented: $intentionsTipPresented)
            .onChange(of: intentionsTipPresented) { wasShown, isShown in
              if wasShown, !isShown { Task { await TourEvents.intentionsDone.donate() } }
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
            .popoverTip(emotionsTip, isPresented: $emotionsTipPresented, arrowEdges: .top)
            .onChange(of: emotionsTipPresented) { wasShown, isShown in
              if wasShown, !isShown { Task { await TourEvents.emotionsDone.donate() } }
            }

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
        .popoverTip(prayTip, isPresented: $prayTipPresented, arrowEdges: .bottom)
        .onChange(of: prayTipPresented) { wasShown, isShown in
          if wasShown, !isShown { Task { await TourEvents.prayDone.donate() } }
        }
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
        .padding(.vertical, 6)
    }
    // Style natif iOS 26 pour un bouton « menu » en Liquid Glass : `.menuStyle(.button)` fait rendre
    // le Menu comme un bouton, et `.buttonStyle(.glass)` applique le morph de verre interactif géré
    // par le système. Indispensable car le style de Menu par défaut peint sa propre teinte d'état
    // pressé PAR-DESSUS un `.glassEffect` manuel — le bouton « tintait » au tap comme à l'appui long.
    .menuStyle(.button)
    .buttonStyle(.glass)
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
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
      selectedEmotion = emotion
      emotionVerse = VerseService.shared.verse(for: emotion)
    }
    if let emotionVerse {
      WidgetSyncService.updateLastVerse(emotionVerse, emotion: emotion)
    }
    // L'utilisateur a découvert le geste : on retire le tip Émotions (le suivant s'enchaîne).
    emotionsTip.invalidate(reason: .actionPerformed)
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
    // Repli immédiat (1re ligne) pour que le journal ne montre jamais « Prière libre » nu et que la
    // feuille se ferme sans attendre le modèle.
    entry.customTitle = PrayerEntry.fallbackTitle(from: trimmed)
    entry.titleSource = .fallback
    modelContext.insert(entry)
    StreakService.shared.recordPrayer()
    WidgetSyncService.sync(context: modelContext)
    resetSelection()

    // Enrichissement asynchrone : le titre suggéré par le modèle on-device remplace le repli quand il
    // arrive. On n'écrase jamais un titre déjà édité par l'utilisateur. Textes très courts ignorés.
    if trimmed.count >= 15 {
      Task { @MainActor in
        if let aiTitle = await AIAssistantService.shared.generateTitle(for: trimmed),
          entry.titleSource != .user
        {
          entry.customTitle = aiTitle
          entry.titleSource = .ai
        }
      }
    }
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
