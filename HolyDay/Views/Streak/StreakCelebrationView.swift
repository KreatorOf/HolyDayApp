//
//  StreakCelebrationView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 22/05/2026.
//

import SwiftUI

struct StreakCelebrationView: View {
  let streakValue: Int
  @Environment(\.dismiss) private var dismiss

  @State private var breathe = false
  @State private var appeared = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      AnimatedMeshBackground()
        .overlay(Color.black.opacity(0.45))

      FallingFlamesView()

      VStack(spacing: 32) {
        Spacer()

        VStack(spacing: 12) {
          Image(systemName: "flame.fill")
            .font(.system(size: 72))
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.orange, AppTheme.thanksgivingGold.opacity(0.9))

          Text(String(format: String(localized: "streak.celebration.title"), streakValue))
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 24)

          Text("streak.celebration.subtitle")
            .font(.system(size: 20, weight: .regular, design: .default))
            .foregroundStyle(AppTheme.textSecondary.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 32)
        }
        .scaleEffect(breathe ? 1.03 : 1.0)
        .animation(
          reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(autoreverses: true),
          value: breathe
        )

        Spacer()

        Button {
          let generator = UIImpactFeedbackGenerator(style: .light)
          generator.prepare()
          generator.impactOccurred()

          dismiss()
        } label: {
          HStack(spacing: 12) {
            Text(String(localized: "streak.celebration.cta"))
            Image(systemName: "hands.and.sparkles.fill")
              .font(.title3)
              .symbolRenderingMode(.hierarchical)
              .symbolEffect(.bounce.down.byLayer, options: .nonRepeating)

          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .font(.body.weight(.semibold))
        .padding(.horizontal, 48)
        .padding(.bottom, 48)
      }
    }
    .ignoresSafeArea()
    .sensoryFeedback(.success, trigger: appeared)
    .onAppear {
      appeared = true
      if reduceMotion { return }
      withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathe = true }
    }
  }
}

#Preview {
  StreakCelebrationView(streakValue: 7)
}
