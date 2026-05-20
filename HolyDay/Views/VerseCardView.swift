//
//  VerseCardView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct VerseCardView: View {
    let verse: Verse

    private var bookAccentColor: Color {
        switch verse.book {
        case "Jean", "Matthieu", "Marc", "Luc",
             "John", "Matthew", "Mark", "Luke":
            return AppTheme.confessionBlue
        case "Psaumes", "Proverbes",
             "Psalms", "Proverbs":
            return AppTheme.thanksgivingGold
        case "Philippiens", "Jacques", "1 Pierre",
             "Philippians", "James", "1 Peter":
            return AppTheme.supplicationGreen
        default:
            return AppTheme.adorationPurple
        }
    }

    private var shareText: String {
        "\"\(verse.text)\"\n\n— \(verse.reference)\n\n\(String(localized: "verse.share.footer"))\n\(AppLinks.appStore)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundStyle(bookAccentColor)
                    Text("verse.card.title")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }

                Spacer()

                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(Color.white.opacity(0.1))
                    }

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(bookAccentColor.opacity(0.9))
                        .padding(9)
                        .background {
                            Circle().fill(Color.white.opacity(0.08))
                        }
                }
            }

            Text(verse.text)
                .font(.title3)
                .fontWeight(.medium)
                .lineSpacing(10)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(bookAccentColor)
                        .frame(width: 4, height: 4)
                    Text(verse.reference)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(bookAccentColor)
                }
            }
        }
        .padding(28)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.primaryGradient.opacity(0.15))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                bookAccentColor.opacity(0.4),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: AppTheme.premiumShadow, radius: 20, x: 0, y: 10)
            .shadow(color: bookAccentColor.opacity(0.18), radius: 30, x: 0, y: 15)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 16) {
            VerseCardView(verse: Verse(
                text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique.",
                reference: "Jean 3:16", book: "Jean", chapter: 3, verse: 16
            ))
            VerseCardView(verse: Verse(
                text: "L'Éternel est mon berger : je ne manquerai de rien.",
                reference: "Psaume 23:1", book: "Psaumes", chapter: 23, verse: 1
            ))
        }
        .padding()
    }
}
