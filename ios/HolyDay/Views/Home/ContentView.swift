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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Query(
    filter: #Predicate<PrayerIntention> { !$0.isAnswered },
    sort: \PrayerIntention.createdAt,
    order: .reverse
  )
  private var activeIntentions: [PrayerIntention]
  @State private var prayerRecord = PrayerRecordService.shared

  @State private var selectedEmotion: Emotion?
  @State private var emotionVerse: Verse?

  @State private var showFreePrayer = false
  @State private var showStructuredPrayer = false
  @State private var showIntentions = false
  @State private var showPrayerChoices = false
  @State private var prayerTriggerFrame = CGRect.zero
  @State private var prayerChoicesFrame = CGRect.zero

  @State private var showSupportPrompt = false
  @State private var showPaywallFromPrompt = false
  @State private var openPaywallAfterPrompt = false
  // Jeton d'enregistrement avant l'ouverture de la prière structurée : permet de savoir, à sa
  // fermeture, si une nouvelle prière a réellement été enregistrée pendant la session.
  @State private var recordTokenBeforeStructured: UUID?
  // Pendant équivalent pour la prière libre (présentée en feuille depuis le menu « Prier »).
  @State private var recordTokenBeforeFree: UUID?

  @AppStorage("holyday.userName") private var userName = ""
  @State private var router = AppRouter.shared

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
  // Colonne de lecture commune au titre, au ruban, au verset et au CTA. Elle évite que le CTA se
  // centre dans toute la surface lorsque Duo réserve une région système latérale.
  private let compactContentMaxWidth: CGFloat = 560
  private let prayerCoordinateSpace = "home.prayer"

  var body: some View {
    NavigationStack {
      ZStack {
        composerLayer
      }
      .background { AppBackground() }
      // Sélection d'une émotion : retour haptique léger (API SwiftUI moderne, cohérente avec le
      // reste de l'app, plutôt qu'un UISelectionFeedbackGenerator impératif).
      .sensoryFeedback(.selection, trigger: selectedEmotion)
      .appNavigationBarBackground()
      .toolbar {
        ToolbarItem(placement: .principal) { brandingTitle }
        ToolbarItem(placement: .topBarTrailing) {
          intentionsButton
            .appPopoverTip(intentionsTip, isPresented: $intentionsTipPresented)
            .onChange(of: intentionsTipPresented) { wasShown, isShown in
              if wasShown, !isShown { Task { await TourEvents.intentionsDone.donate() } }
            }
        }
      }
      // Capture d'écran : pré-sélectionne une émotion pour afficher le verset sans dépendre du
      // ruban animé. Sans effet hors run `fastlane snapshot`.
      .onAppear {
        if selectedEmotion == nil, let emotion = ScreenshotMode.preselectedEmotion {
          select(emotion)
        }
      }
    }
    .coordinateSpace(name: prayerCoordinateSpace)
    .simultaneousGesture(dismissPrayerChoicesGesture)
    .fullScreenCover(
      isPresented: $showStructuredPrayer,
      onDismiss: {
        // Une prière structurée a-t-elle été enregistrée pendant la session ?
        if prayerRecord.lastRecordToken != recordTokenBeforeStructured {
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
        if prayerRecord.lastRecordToken != recordTokenBeforeFree {
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
    // Routes venues d'une notification, d'un widget ou de la commande « Prier ». `initial: true` :
    // au lancement à froid, la route est posée avant que la vue n'existe.
    .onChange(of: router.pending, initial: true) { _, route in
      switch route {
      case .freePrayer:
        router.pending = nil
        recordTokenBeforeFree = prayerRecord.lastRecordToken
        showFreePrayer = true
      case .intentions:
        router.pending = nil
        showIntentions = true
      default:
        break
      }
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
    Group {
      if horizontalSizeClass == .regular, !dynamicTypeSize.isAccessibilitySize {
        duoComposerLayer
      } else {
        compactComposerLayer
      }
    }
  }

  // L'écran interne de l'iPhone Duo fournit un trait de taille régulier, même si sa largeur logique
  // est inférieure à celle d'un iPad. Le repli compact reste préférable avec Dynamic Type d'accès.
  private var duoComposerLayer: some View {
    DuoPrayerComposer(
      question: feelingQuestion,
      activeIntention: activeIntentions.first?.text,
      activeIntentionCount: activeIntentions.count,
      hasVerse: emotionVerse != nil,
      onShowIntentions: { showIntentions = true },
      emotionContent: { emotionRibbon },
      prayerContent: { duoPrayerButton },
      verseContent: { duoVerseContent }
    )
    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: emotionVerse?.id)
  }

  // ScrollView + minHeight = hauteur du viewport : le contenu reste centré au repos et reste
  // accessible sur petits écrans ou en grandes tailles Dynamic Type. Le bouton « Prier » est
  // ancré en bas (safeAreaInset) : il ne se déplace pas quand le verset apparaît au-dessus.
  private var compactComposerLayer: some View {
    GeometryReader { geo in
      ScrollView {
        VStack(spacing: 28) {
          Spacer(minLength: 0)

          Text(feelingQuestion)
            .font(.system(.title2, design: .serif).weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

          emotionRibbon

          verseSlot

          Spacer(minLength: 0)
        }
        .frame(minHeight: geo.size.height)
        .frame(maxWidth: compactContentMaxWidth)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: emotionVerse?.id)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom) {
      prayButton
        .frame(maxWidth: compactContentMaxWidth)
        .frame(maxWidth: .infinity)
        .appPopoverTip(prayTip, isPresented: $prayTipPresented, arrowEdge: .bottom)
        .onChange(of: prayTipPresented) { wasShown, isShown in
          if wasShown, !isShown { Task { await TourEvents.prayDone.donate() } }
        }
        .padding(.bottom, 28)
    }
  }

  private var duoPrayerButton: some View {
    prayButton
      .appPopoverTip(prayTip, isPresented: $prayTipPresented, arrowEdge: .bottom)
      .onChange(of: prayTipPresented) { wasShown, isShown in
        if wasShown, !isShown { Task { await TourEvents.prayDone.donate() } }
      }
  }

  // Les popovers système se repositionnent pour éviter les bords, ce qui les faisait dériver à
  // droite sur Duo. Ce sélecteur est rendu dans le repère du CTA : les options s'ouvrent toujours
  // juste au-dessus du bouton qui les déclenche.
  @ViewBuilder
  private var prayButton: some View {
    if #available(iOS 26.0, *) {
      prayerTrigger(label: prayButtonLabel(verticalPadding: 6))
        .buttonStyle(.glass)
    } else {
      prayerTrigger(label: prayButtonLabel(verticalPadding: 14))
        .appGlassEffect(in: .capsule)
    }
  }

  private func prayerTrigger(label: some View) -> some View {
    Button {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showPrayerChoices.toggle() }
    } label: {
      label
    }
    .accessibilityIdentifier("home.prayButton")
    .accessibilityLabel(String(localized: "home.pray.cta"))
    .onGeometryChange(for: CGRect.self) {
      $0.frame(in: .named(prayerCoordinateSpace))
    } action: {
      prayerTriggerFrame = $0
    }
    .opacity(showPrayerChoices ? 0 : 1)
    .accessibilityHidden(showPrayerChoices)
    .overlay(alignment: .bottom) {
      if showPrayerChoices {
        prayerChoices
          .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottom)))
          .zIndex(1)
      }
    }
  }

  private var prayerChoices: some View {
    VStack(spacing: 4) {
      prayerChoice(
        "prayer.free.title",
        systemImage: "square.and.pencil",
        mode: .free
      )
      Divider()
      prayerChoice(
        "prayer.guided.title",
        systemImage: "hands.sparkles",
        mode: .guided
      )
    }
    .padding(8)
    .frame(width: 240)
    .appGlassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .onGeometryChange(for: CGRect.self) {
      $0.frame(in: .named(prayerCoordinateSpace))
    } action: {
      prayerChoicesFrame = $0
    }
  }

  private var dismissPrayerChoicesGesture: some Gesture {
    SpatialTapGesture(coordinateSpace: .named(prayerCoordinateSpace))
      .onEnded { event in
        guard showPrayerChoices,
          !prayerTriggerFrame.contains(event.location),
          !prayerChoicesFrame.contains(event.location)
        else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          showPrayerChoices = false
        }
      }
  }

  private func prayerChoice(
    _ titleKey: LocalizedStringKey,
    systemImage: String,
    mode: DuoPrayerMode
  ) -> some View {
    Button {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showPrayerChoices = false }
      present(mode)
    } label: {
      Label(titleKey, systemImage: systemImage)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(AppTheme.textPrimary)
    .accessibilityIdentifier(mode.accessibilityIdentifier)
  }

  private var emotionRibbon: some View {
    EmotionRibbonView(selectedEmotion: selectedEmotion) { select($0) }
      .appPopoverTip(emotionsTip, isPresented: $emotionsTipPresented, arrowEdge: .top)
      .onChange(of: emotionsTipPresented) { wasShown, isShown in
        if wasShown, !isShown { Task { await TourEvents.emotionsDone.donate() } }
      }
  }

  // Emplacement réservé : hauteur fixe et verset ancré en haut, pour que la révélation mot à mot
  // s'écrive « vers le bas » sans décaler les autres éléments.
  private var verseSlot: some View {
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
  }

  // Sur Duo, le verset est centré dans son propre panneau : conserver le créneau compact de 168 pt
  // ici créerait un vide visuel sous l'état d'attente.
  private var duoVerseContent: some View {
    Group {
      if let emotionVerse {
        EmotionVerseView(
          verse: emotionVerse,
          accent: selectedEmotion?.color ?? AppTheme.adorationPurple
        )
        .transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func prayButtonLabel(verticalPadding: CGFloat) -> some View {
    Label("home.pray.cta", systemImage: "hands.sparkles")
      .font(.headline)
      .foregroundStyle(AppTheme.textPrimary)
      .padding(.horizontal, 26)
      .padding(.vertical, verticalPadding)
  }

  // MARK: - Toolbar

  private var brandingTitle: some View {
    HStack(spacing: 0) {
      Text("Holy")
        .font(AppTheme.tabTitleFont)
        .foregroundStyle(AppTheme.textPrimary)
      Text("Day")
        .font(.system(AppTheme.tabTitleStyle, design: .serif, weight: .thin))
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

  private func present(_ mode: DuoPrayerMode) {
    switch mode {
    case .free:
      recordTokenBeforeFree = prayerRecord.lastRecordToken
      showFreePrayer = true
    case .guided:
      recordTokenBeforeStructured = prayerRecord.lastRecordToken
      showStructuredPrayer = true
    }
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
    PrayerRecordService.shared.recordPrayer()
    WidgetSyncService.sync()
    // Retire le rappel d'aujourd'hui et oriente les suivants vers l'émotion déclarée.
    NotificationService.shared.refreshScheduledReminders()
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

private enum DuoPrayerMode {
  case free
  case guided

  var accessibilityIdentifier: String {
    switch self {
    case .free: "prayer.free.menuItem"
    case .guided: "prayer.guided.menuItem"
    }
  }
}

// MARK: - iPhone Duo composition

private struct DuoPrayerComposer<EmotionContent: View, PrayerContent: View, VerseContent: View>:
  View
{
  let question: String
  let activeIntention: String?
  let activeIntentionCount: Int
  let hasVerse: Bool
  private let onShowIntentions: () -> Void
  private let emotionContent: EmotionContent
  private let prayerContent: PrayerContent
  private let verseContent: VerseContent

  init(
    question: String,
    activeIntention: String?,
    activeIntentionCount: Int,
    hasVerse: Bool,
    onShowIntentions: @escaping () -> Void,
    @ViewBuilder emotionContent: () -> EmotionContent,
    @ViewBuilder prayerContent: () -> PrayerContent,
    @ViewBuilder verseContent: () -> VerseContent
  ) {
    self.question = question
    self.activeIntention = activeIntention
    self.activeIntentionCount = activeIntentionCount
    self.hasVerse = hasVerse
    self.onShowIntentions = onShowIntentions
    self.emotionContent = emotionContent()
    self.prayerContent = prayerContent()
    self.verseContent = verseContent()
  }

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        HStack(alignment: .center, spacing: 28) {
          DuoPrayerActionPane(
            question: question,
            activeIntention: activeIntention,
            activeIntentionCount: activeIntentionCount,
            onShowIntentions: onShowIntentions,
            emotionContent: { emotionContent },
            prayerContent: { prayerContent }
          )
          DuoPrayerVersePane(hasVerse: hasVerse) { verseContent }
        }
        .frame(maxWidth: 1_180)
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .frame(minHeight: proxy.size.height, alignment: .center)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
  }
}

private struct DuoPrayerActionPane<EmotionContent: View, PrayerContent: View>: View {
  let question: String
  let activeIntention: String?
  let activeIntentionCount: Int
  private let onShowIntentions: () -> Void
  private let emotionContent: EmotionContent
  private let prayerContent: PrayerContent

  init(
    question: String,
    activeIntention: String?,
    activeIntentionCount: Int,
    onShowIntentions: @escaping () -> Void,
    @ViewBuilder emotionContent: () -> EmotionContent,
    @ViewBuilder prayerContent: () -> PrayerContent
  ) {
    self.question = question
    self.activeIntention = activeIntention
    self.activeIntentionCount = activeIntentionCount
    self.onShowIntentions = onShowIntentions
    self.emotionContent = emotionContent()
    self.prayerContent = prayerContent()
  }

  var body: some View {
    VStack(spacing: 32) {
      Text(question)
        .font(.system(.title2, design: .serif).weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)

      emotionContent
        .frame(maxWidth: .infinity)

      prayerContent
        .padding(.top, 4)

      if let activeIntention {
        DuoActiveIntentionCard(
          intention: activeIntention,
          count: activeIntentionCount,
          onOpen: onShowIntentions
        )
      }
    }
    .padding(32)
    .frame(maxWidth: .infinity, minHeight: 360, alignment: .center)
    .appGlassEffect(.regular, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
  }
}

private struct DuoActiveIntentionCard: View {
  let intention: String
  let count: Int
  let onOpen: () -> Void

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 12) {
        Image(systemName: "heart.text.square")
          .font(.title3)
          .foregroundStyle(AppTheme.supplicationGreen)

        VStack(alignment: .leading, spacing: 3) {
          Text("intentions.section.active")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
          Text(intention)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }

        Spacer(minLength: 8)

        if count > 1 {
          Text("\(count)")
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(minWidth: 28, minHeight: 28)
            .background(AppTheme.supplicationGreen.opacity(0.14), in: .circle)
        }

        Image(systemName: "chevron.forward")
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .buttonStyle(.plain)
    .appGlassEffect(
      .clear, tint: AppTheme.supplicationGreen.opacity(0.08),
      interactive: true, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

private struct DuoPrayerVersePane<Content: View>: View {
  let hasVerse: Bool
  private let content: Content

  init(hasVerse: Bool, @ViewBuilder content: () -> Content) {
    self.hasVerse = hasVerse
    self.content = content()
  }

  var body: some View {
    Group {
      if !hasVerse {
        VStack(spacing: 12) {
          Image(systemName: "sparkles")
            .font(.title2)
            .foregroundStyle(AppTheme.textTertiary)
            .accessibilityHidden(true)
          Text("tour.emotions.message")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
      } else {
        content
      }
    }
    .padding(32)
    .frame(maxWidth: .infinity, minHeight: 360, alignment: .center)
    .appGlassEffect(.clear, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
  }
}

#Preview {
  ContentView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
    .preferredColorScheme(.dark)
}
