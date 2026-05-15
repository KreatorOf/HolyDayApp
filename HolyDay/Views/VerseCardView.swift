//
//  VerseCardView.swift
//  Kairos
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct VerseCardView: View {
    let verse: Verse
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête avec badge premium
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.thanksgivingGold)
                    Text("Verset du jour")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                
                Spacer()
                
                // Badge date premium
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    }
            }
            
            // Texte du verset avec style premium
            Text(verse.text)
                .font(.title3)
                .fontWeight(.medium)
                .lineSpacing(10)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
            
            // Référence avec accent gold
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.thanksgivingGold)
                        .frame(width: 4, height: 4)
                    Text(verse.reference)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.thanksgivingGold)
                }
            }
        }
        .padding(28)
        .background {
            ZStack {
                // Gradient de fond subtil clippé à la forme
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.primaryGradient.opacity(0.15))

                // Glass effect
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Bordure lumineuse
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: AppTheme.premiumShadow, radius: 20, x: 0, y: 10)
            .shadow(color: AppTheme.thanksgivingGold.opacity(0.2), radius: 30, x: 0, y: 15)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundPrimary
            .ignoresSafeArea()
        
        VerseCardView(verse: Verse(
            text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.",
            reference: "Jean 3:16",
            book: "Jean",
            chapter: 3,
            verse: 16
        ))
        .padding()
    }
}
