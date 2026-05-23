//
//  PrayerHistoryView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI
import SwiftData

struct PrayerHistoryView: View {
    @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var displayedMonth: Date = Self.firstOfCurrentMonth()
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
    @State private var showInsight = false
    @State private var topInset: CGFloat = 100
    @State private var showNavTitle = false
    @State private var searchText = ""
    @State private var isSearching = false

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
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                withAnimation(.easeInOut(duration: 0.2)) { showNavTitle = y > 80 }
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
                        if aiInsightAvailable {
                            Button { showInsight = true } label: {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(AppTheme.adorationPurple)
                            }
                        }
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSearching.toggle()
                                if !isSearching { searchText = "" }
                            }
                        } label: {
                            Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showInsight) {
                JournalInsightView()
            }
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
                .font(.system(size: 34, weight: .bold, design: .serif).italic())
                .foregroundStyle(AppTheme.textPrimary)
            if !isSearching {
                Text("journal.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
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
                        Button { searchText = "" } label: {
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
        VStack(spacing: 0) {
            monthNavigationHeader
            weekDayLabels
            calendarDayGrid
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

            Text(monthYearLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

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

    private var calendarDayGrid: some View {
        let prayedDays = prayedDaysInMonth
        return LazyVGrid(
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

    private func calendarDayView(_ date: Date, prayedDays: Set<Date>) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let startOfDay = calendar.startOfDay(for: date)
        let isSelected = selectedDate == startOfDay
        let hasPrayer = prayedDays.contains(startOfDay)
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
                            isSelected ? Color.white :
                            isFuture ? AppTheme.textTertiary : AppTheme.textPrimary
                        )
                }
                .frame(width: 34, height: 34)

                Circle()
                    .fill(hasPrayer ? (isSelected ? Color.white : AppTheme.thanksgivingGold) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .disabled(isFuture)
    }

    // MARK: Selected day section

    @ViewBuilder
    private var selectedDaySection: some View {
        if let selected = selectedDate {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(dayLabel(selected))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.0)

                    if !selectedDayEntries.isEmpty {
                        Text("\(selectedDayEntries.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background {
                                Capsule().fill(AppTheme.adorationPurple.opacity(0.4))
                            }
                    }
                }

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
        return grouped
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
    }

    // MARK: Search results

    @ViewBuilder
    private var searchResultsSection: some View {
        let results = searchResults
        if results.isEmpty {
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
        } else {
            VStack(alignment: .leading, spacing: 20) {
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

    private var searchResults: [(date: Date, entries: [PrayerEntry])] {
        guard !searchText.isEmpty else { return [] }
        let matched = entries.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            $0.stepTitle.localizedCaseInsensitiveContains(searchText)
        }
        let grouped = Dictionary(grouping: matched) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped
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

    private var aiInsightAvailable: Bool {
        entries.filter({ !$0.text.isEmpty }).count >= 3 && AIAssistantService.shared.isAvailable
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

    private var prayedDaysInMonth: Set<Date> {
        let calendar = Calendar.current
        return Set(entries
            .filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
            .map { calendar.startOfDay(for: $0.date) })
    }

    private func entriesForDate(_ date: Date) -> [PrayerEntry] {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return entries
            .filter { calendar.startOfDay(for: $0.date) == target }
            .sorted { $0.date < $1.date }
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return String(localized: "date.today") }
        if calendar.isDateInYesterday(date) { return String(localized: "date.yesterday") }
        return date.formatted(.dateTime.day().month(.wide).year())
    }

    private func navigateMonth(by offset: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        displayedMonth = newMonth
        selectedDate = nil
    }
}

// MARK: Entry row

struct JournalEntryRow: View {
    let entry: PrayerEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.stepIcon)
                .font(.callout)
                .foregroundStyle(AppTheme.color(for: entry.stepColorName))
                .frame(width: 36, height: 36)
                .background(AppTheme.color(for: entry.stepColorName).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
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
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                if entry.text.isEmpty {
                    Text("journal.entry.no.text")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .italic()
                } else {
                    Text(entry.text)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
                }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PrayerEntry.self, configurations: config)

    let calendar = Calendar.current
    let today = Date()
    guard let firstOfLastMonth = calendar.date(
        from: calendar.dateComponents([.year, .month],
        from: calendar.date(byAdding: .month, value: -1, to: today)!)
    ),
    let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfLastMonth)?.count
    else { fatalError() }

    let steps = PrayerStep.defaultSteps
    let sampleTexts = [
        "Seigneur, je te loue pour ta grandeur et ta bonté infinie.",
        "Pardonne-moi pour mes manquements d'aujourd'hui.",
        "Merci pour cette belle journée et les personnes que tu mets sur ma route.",
        "Je te confie mes inquiétudes et mes proches dans le besoin.",
        ""
    ]

    for day in 0..<daysInMonth {
        guard let date = calendar.date(byAdding: .day, value: day, to: firstOfLastMonth) else { continue }
        let stepCount = Int.random(in: 1...4)
        let shuffled = steps.shuffled().prefix(stepCount)
        for (i, step) in shuffled.enumerated() {
            let hour = 7 + i * 2
            let entryDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date)!
            let text = sampleTexts.randomElement()!
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
