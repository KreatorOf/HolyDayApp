//
//  SupportPromptView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 03/06/2026.
//

import SwiftUI

/// Sollicitation douce et non-bloquante proposée après quelques jours de prière : remercie
/// l'utilisateur et l'invite, sans pression, à soutenir le développeur. Trois sorties possibles :
/// soutenir (ouvre le paywall), plus tard, ou ne plus jamais demander.
struct SupportPromptView: View {
  var onSupport: () -> Void
  var onLater: () -> Void
  var onDontAskAgain: () -> Void

  var body: some View {
    ZStack {
      AppBackground()

      VStack(spacing: 0) {
        Spacer(minLength: 0)

        VStack(spacing: 18) {
          icon
          Text("support.prompt.title")
            .font(.system(.title2, design: .serif, weight: .bold).italic())
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
          Text("support.prompt.message")
            .font(.body)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 36)

        Spacer(minLength: 0)

        actions
      }
      .padding(.vertical, 32)
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  // MARK: - Icon

  private var icon: some View {
    ZStack {
      Circle()
        .fill(AppTheme.adorationPurple.opacity(0.12))
        .frame(width: 96, height: 96)
      Image(systemName: "hands.sparkles.fill")
        .font(.system(size: 38, weight: .medium))
        .foregroundStyle(AppTheme.adorationPurple)
    }
  }

  // MARK: - Actions

  private var actions: some View {
    VStack(spacing: 14) {
      Button(action: onSupport) {
        Text("support.prompt.cta")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
          .background(AppTheme.adorationPurple, in: RoundedRectangle(cornerRadius: 16))
      }
      .buttonStyle(.plain)

      Button(action: onLater) {
        Text("support.prompt.later")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(AppTheme.textSecondary)
      }
      .buttonStyle(.plain)

      Button(action: onDontAskAgain) {
        Text("support.prompt.never")
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .underline()
      }
      .buttonStyle(.plain)
      .padding(.top, 2)
    }
    .padding(.horizontal, 28)
  }
}

#Preview {
  Color.black
    .sheet(isPresented: .constant(true)) {
      SupportPromptView(onSupport: {}, onLater: {}, onDontAskAgain: {})
    }
}
