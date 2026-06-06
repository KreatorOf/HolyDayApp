//
//  SplashView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 06/06/2026.
//

import SwiftUI

/// Écran de démarrage affiché brièvement à chaque lancement à froid : motif + nom de l'app, animés,
/// avant de céder la place au contenu. Purement visuel ; sa durée est pilotée par l'appelant.
struct SplashView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var appeared = false

  var body: some View {
    ZStack {
      AppBackground()

      VStack(spacing: 18) {
        ZStack {
          Circle()
            .fill(AppTheme.adorationPurple.opacity(0.12))
            .frame(width: 104, height: 104)
          Image("prayingHands")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .foregroundStyle(AppTheme.adorationPurple)
        }

        // Marque « HolyDay » (nom propre, non localisé) reprenant la typographie de l'app.
        HStack(spacing: 0) {
          Text(verbatim: "Holy")
            .font(.system(.largeTitle, design: .serif, weight: .bold).italic())
          Text(verbatim: "Day")
            .font(.system(.largeTitle, design: .serif, weight: .thin))
        }
        .foregroundStyle(AppTheme.textPrimary)
      }
      .scaleEffect(appeared ? 1 : 0.92)
      .opacity(appeared ? 1 : 0)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: "HolyDay"))
    .task {
      guard !reduceMotion else {
        appeared = true
        return
      }
      withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { appeared = true }
    }
  }
}

#Preview {
  SplashView()
}
