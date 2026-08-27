//
//  WidgetTheme.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

/// Palette commune aux widgets : fond nuit signature de l'app + accents.
/// L'or vient du colorset `thanksgivingGold` (copie de celui de l'app — l'extension ne voit pas
/// le catalogue de la cible app).
enum WidgetTheme {
  static let night = Color(red: 0.05, green: 0.05, blue: 0.12)
  static let violet = Color(red: 0.55, green: 0.35, blue: 0.85)
  static let gold = Color("thanksgivingGold")

  // Hiérarchie de texte sur fond nuit — trois niveaux nommés, plancher à 0.55 pour rester
  // au-dessus de 4.5:1 de contraste (cohérence avec la refonte contraste de l'app).
  static let textSecondary = Color.white.opacity(0.7)
  static let textTertiary = Color.white.opacity(0.55)
  static let separator = Color.white.opacity(0.16)

  /// Styles de texte selon le mode de rendu : plein couleur → hiérarchie blanche sur fond nuit ;
  /// teinté/vibrant (iOS 18+) → styles sémantiques, le système applique teinte et matière
  /// lui-même (le fond nuit est alors remplacé, la hiérarchie doit tenir sans lui).
  struct Palette {
    let primary: AnyShapeStyle
    let secondary: AnyShapeStyle
    let tertiary: AnyShapeStyle

    init(_ mode: WidgetRenderingMode) {
      if mode == .fullColor {
        primary = AnyShapeStyle(Color.white)
        secondary = AnyShapeStyle(WidgetTheme.textSecondary)
        tertiary = AnyShapeStyle(WidgetTheme.textTertiary)
      } else {
        primary = AnyShapeStyle(.primary)
        secondary = AnyShapeStyle(.secondary)
        tertiary = AnyShapeStyle(.secondary)
      }
    }
  }

  /// Pastel de l'émotion portée par le dernier verset — copie de `Emotion.pastel`, dont le type
  /// vit côté app ; la `rawValue` transite par `SharedStore`.
  static func accent(forEmotionTag tag: String) -> Color {
    switch tag {
    case "joy": Color(red: 0.95, green: 0.68, blue: 0.22)
    case "peace": Color(red: 0.40, green: 0.80, blue: 0.58)
    case "gratitude": Color(red: 0.99, green: 0.58, blue: 0.42)
    case "sadness": Color(red: 0.40, green: 0.64, blue: 0.93)
    case "fear": Color(red: 0.70, green: 0.56, blue: 0.96)
    case "fatigue": Color(red: 0.46, green: 0.52, blue: 0.82)
    case "anger": Color(red: 0.93, green: 0.42, blue: 0.40)
    case "hope": Color(red: 0.26, green: 0.76, blue: 0.73)
    default: violet
    }
  }

  /// Symbole de l'émotion — copie de `Emotion.icon` (même raison que `accent(forEmotionTag:)`).
  static func icon(forEmotionTag tag: String) -> String {
    switch tag {
    case "joy": "sun.max.fill"
    case "peace": "leaf.fill"
    case "gratitude": "hands.and.sparkles.fill"
    case "sadness": "cloud.rain.fill"
    case "fear": "wind"
    case "fatigue": "moon.zzz.fill"
    case "anger": "flame.fill"
    case "hope": "sunrise.fill"
    default: "book.closed.fill"
    }
  }

  /// Fond nuit avec un voile dégradé de la couleur d'accent, commun aux trois widgets.
  static func nightBackground(accent: Color, intensity: Double = 0.15) -> some View {
    ZStack {
      night
      LinearGradient(
        colors: [accent.opacity(intensity), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }
}
