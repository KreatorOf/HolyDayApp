//
//  EmotionRibbonView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftUI

/// Ruban d'émotions défilant doucement de droite à gauche, en boucle continue.
/// Respecte « Réduire les animations » en repliant sur une rangée scrollable statique.
struct EmotionRibbonView: View {
  var onSelect: (Emotion) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  @State private var contentWidth: CGFloat = 0
  @State private var startDate = Date()
  // Le marquee ne redessine que lorsqu'il est réellement à l'écran et l'app active : inutile de
  // brûler des frames quand il est masqué par le clavier, sur un autre onglet ou en arrière-plan.
  @State private var onScreen = true
  // Position de reprise du défilement automatique : capturée au début d'un glissement puis
  // décalée par la translation du doigt, pour repartir sans saut au relâchement.
  @State private var pausedOffset: CGFloat = 0
  @State private var dragOffset: CGFloat = 0
  @State private var isDragging = false
  // Distingue un glissement d'un vrai tap : tant qu'il est vrai, le tap d'une bulle est ignoré
  // pour ne pas afficher le verset à la fin d'un glissement.
  @State private var didDrag = false

  private let emotions = Emotion.allCases
  private let spacing: CGFloat = 12
  private let rowHeight: CGFloat = 48
  // Vitesse de défilement en points par seconde — volontairement lente pour laisser lire et tapper.
  private let pointsPerSecond: CGFloat = 28
  // Marge laissée de chaque côté pour que les bulles ne touchent jamais les bords de l'écran.
  // Alignée sur la marge de lecture du reste de la composition (titre à 32 pt) — HIG : marges
  // latérales cohérentes pour un rythme vertical régulier.
  private let horizontalInset: CGFloat = 24
  // Largeur du fondu sur chaque bord : les bulles apparaissent/disparaissent en douceur.
  private let edgeFade: CGFloat = 36

  var body: some View {
    Group {
      if reduceMotion {
        staticRow
      } else {
        marquee
      }
    }
    .frame(height: rowHeight)
    .mask(alignment: .center) { edgeFadeMask }
    .padding(.horizontal, horizontalInset)
    .onScrollVisibilityChange(threshold: 0.05) { onScreen = $0 }
    .onAppear { onScreen = true }
    .onDisappear { onScreen = false }
  }

  // Anime seulement si l'app est au premier plan ET le ruban visible.
  private var isAnimating: Bool { scenePhase == .active && onScreen }

  // MARK: - Edge fade

  // Dégradé qui rend les bords transparents : effet de fondu « premium » qui évite la coupure
  // nette du `clipped()`. La fraction est calculée sur la largeur réelle pour rester constante
  // en points quelle que soit la taille d'écran.
  private var edgeFadeMask: some View {
    GeometryReader { geo in
      let fraction = geo.size.width > 0 ? min(edgeFade / geo.size.width, 0.5) : 0
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0),
          .init(color: .black, location: fraction),
          .init(color: .black, location: 1 - fraction),
          .init(color: .clear, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
    }
  }

  // MARK: - Static fallback

  private var staticRow: some View {
    ScrollView(.horizontal) {
      HStack(spacing: spacing) {
        ForEach(emotions) { bubble($0) }
      }
      // Aligne la première/dernière bulle au repos sur la fin du fondu de bord.
      .padding(.horizontal, edgeFade)
    }
    .scrollIndicators(.hidden)
  }

  // MARK: - Marquee

  // L'overlay sur un Color.clear pleine largeur évite que la double rangée (largeur idéale
  // énorme) n'élargisse la mise en page ; `clipped()` masque le débordement horizontal.
  // TimelineView pilote l'offset image par image : le défilement reste continu et n'est jamais
  // interrompu par une transaction d'animation parente (ex. la sélection d'une émotion).
  private var marquee: some View {
    Color.clear
      .frame(maxWidth: .infinity)
      .overlay(alignment: .leading) {
        // `paused` coupe le défilement hors écran/inactif ; `minimumInterval` plafonne à ~60 fps
        // (inutile de redessiner à 120 Hz pour un défilement à 28 pt/s) → moins d'énergie.
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isAnimating)) { context in
          HStack(spacing: spacing) {
            row
              .onGeometryChange(for: CGFloat.self) {
                $0.size.width
              } action: { width in
                guard width > 0, contentWidth == 0 else { return }
                contentWidth = width
              }
            row
          }
          .fixedSize()
          .offset(x: displayedOffset(at: context.date))
        }
      }
      .clipped()
      .contentShape(Rectangle())
      .simultaneousGesture(dragGesture)
  }

  // `simultaneousGesture` est indispensable : les bulles sont des Button qui couvrent tout le
  // ruban et captureraient le toucher avant un `.gesture` classique (priorité inférieure).
  // À priorité égale, un tap bref sélectionne l'émotion tandis qu'un déplacement du doigt fait
  // glisser le ruban. `minimumDistance` distingue tap et glissement (HIG).
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 10)
      .onChanged { value in
        if !isDragging {
          // Fige à la position courante du défilement automatique pour éviter un saut.
          pausedOffset = autoOffset(at: Date())
          isDragging = true
        }
        didDrag = true
        dragOffset = value.translation.width
      }
      .onEnded { _ in
        pausedOffset = wrap(pausedOffset + dragOffset)
        dragOffset = 0
        startDate = Date()
        isDragging = false
        // Réinitialisé au cycle suivant : l'action du bouton, déclenchée au lever du doigt
        // dans le cycle courant, voit encore `didDrag == true` et n'affiche pas le verset.
        DispatchQueue.main.async { didDrag = false }
      }
  }

  private var row: some View {
    HStack(spacing: spacing) {
      ForEach(emotions) { bubble($0) }
    }
  }

  // Une période translate d'une copie + l'espacement inter-copies : la 2ᵉ rangée vient alors
  // se superposer exactement à la position de départ de la 1ʳᵉ → boucle sans couture.
  private var period: CGFloat { contentWidth + spacing }

  // Position affichée : suit le doigt pendant un glissement, sinon poursuit le défilement
  // automatique depuis la dernière position de reprise.
  private func displayedOffset(at date: Date) -> CGFloat {
    guard period > 0 else { return 0 }
    return isDragging ? wrap(pausedOffset + dragOffset) : autoOffset(at: date)
  }

  // Défilement automatique de droite à gauche depuis `pausedOffset`.
  private func autoOffset(at date: Date) -> CGFloat {
    guard period > 0 else { return 0 }
    let traveled = CGFloat(date.timeIntervalSince(startDate)) * pointsPerSecond
    return wrap(pausedOffset - traveled)
  }

  // Normalise dans (-période, 0] : le ruban reste couvert par les deux rangées dans les deux
  // sens de glissement, donc la boucle est sans couture même après un glissement vers la droite.
  private func wrap(_ value: CGFloat) -> CGFloat {
    guard period > 0 else { return 0 }
    let remainder = value.truncatingRemainder(dividingBy: period)
    return remainder > 0 ? remainder - period : remainder
  }

  // MARK: - Bubble

  private func bubble(_ emotion: Emotion) -> some View {
    Button {
      // Un glissement ne doit jamais déclencher la sélection (affichage du verset).
      guard !didDrag else { return }
      onSelect(emotion)
    } label: {
      HStack(spacing: 7) {
        Image(systemName: emotion.icon)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(emotion.color)
        Text(emotion.titleKey)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(AppTheme.textPrimary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .glassEffect(.clear.tint(emotion.color.opacity(0.28)).interactive(), in: .capsule)
    .accessibilityLabel(emotion.accessibilityLabel)
  }
}

#Preview {
  ZStack {
    AppBackground()
    EmotionRibbonView { _ in }
  }
  .preferredColorScheme(.dark)
}
