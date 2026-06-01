//
//  AppBackground.swift
//  HolyDay
//
//  Created by Matthias Cadet on 01/06/2026.
//

import SwiftUI

/// Fond global de l'application.
/// Light : blanc neutre. Dark : violet profond avec un ovale central plus sombre (dégradé
/// elliptique) qui creuse un peu la profondeur au centre de l'écran.
struct AppBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    AppTheme.backgroundPrimary
      .overlay {
        if colorScheme == .dark {
          EllipticalGradient(
            colors: [Color.black.opacity(0.5), .clear],
            center: .center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.85
          )
        }
      }
      .ignoresSafeArea()
      .accessibilityHidden(true)
  }
}
