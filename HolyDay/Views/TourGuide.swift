//
//  TourGuide.swift
//  HolyDay
//
//  Created by Matthias Cadet on 07/06/2026.
//

import SwiftUI

// MARK: - Étapes du parcours

/// Tour guidé contextuel joué une fois après l'onboarding : présente les actions clés de l'accueil.
enum TourStep: Int, CaseIterable {
  case emotions, composer, intentions, guidedPrayer

  var title: LocalizedStringKey {
    switch self {
    case .emotions: return "tour.emotions.title"
    case .composer: return "tour.composer.title"
    case .intentions: return "tour.intentions.title"
    case .guidedPrayer: return "tour.guided.title"
    }
  }

  var message: LocalizedStringKey {
    switch self {
    case .emotions: return "tour.emotions.message"
    case .composer: return "tour.composer.message"
    case .intentions: return "tour.intentions.message"
    case .guidedPrayer: return "tour.guided.message"
    }
  }
}

// MARK: - Collecte des ancres

/// Cadre (dans l'espace de l'overlay) de chaque élément ciblé, indexé par `TourStep.rawValue`.
struct TourAnchorKey: PreferenceKey {
  static let defaultValue: [Int: Anchor<CGRect>] = [:]
  static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
    value.merge(nextValue()) { _, new in new }
  }
}

extension View {
  /// Déclare cette vue comme cible d'une étape du tour.
  func tourAnchor(_ step: TourStep) -> some View {
    anchorPreference(key: TourAnchorKey.self, value: .bounds) { [step.rawValue: $0] }
  }

  /// Masque inversé : assombrit tout sauf la forme fournie (le « trou » du spotlight).
  fileprivate func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
    self.mask {
      Rectangle()
        .overlay(alignment: .topLeading) { mask().blendMode(.destinationOut) }
    }
  }
}

// MARK: - Overlay

struct TourOverlayView: View {
  let step: TourStep
  /// Cadre de la cible dans l'espace de l'overlay (nil si introuvable → pas de spotlight).
  let targetRect: CGRect?
  let screen: CGSize
  let index: Int
  let total: Int
  var onNext: () -> Void
  var onSkip: () -> Void

  private var isLast: Bool { index >= total - 1 }
  // Cible dans la moitié haute → bulle (et flèche) en dessous ; sinon au-dessus.
  private var bubbleBelow: Bool { (targetRect?.midY ?? 0) < screen.height / 2 }

  var body: some View {
    ZStack(alignment: .topLeading) {
      dim
      if let rect = targetRect { arrow(for: rect) }
      bubble
    }
  }

  // Fond assombri avec découpe autour de la cible.
  @ViewBuilder private var dim: some View {
    let base = Color.black.opacity(0.6).contentShape(Rectangle()).onTapGesture { onNext() }
    if let rect = targetRect {
      // Capsule plutôt que rectangle : halo entièrement arrondi (pilule pour les éléments larges,
      // cercle pour les boutons). Plus de marge pour que l'arrondi entoure bien la cible.
      let hole = rect.insetBy(dx: -14, dy: -12)
      base.reverseMask {
        Capsule(style: .continuous)
          .frame(width: hole.width, height: hole.height)
          .position(x: hole.midX, y: hole.midY)
      }
    } else {
      base
    }
  }

  private func arrow(for rect: CGRect) -> some View {
    Image(systemName: bubbleBelow ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
      .font(.title3)
      .foregroundStyle(AppTheme.adorationPurple)
      .position(x: rect.midX, y: bubbleBelow ? rect.maxY + 22 : rect.minY - 22)
  }

  private var bubble: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(step.title)
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
      Text(step.message)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 12) {
        Button(action: onSkip) {
          Text("tour.skip")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
        }
        Spacer()
        Text(verbatim: "\(index + 1)/\(total)")
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
        Spacer()
        Button(action: onNext) {
          Text(isLast ? "tour.done" : "tour.next")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.adorationPurple, in: Capsule())
        }
      }
    }
    .padding(16)
    .frame(maxWidth: 320)
    .background {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.regularMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
    .frame(maxWidth: screen.width - 48)
    .position(bubblePosition)
    .buttonStyle(.plain)
  }

  private var bubblePosition: CGPoint {
    guard let rect = targetRect else {
      return CGPoint(x: screen.width / 2, y: screen.height / 2)
    }
    let y = bubbleBelow ? min(rect.maxY + 130, screen.height - 130) : max(rect.minY - 130, 150)
    return CGPoint(x: screen.width / 2, y: y)
  }
}
