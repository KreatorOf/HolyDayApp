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
  @State private var contentWidth: CGFloat = 0
  @State private var startDate = Date()

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
        TimelineView(.animation) { context in
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
          .offset(x: offset(at: context.date))
        }
      }
      .clipped()
  }

  private var row: some View {
    HStack(spacing: spacing) {
      ForEach(emotions) { bubble($0) }
    }
  }

  // Une période translate d'une copie + l'espacement inter-copies : la 2ᵉ rangée vient alors
  // se superposer exactement à la position de départ de la 1ʳᵉ → boucle sans couture.
  private func offset(at date: Date) -> CGFloat {
    let distance = contentWidth + spacing
    guard distance > 0 else { return 0 }
    let traveled = CGFloat(date.timeIntervalSince(startDate)) * pointsPerSecond
    return -traveled.truncatingRemainder(dividingBy: distance)
  }

  // MARK: - Bubble

  private func bubble(_ emotion: Emotion) -> some View {
    Button {
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
