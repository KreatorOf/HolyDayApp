//
//  EmotionRibbonView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftUI

/// Deux rangées d'émotions qui défilent en boucle continue, en sens opposés, pour donner de
/// l'épaisseur. Défilement ambiant uniquement : un tap sélectionne une émotion (pas de glissement
/// manuel). Respecte « Réduire les animations » en repliant sur des rangées scrollables statiques.
struct EmotionRibbonView: View {
  var onSelect: (Emotion) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  // Le marquee ne redessine que lorsqu'il est réellement à l'écran et l'app active : inutile de
  // brûler des frames quand il est masqué par le clavier, sur un autre onglet ou en arrière-plan.
  @State private var onScreen = true
  @State private var startDate = Date()
  // Partition figée des 8 émotions en deux rangées de 4, mélangée une seule fois : l'ordre ne doit
  // pas sauter à chaque redraw (60 fps).
  @State private var rows: [[Emotion]] = EmotionRibbonView.makeRows()

  private let spacing: CGFloat = 12
  private let rowHeight: CGFloat = 48
  private let rowSpacing: CGFloat = 10
  // Marge laissée de chaque côté pour que les bulles ne touchent jamais les bords de l'écran.
  // Alignée sur la marge de lecture du reste de la composition (titre à 32 pt) — HIG : marges
  // latérales cohérentes pour un rythme vertical régulier.
  private let horizontalInset: CGFloat = 24
  // Largeur du fondu sur chaque bord : les bulles apparaissent/disparaissent en douceur.
  private let edgeFade: CGFloat = 36
  // Vitesses légèrement différentes par rangée → parallaxe organique plutôt qu'un tapis roulant.
  private let speeds: [CGFloat] = [24, 30]

  private static func makeRows() -> [[Emotion]] {
    let shuffled = Emotion.allCases.shuffled()
    let mid = shuffled.count / 2
    return [Array(shuffled[..<mid]), Array(shuffled[mid...])]
  }

  var body: some View {
    Group {
      if reduceMotion {
        staticRows
      } else {
        marquee
      }
    }
    .frame(height: rowHeight * 2 + rowSpacing)
    .mask(alignment: .center) { edgeFadeMask }
    .padding(.horizontal, horizontalInset)
    .onScrollVisibilityChange(threshold: 0.05) { onScreen = $0 }
    .onAppear { onScreen = true }
    .onDisappear { onScreen = false }
  }

  // Anime seulement si l'app est au premier plan ET le ruban visible.
  private var isAnimating: Bool { scenePhase == .active && onScreen }

  // MARK: - Marquee

  // Une seule horloge `TimelineView` partagée par les deux rangées : `paused` coupe le défilement
  // hors écran/inactif ; `minimumInterval` plafonne à ~60 fps (inutile de redessiner à 120 Hz pour
  // un défilement lent) → moins d'énergie. Chaque rangée dérive son offset de cette même date.
  private var marquee: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isAnimating)) { context in
      VStack(spacing: rowSpacing) {
        MarqueeRow(
          emotions: rows[0], direction: .leftward, speed: speeds[0],
          spacing: spacing, rowHeight: rowHeight,
          date: context.date, startDate: startDate, onSelect: onSelect)
        MarqueeRow(
          emotions: rows[1], direction: .rightward, speed: speeds[1],
          spacing: spacing, rowHeight: rowHeight,
          date: context.date, startDate: startDate, onSelect: onSelect)
      }
    }
  }

  // MARK: - Static fallback

  private var staticRows: some View {
    VStack(spacing: rowSpacing) {
      ForEach(rows.indices, id: \.self) { index in
        ScrollView(.horizontal) {
          HStack(spacing: spacing) {
            ForEach(rows[index]) { EmotionBubble(emotion: $0, onSelect: onSelect) }
          }
          // Aligne la première/dernière bulle au repos sur la fin du fondu de bord.
          .padding(.horizontal, edgeFade)
        }
        .frame(height: rowHeight)
        .scrollIndicators(.hidden)
      }
    }
  }

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
}

// MARK: - Marquee row

/// Une rangée qui défile en boucle dans une direction donnée. La logique est encapsulée ici pour
/// pouvoir empiler plusieurs rangées indépendantes. La date provient d'une horloge partagée par le
/// parent ; seule la largeur du contenu est mesurée localement.
private struct MarqueeRow: View {
  enum Direction { case leftward, rightward }

  let emotions: [Emotion]
  let direction: Direction
  let speed: CGFloat
  let spacing: CGFloat
  let rowHeight: CGFloat
  let date: Date
  let startDate: Date
  let onSelect: (Emotion) -> Void

  @State private var contentWidth: CGFloat = 0

  var body: some View {
    // L'overlay sur un Color.clear pleine largeur évite que les copies (largeur idéale énorme)
    // n'élargissent la mise en page ; `clipped()` masque le débordement horizontal.
    Color.clear
      .frame(maxWidth: .infinity)
      .frame(height: rowHeight)
      .overlay(alignment: .leading) {
        HStack(spacing: spacing) {
          // Trois copies : avec seulement 4 bulles par rangée, le contenu peut être plus étroit que
          // l'écran ; il faut assez de copies pour couvrir le viewport quel que soit l'offset.
          row
            .onGeometryChange(for: CGFloat.self) {
              $0.size.width
            } action: { width in
              guard width > 0, contentWidth == 0 else { return }
              contentWidth = width
            }
          row
          row
        }
        .fixedSize()
        .offset(x: offset)
      }
      .clipped()
  }

  private var row: some View {
    HStack(spacing: spacing) {
      ForEach(emotions) { EmotionBubble(emotion: $0, onSelect: onSelect) }
    }
  }

  // Une période translate d'une copie + l'espacement : la copie suivante vient alors exactement à la
  // position de départ de la précédente → boucle sans couture. Les copies étant identiques, le saut
  // de wrap (d'une période pile) atterrit sur un contenu identique : invisible.
  private var period: CGFloat { contentWidth + spacing }

  private var offset: CGFloat {
    guard period > 0 else { return 0 }
    let traveled = CGFloat(date.timeIntervalSince(startDate)) * speed
    // Les deux sens partagent le même wrap dans (-période, 0] ; seul le signe de la distance change.
    return wrap(direction == .leftward ? -traveled : traveled)
  }

  // Normalise dans (-période, 0].
  private func wrap(_ value: CGFloat) -> CGFloat {
    guard period > 0 else { return 0 }
    let remainder = value.truncatingRemainder(dividingBy: period)
    return remainder > 0 ? remainder - period : remainder
  }
}

// MARK: - Bubble

/// Bulle d'une émotion, partagée par le marquee et le repli statique. Teintée par la pastel propre à
/// l'émotion ; le tap déclenche la sélection.
private struct EmotionBubble: View {
  let emotion: Emotion
  let onSelect: (Emotion) -> Void

  var body: some View {
    Button {
      onSelect(emotion)
    } label: {
      HStack(spacing: 7) {
        Image(systemName: emotion.icon)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(emotion.pastel)
        Text(emotion.titleKey)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(AppTheme.textPrimary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .glassEffect(.clear.tint(emotion.pastel.opacity(0.28)).interactive(), in: .capsule)
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
