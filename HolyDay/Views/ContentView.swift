//
//  ContentView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
  @State private var streak = StreakService.shared
  @State private var isFABExpanded = false
  @State private var showFreePrayer = false
  @State private var showStructuredPrayer = false
  @State private var showNavTitle = false
  @State private var topInset: CGFloat = 100
  @State private var cachedGreeting = ""
  @State private var verseOfTheDay = VerseService.shared.getVerseOfTheDay()
  @State private var selectedEntry: PrayerEntry?
  @AppStorage("holyday.userName") private var userName = ""

  var body: some View {
    NavigationStack {
      ZStack {
        scrollContent
        if isFABExpanded {
          Color.black.opacity(0.001)
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture { collapse() }
        }
      }
      .overlay(alignment: .bottomTrailing) {
        fabStack
          .padding(.trailing, 24)
          .padding(.bottom, 24)
      }
      .ignoresSafeArea(.all, edges: .top)
      .background { AnimatedMeshBackground() }
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
          HStack(spacing: 0) {
            Text("Holy")
              .font(.system(.callout, design: .serif, weight: .bold).italic())
              .foregroundStyle(AppTheme.textPrimary)
            Text("Day")
              .font(.system(.callout, design: .serif, weight: .thin))
              .foregroundStyle(AppTheme.textPrimary)
          }
          .opacity(showNavTitle ? 1 : 0)
        }
      }
      .navigationDestination(item: $selectedEntry) { entry in
        PrayerEntryDetailView(entry: entry)
      }
    }
    .background(
      GeometryReader { geo in
        Color.clear.onAppear { topInset = geo.safeAreaInsets.top }
      }
      .ignoresSafeArea()
    )
    .fullScreenCover(isPresented: $showFreePrayer) {
      FreePrayerView()
    }
    .fullScreenCover(isPresented: $showStructuredPrayer) {
      StructuredPrayerSheet()
    }
    .onAppear { updateGreeting() }
    .onChange(of: userName) { _, _ in updateGreeting() }
  }

  // MARK: - Scroll content

  private var scrollContent: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerSection
        VerseCardView(verse: verseOfTheDay)
          .padding(.horizontal, 16)
        meditateInvitation
          .padding(.horizontal, 24)
        if let last = lastPrayer {
          continuityCard(last)
            .padding(.horizontal, 16)
        }
      }
      .padding(.top, topInset + 44 + 50)
      .padding(.bottom, 140)
    }
    .scrollIndicators(.hidden)
    .onScrollGeometryChange(for: CGFloat.self) {
      $0.contentOffset.y
    } action: { _, y in
      let shouldShow = y > 80
      guard shouldShow != showNavTitle else { return }
      withAnimation(.easeInOut(duration: 0.2)) { showNavTitle = shouldShow }
    }
  }

  // MARK: - Header

  private var headerSection: some View {
    VStack(alignment: .center, spacing: 2) {
      Text(cachedGreeting)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .tracking(0.3)
        .multilineTextAlignment(.center)
      HStack(spacing: 0) {
        Text("Holy")
          .font(.system(size: 38, weight: .bold, design: .serif).italic())
          .foregroundStyle(AppTheme.textPrimary)
        Text("Day")
          .font(.system(size: 38, weight: .thin, design: .serif))
          .foregroundStyle(AppTheme.textSecondary)
      }
      #if DEBUG
        .onTapGesture(count: 3) {
          streak.resetTodaysPrayer()
          UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
      #endif
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Meditate invitation

  private var meditateInvitation: some View {
    Text(meditatePrompt)
      .font(.system(.body, design: .serif).italic())
      .foregroundStyle(AppTheme.textSecondary)
      .multilineTextAlignment(.center)
      .lineSpacing(4)
      .frame(maxWidth: .infinity)
  }

  // MARK: - Continuity thread

  private func continuityCard(_ entry: PrayerEntry) -> some View {
    Button {
      selectedEntry = entry
    } label: {
      VStack(alignment: .leading, spacing: 6) {
        Text("home.continuity.label")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
          .textCase(.uppercase)
          .tracking(1.0)

        HStack(spacing: 6) {
          Image(systemName: entry.stepIcon)
            .font(.caption)
            .foregroundStyle(AppTheme.color(for: entry.stepColorName))
          Text("\(relativeDay(entry.date)) · \(entry.stepTitle)")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textPrimary)
        }

        Text(entry.text)
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
          .italic()
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
  }

  // MARK: - FAB

  private var fabStack: some View {
    VStack(alignment: .trailing, spacing: 14) {
      if isFABExpanded {
        fabOption(
          icon: "sparkles",
          label: String(localized: "prayer.fab.structured")
        ) {
          collapse()
          showStructuredPrayer = true
        }
        .transition(
          .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
          )
        )

        fabOption(
          icon: "square.and.pencil",
          label: String(localized: "prayer.fab.free")
        ) {
          collapse()
          showFreePrayer = true
        }
        .transition(
          .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
          )
        )
      }

      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
          isFABExpanded.toggle()
        }
      } label: {
        Image(systemName: "plus")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.white)
          .rotationEffect(.degrees(isFABExpanded ? 45 : 0))
          .frame(width: 56, height: 56)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .glassEffect(.regular.tint(AppTheme.adorationPurple.opacity(0.5)), in: Circle())
      .sensoryFeedback(.impact(flexibility: .soft), trigger: isFABExpanded)
    }
  }

  private func fabOption(icon: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.body.weight(.semibold))
          .foregroundStyle(AppTheme.adorationPurple)
        Text(label)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.textPrimary)
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 13)
    }
    .buttonStyle(.plain)
    .glassEffect(.regular, in: Capsule())
  }

  private func collapse() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      isFABExpanded = false
    }
  }

  // MARK: - Helpers

  private var lastPrayer: PrayerEntry? {
    entries.first { !$0.text.isEmpty }
  }

  // Literal keys — a LocalizedStringKey built from string interpolation is treated as a
  // format string and never resolves against the catalog.
  private static let meditatePrompts: [LocalizedStringKey] = [
    "home.meditate.0", "home.meditate.1", "home.meditate.2", "home.meditate.3",
    "home.meditate.4", "home.meditate.5", "home.meditate.6",
  ]

  private var meditatePrompt: LocalizedStringKey {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return Self.meditatePrompts[(dayOfYear - 1) % Self.meditatePrompts.count]
  }

  private func relativeDay(_ date: Date) -> String {
    let calendar = Calendar.current
    let days =
      calendar.dateComponents(
        [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: .now)
      ).day ?? 0
    if days <= 0 { return String(localized: "home.continuity.today") }
    if days == 1 { return String(localized: "home.continuity.yesterday") }
    return String(format: String(localized: "home.continuity.days"), days)
  }

  private func updateGreeting() {
    let hour = Calendar.current.component(.hour, from: Date())
    let base: String
    switch hour {
    case 5..<12: base = String(localized: "greeting.morning")
    case 12..<18: base = String(localized: "greeting.afternoon")
    default: base = String(localized: "greeting.evening")
    }
    cachedGreeting = userName.isEmpty ? base : "\(base), \(userName)"
  }
}

#Preview {
  ContentView()
    .modelContainer(for: PrayerEntry.self, inMemory: true)
    .preferredColorScheme(.dark)
}
