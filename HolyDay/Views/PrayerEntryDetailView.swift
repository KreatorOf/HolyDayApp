//
//  PrayerEntryDetailView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftData
import SwiftUI

struct PrayerEntryDetailView: View {
  let entry: PrayerEntry

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        entryHeader
        Divider()
          .overlay(Color.white.opacity(0.12))
        prayerContent
        if entry.stepColorName == "supplicationGreen" {
          answeredButton
        }
      }
      .padding(20)
    }
    .navigationBarTitleDisplayMode(.inline)
    .background { AppBackground() }
  }

  private var answeredButton: some View {
    Button {
      entry.isAnswered.toggle()
      entry.answeredAt = entry.isAnswered ? .now : nil
    } label: {
      HStack(spacing: 10) {
        Image(systemName: entry.isAnswered ? "checkmark.seal.fill" : "checkmark.seal")
          .font(.callout.weight(.semibold))
        Text(entry.isAnswered ? "entry.answered.label" : "entry.mark.answered.label")
          .font(.subheadline.weight(.semibold))
      }
      .foregroundStyle(entry.isAnswered ? Color.black.opacity(0.7) : AppTheme.supplicationGreen)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(
            entry.isAnswered ? AppTheme.supplicationGreen : AppTheme.supplicationGreen.opacity(0.12)
          )
          .overlay {
            if !entry.isAnswered {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.supplicationGreen.opacity(0.4), lineWidth: 1)
            }
          }
      }
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: entry.isAnswered)
  }

  private var entryHeader: some View {
    HStack(spacing: 14) {
      Image(systemName: entry.stepIcon)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(entry.accentColor)
        .frame(width: 50, height: 50)
        .background(entry.accentColor.opacity(0.15))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(entry.stepTitle)
          .font(.title3)
          .fontWeight(.bold)
        Text(entry.date.formatted(date: .long, time: .shortened))
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
      }
      Spacer()
    }
  }

  private var prayerContent: some View {
    Group {
      if entry.text.isEmpty {
        Text("entry.no.text")
          .font(.body)
          .foregroundStyle(AppTheme.textSecondary)
          .italic()
      } else {
        Text(entry.text)
          .font(.body)
          .lineSpacing(8)
      }
    }
  }
}

#Preview {
  NavigationStack {
    PrayerEntryDetailView(
      entry: PrayerEntry(
        stepTitle: "Adoration",
        stepIcon: "hands.sparkles",
        stepColorName: "adorationPurple",
        text:
          "Seigneur, je te loue pour ta grandeur et ta bonté infinie. Tu es digne de toute gloire et de tout honneur.",
        date: .now
      ))
  }
  .preferredColorScheme(.dark)
}
