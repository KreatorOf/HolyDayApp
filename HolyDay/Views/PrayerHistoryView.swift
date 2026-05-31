//
//  PrayerHistoryView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import FoundationModels
import SwiftData
import SwiftUI

struct PrayerHistoryView: View {
  @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
  @Environment(\.modelContext) private var modelContext
  @State private var tipService = TipService.shared
  @State private var displayedMonth: Date = Self.firstOfCurrentMonth()
  @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
  @State private var topInset: CGFloat = 100
  @State private var showNavTitle = false
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var cachedSearchResults: [(date: Date, entries: [PrayerEntry])] = []
  @State private var aiResults: [(date: Date, entries: [PrayerEntry])]?
  @State private var isAISearching = false
  @State private var showInsight = false
  @State private var showAIPaywall = false

  private static func firstOfCurrentMonth() -> Date {
    let cal = Calendar.current
    let c = cal.dateComponents([.year, .month], from: Date())
    return cal.date(from: c) ?? Date()
  }

  private static let monthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale.current
    f.dateFormat = "MMMM yyyy"
    return f
  }()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          pageHeader
          if isSearching {
            searchPanelSection
              .padding(.horizontal, 16)
          } else {
            calendarCard
              .padding(.horizontal, 16)
            selectedDaySection
              .padding(.horizontal, 16)
          }
        }
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)
      .ignoresSafeArea(.all, edges: .top)
      .onScrollGeometryChange(for: CGFloat.self) {
        $0.contentOffset.y
      } action: { _, y in
        let shouldShow = y > 80
        guard shouldShow != showNavTitle else { return }
        withAnimation(.easeInOut(duration: 0.2)) { showNavTitle = shouldShow }
      }
      .background { AnimatedMeshBackground() }
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("tab.journal")
            .font(.system(.callout, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .opacity(showNavTitle ? 1 : 0)
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 14) {
            Button {
              showInsight = true
            } label: {
              Image(systemName: "sparkles")
                .foregroundStyle(AppTheme.adorationPurple)
            }
            .sensoryFeedback(.selection, trigger: showInsight)
            .accessibilityLabel(String(localized: "accessibility.ai.button"))
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSearching.toggle()
                if !isSearching { searchText = "" }
              }
            } label: {
              Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityLabel(
              isSearching
                ? String(localized: "accessibility.search.close")
                : String(localized: "accessibility.search.open")
            )
          }
        }
      }
      .task(id: searchText) {
        // A new query exits semantic-search mode back to instant local matching.
        aiResults = nil
        guard !searchText.isEmpty else {
          cachedSearchResults = []
          return
        }
        // Debounce: cancel previous task if user is still typing
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        let text = searchText
        let snapshot = entries
        let matched = snapshot.filter {
          $0.text.localizedCaseInsensitiveContains(text)
            || $0.stepTitle.localizedCaseInsensitiveContains(text)
        }
        let grouped = Dictionary(grouping: matched) {
          Calendar.current.startOfDay(for: $0.date)
        }
        cachedSearchResults =
          grouped
          .sorted { $0.key > $1.key }
          .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
      }
    }
    .sheet(isPresented: $showInsight) {
      NavigationStack {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            AnsweredPrayersInsight()
            PrayerRhythmInsight()
            ACTSBalanceInsight()
            if tipService.hasAIFeature {
              MonthlyRecapSection(entries: currentMonthEntries)
              JournalAIInsightSection(entries: entries)
            } else {
              AIInsightUpsellCard {
                showInsight = false
                showAIPaywall = true
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.backgroundPrimary.ignoresSafeArea())
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(role: .close) { showInsight = false }
          }
        }
      }
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showAIPaywall) {
      HolyDayPaywallView(context: .aiFeature)
    }
    .background(
      GeometryReader { geo in
        Color.clear.onAppear { topInset = geo.safeAreaInsets.top }
      }
      .ignoresSafeArea()
    )
  }

  // MARK: Page header

  private var pageHeader: some View {
    VStack(alignment: .leading, spacing: isSearching ? 12 : 4) {
      Text("tab.journal")
        .font(.system(.largeTitle, design: .serif).weight(.bold).italic())
        .foregroundStyle(AppTheme.textPrimary)
      if isSearching {
        HStack(spacing: 10) {
          Image(systemName: "magnifyingglass")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
          TextField(String(localized: "journal.search.placeholder"), text: $searchText)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
          if !searchText.isEmpty {
            Button {
              searchText = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(AppTheme.textTertiary)
            }
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(AppTheme.cardFill)
            .overlay {
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(.top, topInset + 44 + 50)
    .padding(.horizontal, 16)
  }

  // MARK: Calendar card

  private var calendarCard: some View {
    let prayedDays = prayedDaysInMonth
    return VStack(spacing: 0) {
      monthNavigationHeader
      monthInsightStrip(dayCount: prayedDays.count)
      weekDayLabels
      calendarDayGrid(prayedDays: prayedDays)
    }
    .background {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  private var monthNavigationHeader: some View {
    HStack {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          navigateMonth(by: -1)
        }
      } label: {
        Image(systemName: "chevron.left")
          .font(.callout.weight(.semibold))
          .foregroundStyle(AppTheme.textSecondary)
          .frame(width: 36, height: 36)
          .background(Circle().fill(AppTheme.buttonFillSubtle))
      }

      Spacer()

      VStack(spacing: 3) {
        Text(monthYearLabel)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.textPrimary)
        if !isCurrentMonth {
          Button(action: goToCurrentMonth) {
            HStack(spacing: 3) {
              Image(systemName: "arrow.uturn.left")
                .font(.system(size: 9, weight: .semibold))
              Text(String(localized: "date.today"))
                .font(.caption2.weight(.medium))
            }
            .foregroundStyle(AppTheme.thanksgivingGold)
          }
          .transition(.opacity.combined(with: .scale))
        }
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCurrentMonth)

      Spacer()

      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          navigateMonth(by: 1)
        }
      } label: {
        Image(systemName: "chevron.right")
          .font(.callout.weight(.semibold))
          .foregroundStyle(AppTheme.textSecondary)
          .frame(width: 36, height: 36)
          .background(Circle().fill(AppTheme.buttonFillSubtle))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }

  private func monthInsightStrip(dayCount: Int) -> some View {
    let text = monthInsightText(dayCount: dayCount)
    return HStack(spacing: 6) {
      Image(systemName: "hands.sparkles")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(AppTheme.thanksgivingGold)
      Text(text)
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
    .animation(.easeInOut(duration: 0.2), value: text)
  }

  private var weekDayLabels: some View {
    let labels = String(localized: "calendar.weekday.labels").components(separatedBy: ",")
    return HStack(spacing: 0) {
      ForEach(labels.indices, id: \.self) { i in
        Text(labels[i])
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 10)
  }

  private func calendarDayGrid(prayedDays: [Date: Int]) -> some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
      spacing: 6
    ) {
      ForEach(calendarDays.indices, id: \.self) { i in
        if let date = calendarDays[i] {
          calendarDayView(date, prayedDays: prayedDays)
        } else {
          Color.clear.frame(height: 44)
        }
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 14)
  }

  private func calendarDayView(_ date: Date, prayedDays: [Date: Int]) -> some View {
    let calendar = Calendar.current
    let isToday = calendar.isDateInToday(date)
    let startOfDay = calendar.startOfDay(for: date)
    let isSelected = selectedDate == startOfDay
    let count = prayedDays[startOfDay, default: 0]
    let hasPrayer = count > 0
    let dotIntensity = min(Double(count), 3.0) / 3.0
    let isFuture = startOfDay > calendar.startOfDay(for: Date())
    return Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        selectedDate = startOfDay
      }
    } label: {
      VStack(spacing: 3) {
        ZStack {
          if isSelected {
            Circle().fill(AppTheme.adorationPurple)
          } else if isToday {
            Circle().strokeBorder(AppTheme.thanksgivingGold.opacity(0.7), lineWidth: 1.5)
          }
          Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
            .foregroundStyle(
              isSelected ? Color.white : isFuture ? AppTheme.textTertiary : AppTheme.textPrimary
            )
        }
        .frame(width: 34, height: 34)

        Circle()
          .fill(
            hasPrayer
              ? (isSelected
                ? Color.white : AppTheme.thanksgivingGold.opacity(0.3 + 0.7 * dotIntensity))
              : Color.clear
          )
          .frame(width: 5, height: 5)
      }
    }
    .disabled(isFuture)
  }

  // MARK: Selected day section

  @ViewBuilder
  private var selectedDaySection: some View {
    if let selected = selectedDate {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .bottom) {
          dayHeaderLabel(selected)
          Spacer()
          if !selectedDayEntries.isEmpty {
            Text("\(selectedDayEntries.count)")
              .font(.caption2.weight(.bold))
              .foregroundStyle(AppTheme.textPrimary)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background {
                Capsule().fill(AppTheme.adorationPurple.opacity(0.35))
              }
          }
        }

        VStack(spacing: 8) {
          if selectedDayEntries.isEmpty {
            emptyDayState
          } else {
            ForEach(selectedDayEntries) { entry in
              NavigationLink {
                PrayerEntryDetailView(entry: entry)
              } label: {
                JournalEntryRow(entry: entry)
              }
              .buttonStyle(.plain)
              .contextMenu {
                Button(role: .destructive) {
                  modelContext.delete(entry)
                } label: {
                  Label("common.delete", systemImage: "trash")
                }
              }
            }
          }
        }
        .id(selected)
        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: selected)
      }
    }
  }

  @ViewBuilder
  private func dayHeaderLabel(_ date: Date) -> some View {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      Text(String(localized: "date.today").uppercased())
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.thanksgivingGold)
        .tracking(1.0)
    } else if calendar.isDateInYesterday(date) {
      Text(String(localized: "date.yesterday").uppercased())
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.textTertiary)
        .tracking(1.0)
    } else {
      VStack(alignment: .leading, spacing: 2) {
        Text(date.formatted(.dateTime.weekday(.wide)).uppercased())
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
          .tracking(1.0)
        Text(date.formatted(.dateTime.day().month(.wide).year()))
          .font(.system(.callout, design: .serif, weight: .medium))
          .foregroundStyle(AppTheme.textPrimary)
      }
    }
  }

  // MARK: Search panel (recent + results)

  @ViewBuilder
  private var searchPanelSection: some View {
    if searchText.isEmpty {
      recentEntriesSection
    } else {
      searchResultsSection
    }
  }

  @ViewBuilder
  private var recentEntriesSection: some View {
    let recent = recentResults
    VStack(alignment: .leading, spacing: 20) {
      Text("journal.search.recent.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(1.0)
      if recent.isEmpty {
        HStack(spacing: 14) {
          Image(systemName: "moon.stars")
            .font(.title3)
            .foregroundStyle(AppTheme.textTertiary)
          Text("journal.empty.message")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
          Spacer()
        }
        .padding(16)
        .background {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(AppTheme.cardFill)
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
            }
        }
      } else {
        ForEach(recent, id: \.date) { group in
          VStack(alignment: .leading, spacing: 10) {
            Text(searchDayLabel(group.date))
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.textTertiary)
              .textCase(.uppercase)
              .tracking(1.0)
            ForEach(group.entries) { entry in
              NavigationLink {
                PrayerEntryDetailView(entry: entry)
              } label: {
                JournalEntryRow(entry: entry)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }

  private var recentResults: [(date: Date, entries: [PrayerEntry])] {
    let recent = Array(entries.prefix(10))
    let grouped = Dictionary(grouping: recent) {
      Calendar.current.startOfDay(for: $0.date)
    }
    return
      grouped
      .sorted { $0.key > $1.key }
      .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
  }

  // MARK: Search results

  @ViewBuilder
  private var searchResultsSection: some View {
    let results = aiResults ?? cachedSearchResults
    VStack(alignment: .leading, spacing: 16) {
      if tipService.hasAIFeature {
        aiSearchButton
      }
      if results.isEmpty {
        searchEmptyState
      } else {
        ForEach(results, id: \.date) { group in
          VStack(alignment: .leading, spacing: 10) {
            Text(searchDayLabel(group.date))
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.textTertiary)
              .textCase(.uppercase)
              .tracking(1.0)
            ForEach(group.entries) { entry in
              NavigationLink {
                PrayerEntryDetailView(entry: entry)
              } label: {
                JournalEntryRow(entry: entry)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }

  private var aiSearchButton: some View {
    Button {
      Task { await runSemanticSearch() }
    } label: {
      HStack(spacing: 8) {
        if isAISearching {
          ProgressView().scaleEffect(0.8).tint(AppTheme.adorationPurple)
        } else {
          Image(systemName: aiResults == nil ? "sparkles" : "checkmark")
            .font(.caption.weight(.semibold))
        }
        Text(aiResults == nil ? "journal.search.ai" : "journal.search.ai.active")
          .font(.caption.weight(.semibold))
      }
      .foregroundStyle(AppTheme.adorationPurple)
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background(
        AppTheme.adorationPurple.opacity(0.1),
        in: Capsule()
      )
    }
    .buttonStyle(.plain)
    .disabled(isAISearching || searchText.isEmpty)
  }

  private var searchEmptyState: some View {
    HStack(spacing: 14) {
      Image(systemName: "magnifyingglass")
        .font(.title3)
        .foregroundStyle(AppTheme.textTertiary)
      Text("journal.search.empty")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textTertiary)
      Spacer()
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  private func runSemanticSearch() async {
    let query = searchText
    guard !query.isEmpty else { return }
    isAISearching = true
    defer { isAISearching = false }
    let matches = (try? await AIAssistantService.shared.searchEntries(matching: query, in: entries))
    guard let matches else { return }
    let grouped = Dictionary(grouping: matches) {
      Calendar.current.startOfDay(for: $0.date)
    }
    aiResults =
      grouped
      .sorted { $0.key > $1.key }
      .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
  }

  private func searchDayLabel(_ date: Date) -> String {
    let raw = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    return raw.prefix(1).uppercased() + raw.dropFirst()
  }

  // MARK: Empty state

  private var emptyDayState: some View {
    HStack(spacing: 14) {
      Image(systemName: "moon.stars")
        .font(.title3)
        .foregroundStyle(AppTheme.textTertiary)
      Text("journal.empty.message")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textTertiary)
      Spacer()
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  // MARK: Computed helpers

  private var aiButtonVisible: Bool {
    entries.lazy.filter({ !$0.text.isEmpty }).prefix(3).count >= 3
  }

  private var currentMonthEntries: [PrayerEntry] {
    entries.filter {
      !$0.text.isEmpty
        && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
    }
  }

  private var selectedDayEntries: [PrayerEntry] {
    guard let selected = selectedDate else { return [] }
    return entriesForDate(selected)
  }

  private var monthYearLabel: String {
    let s = Self.monthFormatter.string(from: displayedMonth)
    return s.prefix(1).uppercased() + s.dropFirst()
  }

  private var calendarDays: [Date?] {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: displayedMonth)
    let daysFromMonday = (weekday + 5) % 7
    guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
    var days: [Date?] = Array(repeating: nil, count: daysFromMonday)
    for day in 0..<range.count {
      if let date = calendar.date(byAdding: .day, value: day, to: displayedMonth) {
        days.append(date)
      }
    }
    while days.count % 7 != 0 { days.append(nil) }
    return days
  }

  private var prayedDaysInMonth: [Date: Int] {
    let calendar = Calendar.current
    return
      entries
      .filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
      .reduce(into: [Date: Int]()) { result, entry in
        let day = calendar.startOfDay(for: entry.date)
        result[day, default: 0] += 1
      }
  }

  private var isCurrentMonth: Bool {
    Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
  }

  private func monthInsightText(dayCount: Int) -> String {
    if dayCount == 0 { return String(localized: "journal.month.prayed.none") }
    return String(format: String(localized: "journal.month.prayed.days"), dayCount)
  }

  private func goToCurrentMonth() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      displayedMonth = Self.firstOfCurrentMonth()
      selectedDate = Calendar.current.startOfDay(for: Date())
    }
  }

  private func entriesForDate(_ date: Date) -> [PrayerEntry] {
    let calendar = Calendar.current
    let target = calendar.startOfDay(for: date)
    return
      entries
      .filter { calendar.startOfDay(for: $0.date) == target }
      .sorted { $0.date < $1.date }
  }

  private func navigateMonth(by offset: Int) {
    guard let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth)
    else { return }
    displayedMonth = newMonth
    selectedDate = nil
  }
}

// MARK: Monthly recap section

private struct MonthlyRecapSection: View {
  let entries: [PrayerEntry]

  @State private var recap: MonthlyRecap?
  @State private var isGenerating = false

  var body: some View {
    if entries.count >= 2 {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
          Image(systemName: "calendar")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.thanksgivingGold)
          Text("insight.recap.title")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(1.0)
        }

        Group {
          if let recap {
            recapCard(recap)
          } else if isGenerating {
            loadingCard
          }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: recap == nil)
      }
      .task {
        guard recap == nil, !isGenerating else { return }
        isGenerating = true
        recap = try? await AIAssistantService.shared.monthlyRecap(entries: entries)
        isGenerating = false
      }
    }
  }

  private func recapCard(_ recap: MonthlyRecap) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(recap.narrative)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textPrimary)
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)

      if !recap.themes.isEmpty {
        FlowChips(items: recap.themes)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.thanksgivingGold.opacity(0.2), lineWidth: 1)
        }
    }
  }

  private var loadingCard: some View {
    HStack(spacing: 14) {
      ProgressView()
        .scaleEffect(0.85)
        .tint(AppTheme.thanksgivingGold)
      Text("insight.loading")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
      Spacer()
    }
    .padding(14)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }
}

// Simple wrapping chips layout for theme tags.
private struct FlowChips: View {
  let items: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(items, id: \.self) { item in
        Text(item)
          .font(.caption.weight(.medium))
          .foregroundStyle(AppTheme.thanksgivingGold)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(AppTheme.thanksgivingGold.opacity(0.12), in: Capsule())
      }
    }
  }
}

// MARK: AI insight section

private struct JournalAIInsightSection: View {
  let entries: [PrayerEntry]

  @State private var insight: JournalInsight?
  @State private var isGenerating = false
  @State private var failed = false
  @State private var actionToken = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader
      Group {
        if isGenerating {
          loadingCard
        } else if let insight {
          insightCards(insight)
        } else if failed {
          errorCard
        } else {
          generateCard
        }
      }
      .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isGenerating)
      .animation(.spring(response: 0.4, dampingFraction: 0.85), value: insight == nil)
      .animation(.spring(response: 0.4, dampingFraction: 0.85), value: failed)
    }
    .sensoryFeedback(.success, trigger: insight != nil && !isGenerating)
    .task {
      guard insight == nil && !isGenerating else { return }
      await generate()
    }
  }

  // MARK: Header

  private var sectionHeader: some View {
    HStack(spacing: 6) {
      Image(systemName: "sparkles")
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.adorationPurple)
      Text("insight.section.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(1.0)
      Spacer()
      if insight != nil && !isGenerating {
        Button {
          actionToken.toggle()
          Task { await generate() }
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.caption)
            .foregroundStyle(AppTheme.textTertiary)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: actionToken)
      }
    }
  }

  // MARK: Generate CTA

  private var generateCard: some View {
    Button {
      actionToken.toggle()
      Task { await generate() }
    } label: {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .fill(AppTheme.adorationPurple.opacity(0.12))
            .frame(width: 38, height: 38)
          Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppTheme.adorationPurple)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text("insight.generate.title")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
          Text("insight.generate.subtitle")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
      }
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(AppTheme.cardFill)
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(AppTheme.adorationPurple.opacity(0.2), lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: actionToken)
  }

  // MARK: Loading

  private var loadingCard: some View {
    HStack(spacing: 14) {
      ProgressView()
        .scaleEffect(0.85)
        .tint(AppTheme.adorationPurple)
      Text("insight.loading")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
      Spacer()
    }
    .padding(14)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  // MARK: Insight content

  @ViewBuilder
  private func insightCards(_ data: JournalInsight) -> some View {
    VStack(spacing: 10) {
      if !data.themes.isEmpty {
        insightGroup(
          title: String(localized: "insight.themes.title"),
          icon: "tag.fill",
          color: AppTheme.confessionBlue,
          items: data.themes
        )
      }
      if !data.observations.isEmpty {
        insightGroup(
          title: String(localized: "insight.observations.title"),
          icon: "eye.fill",
          color: AppTheme.adorationPurple,
          items: data.observations
        )
      }
      if !data.answeredPrayers.isEmpty {
        insightGroup(
          title: String(localized: "insight.answered.title"),
          icon: "checkmark.seal.fill",
          color: AppTheme.thanksgivingGold,
          items: data.answeredPrayers
        )
      }
      Text("insight.ai.footer")
        .font(.caption2)
        .foregroundStyle(AppTheme.textTertiary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
  }

  private func insightGroup(title: String, icon: String, color: Color, items: [String]) -> some View
  {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.caption)
          .foregroundStyle(color)
        Text(title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
          .textCase(.uppercase)
          .tracking(0.8)
      }
      VStack(alignment: .leading, spacing: 8) {
        ForEach(items, id: \.self) { item in
          HStack(alignment: .top, spacing: 10) {
            Circle()
              .fill(color.opacity(0.6))
              .frame(width: 5, height: 5)
              .padding(.top, 7)
            Text(item)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textPrimary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(color.opacity(0.2), lineWidth: 1)
        }
    }
  }

  // MARK: Error

  private var currentAvailability: SystemLanguageModel.Availability {
    SystemLanguageModel.default.availability
  }

  private var errorCard: some View {
    let isNotEnabled =
      currentAvailability == .unavailable(.appleIntelligenceNotEnabled)
    let isDeviceIneligible =
      currentAvailability == .unavailable(.deviceNotEligible)
    let isModelNotReady =
      currentAvailability == .unavailable(.modelNotReady)

    return VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 14) {
        Image(systemName: isDeviceIneligible ? "sparkles.slash" : "apple.intelligence")
          .font(.callout)
          .foregroundStyle(AppTheme.textTertiary)
        VStack(alignment: .leading, spacing: 2) {
          Text("insight.error.title")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
          Text(
            isNotEnabled
              ? String(localized: "insight.error.subtitle.not.enabled")
              : isModelNotReady
                ? String(localized: "insight.error.subtitle.model.not.ready")
                : isDeviceIneligible
                  ? String(localized: "insight.error.subtitle")
                  : String(localized: "insight.error.subtitle.generic")
          )
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
        }
        Spacer()
        if !isDeviceIneligible {
          Button {
            actionToken.toggle()
            Task { await generate() }
          } label: {
            Image(systemName: "arrow.clockwise")
              .font(.callout)
              .foregroundStyle(AppTheme.adorationPurple)
          }
          .buttonStyle(.plain)
          .sensoryFeedback(.selection, trigger: actionToken)
        }
      }
      if isNotEnabled {
        Button {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        } label: {
          Text("insight.error.open.settings")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.adorationPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
              AppTheme.adorationPurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(14)
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  // MARK: Generation

  private func generate() async {
    let withText = entries.filter { !$0.text.isEmpty }
    guard withText.count >= 3 else { return }
    isGenerating = true
    insight = nil
    failed = false
    defer { isGenerating = false }
    do {
      insight = try await AIAssistantService.shared.analyzeJournal(entries: withText)
    } catch {
      failed = true
    }
  }
}

// MARK: Entry row

struct JournalEntryRow: View {
  let entry: PrayerEntry
  private var stepColor: Color { AppTheme.color(for: entry.stepColorName) }

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }

      Rectangle()
        .fill(stepColor)
        .frame(width: 3)

      HStack(spacing: 12) {
        Image(systemName: entry.stepIcon)
          .font(.callout)
          .foregroundStyle(stepColor)
          .frame(width: 36, height: 36)
          .background(stepColor.opacity(0.15))
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(entry.stepTitle)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.textPrimary)
            if entry.isAnswered {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.supplicationGreen)
            }
            Spacer()
            Text(entry.date, format: .dateTime.hour().minute())
              .font(.system(.caption2, design: .serif))
              .foregroundStyle(AppTheme.textTertiary)
          }
          if entry.text.isEmpty {
            Text("journal.entry.no.text")
              .font(.subheadline)
              .foregroundStyle(AppTheme.textTertiary)
              .italic()
          } else {
            Text(entry.text)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textSecondary)
              .lineLimit(2)
          }
        }
      }
      .padding(.leading, 17)
      .padding(.trailing, 14)
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

// swiftlint:disable force_try
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: PrayerEntry.self, configurations: config)

  let calendar = Calendar.current
  let today = Date()
  guard
    let lastMonth = calendar.date(byAdding: .month, value: -1, to: today),
    let firstOfLastMonth = calendar.date(
      from: calendar.dateComponents([.year, .month], from: lastMonth)
    ),
    let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfLastMonth)?.count
  else { fatalError() }

  let steps = PrayerStep.defaultSteps
  let sampleTexts = [
    "Seigneur, je te loue pour ta grandeur et ta bonté infinie.",
    "Pardonne-moi pour mes manquements d'aujourd'hui.",
    "Merci pour cette belle journée et les personnes que tu mets sur ma route.",
    "Je te confie mes inquiétudes et mes proches dans le besoin.",
    "",
  ]

  for day in 0..<daysInMonth {
    guard let date = calendar.date(byAdding: .day, value: day, to: firstOfLastMonth) else {
      continue
    }
    let stepCount = Int.random(in: 1...4)
    let shuffled = steps.shuffled().prefix(stepCount)
    for (i, step) in shuffled.enumerated() {
      let hour = 7 + i * 2
      let entryDate =
        calendar.date(
          bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) ?? date
      let text = sampleTexts.randomElement() ?? ""
      let entry = PrayerEntry(
        stepTitle: step.title,
        stepIcon: step.icon,
        stepColorName: step.colorName,
        text: text,
        date: entryDate
      )
      if step.colorName == "supplicationGreen" && Bool.random() {
        entry.isAnswered = true
        entry.answeredAt = entryDate
      }
      container.mainContext.insert(entry)
    }
  }

  return PrayerHistoryView()
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
// swiftlint:enable force_try
