//
//  GlassCompat.swift
//  HolyDay
//
//  Created by Matthias Cadet on 25/08/2026.
//

import SwiftUI

// Liquid Glass (`glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`) est exclusif à
// iOS 26. L'app cible iOS 18, donc chaque surface de verre passe par cette couche : verre natif à
// partir d'iOS 26, matériau translucide équivalent en dessous. Le repli reproduit l'intention
// visuelle (profondeur + teinte de marque), pas le rendu — c'est volontaire : imiter le verre en
// dessous coûterait cher en GPU pour un résultat approximatif.

// MARK: - Style

/// Variante de verre demandée par un appel, indépendante de la disponibilité de `Glass` (iOS 26+).
enum AppGlassStyle {
  /// Verre translucide standard, la surface par défaut.
  case regular
  /// Verre plus transparent : laisse passer le fond, utilisé sur les puces d'émotion.
  case clear

  /// Matériau de repli sous iOS 26. `.clear` est plus transparent que `.regular`, l'échelle des
  /// matériaux système reproduit ce rapport.
  fileprivate var fallbackMaterial: Material {
    switch self {
    case .regular: .ultraThinMaterial
    case .clear: .thinMaterial
    }
  }
}

// MARK: - View modifiers

extension View {
  /// Applique le verre iOS 26 ou son repli matériau, dans la forme donnée.
  ///
  /// - Parameters:
  ///   - style: variante de verre.
  ///   - tint: teinte de marque appliquée par-dessus le verre (sélection, mise en avant).
  ///   - interactive: réaction du verre au toucher. Sans effet sous iOS 26 : le repli matériau n'a
  ///     pas d'équivalent, le retour au toucher reste porté par le `Button` lui-même.
  ///   - shape: forme de la surface.
  @ViewBuilder
  func appGlassEffect(
    _ style: AppGlassStyle = .regular,
    tint: Color? = nil,
    interactive: Bool = false,
    in shape: some Shape
  ) -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(Glass.appGlass(style, tint: tint, interactive: interactive), in: shape)
    } else {
      background {
        ZStack {
          shape.fill(style.fallbackMaterial)
          if let tint {
            shape.fill(tint)
          }
          // Le verre natif dessine un liseré lumineux sur son bord ; sans lui le repli se fond
          // dans l'arrière-plan et les surfaces perdent leur séparation.
          shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        }
      }
    }
  }

  /// Style de bouton en verre iOS 26, avec repli `.bordered` (mêmes métriques et zone tactile).
  @ViewBuilder
  func appGlassButtonStyle() -> some View {
    if #available(iOS 26.0, *) {
      buttonStyle(.glass)
    } else {
      buttonStyle(.bordered)
    }
  }
}

@available(iOS 26.0, *)
extension Glass {
  fileprivate static func appGlass(
    _ style: AppGlassStyle,
    tint: Color?,
    interactive: Bool
  ) -> Glass {
    var glass: Glass =
      switch style {
      case .regular: .regular
      case .clear: .clear
      }
    if let tint {
      glass = glass.tint(tint)
    }
    if interactive {
      glass = glass.interactive()
    }
    return glass
  }
}

// MARK: - Container

/// `GlassEffectContainer` (iOS 26) fait fusionner les surfaces de verre proches. Sous iOS 26 il n'y
/// a rien à fusionner : le conteneur s'efface et laisse passer son contenu tel quel.
struct AppGlassEffectContainer<Content: View>: View {
  private let spacing: CGFloat?
  private let content: Content

  init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: spacing) { content }
    } else {
      content
    }
  }
}
