package com.matthiascadet.holyday.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import java.text.DateFormatSymbols
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.TextStyle
import java.util.Locale

private val ZONE = ZoneId.systemDefault()

/** Équivalent de `PrayerHistoryView` iOS : calendrier + prières du jour + recherche. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayerHistoryScreen(onOpenEntry: (String) -> Unit, onOpenStats: () -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).prayerEntryDao() }
    val entries by dao.observeAll().collectAsState(initial = emptyList())

    var displayedMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(LocalDate.now()) }
    var isSearching by remember { mutableStateOf(false) }
    var searchText by remember { mutableStateOf("") }

    val entriesByDay = remember(entries) {
        entries.groupBy { Instant.ofEpochMilli(it.date).atZone(ZONE).toLocalDate() }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.tab_journal), color = AppTheme.colors.textPrimary) },
                actions = {
                    IconButton(onClick = onOpenStats) {
                        Icon(Icons.Filled.BarChart, contentDescription = stringResource(R.string.accessibility_stats_button), tint = AppTheme.colors.textPrimary)
                    }
                    IconButton(onClick = { isSearching = !isSearching; if (!isSearching) searchText = "" }) {
                        Icon(
                            if (isSearching) Icons.Filled.Close else Icons.Filled.Search,
                            contentDescription = stringResource(if (isSearching) R.string.accessibility_search_close else R.string.accessibility_search_open),
                            tint = AppTheme.colors.textPrimary,
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            AppBackground()
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                if (isSearching) {
                    OutlinedTextField(
                        value = searchText,
                        onValueChange = { searchText = it },
                        placeholder = { Text(stringResource(R.string.journal_search_placeholder)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                    SearchResults(entries, searchText, onOpenEntry)
                } else {
                    CalendarCard(
                        displayedMonth = displayedMonth,
                        selectedDate = selectedDate,
                        entriesByDay = entriesByDay,
                        onMonthChange = { displayedMonth = it },
                        onSelectDate = { selectedDate = it },
                    )
                    SelectedDaySection(selectedDate, entriesByDay, onOpenEntry)
                }
            }
        }
    }
}

@Composable
private fun SearchResults(entries: List<PrayerEntryEntity>, query: String, onOpenEntry: (String) -> Unit) {
    val matched = remember(entries, query) {
        if (query.isBlank()) emptyList()
        else entries.filter { it.text.contains(query, ignoreCase = true) || it.displayTitle.contains(query, ignoreCase = true) }
    }
    if (query.isBlank()) return
    if (matched.isEmpty()) {
        EmptyCard(stringResource(R.string.journal_search_empty))
        return
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        matched.forEach { entry -> JournalEntryRow(entry, onClick = { onOpenEntry(entry.id) }) }
    }
}

@Composable
private fun CalendarCard(
    displayedMonth: YearMonth,
    selectedDate: LocalDate?,
    entriesByDay: Map<LocalDate, List<PrayerEntryEntity>>,
    onMonthChange: (YearMonth) -> Unit,
    onSelectDate: (LocalDate) -> Unit,
) {
    val prayedCounts = entriesByDay.filterKeys { YearMonth.from(it) == displayedMonth }.mapValues { it.value.size }
    val monthLabel = displayedMonth.month.getDisplayName(TextStyle.FULL, Locale.getDefault()).replaceFirstChar { it.uppercase() } + " " + displayedMonth.year

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(AppTheme.colors.cardSurface)
            .border(1.dp, AppTheme.colors.cardStroke, RoundedCornerShape(20.dp))
            .padding(vertical = 12.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = { onMonthChange(displayedMonth.minusMonths(1)) }) {
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = null, tint = AppTheme.colors.textSecondary)
            }
            Text(monthLabel, style = MaterialTheme.typography.titleSmall, color = AppTheme.colors.textPrimary)
            IconButton(onClick = { onMonthChange(displayedMonth.plusMonths(1)) }) {
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = AppTheme.colors.textSecondary)
            }
        }

        val monthCount = prayedCounts.size
        Text(
            text = if (monthCount == 0) stringResource(R.string.journal_month_prayed_none) else stringResource(R.string.journal_month_prayed_days, monthCount),
            style = MaterialTheme.typography.labelSmall,
            color = AppTheme.colors.textTertiary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
        )

        val weekdayLabels = remember { stringArrayOfWeekdays() }
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)) {
            weekdayLabels.forEach { label ->
                Text(label, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center, style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary)
            }
        }

        val firstOfMonth = displayedMonth.atDay(1)
        val leading = (firstOfMonth.dayOfWeek.value + 6) % 7 // lundi = 0
        val daysInMonth = displayedMonth.lengthOfMonth()
        val cells = buildList<LocalDate?> {
            repeat(leading) { add(null) }
            for (day in 1..daysInMonth) add(displayedMonth.atDay(day))
            while (size % 7 != 0) add(null)
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp).size(((cells.size / 7) * 48).dp),
        ) {
            items(cells) { date ->
                if (date == null) {
                    Box(Modifier.aspectRatio(1f))
                } else {
                    DayCell(
                        date = date,
                        isSelected = selectedDate == date,
                        count = prayedCounts[date] ?: 0,
                        onClick = { onSelectDate(date) },
                    )
                }
            }
        }
    }
}

@Composable
private fun DayCell(date: LocalDate, isSelected: Boolean, count: Int, onClick: () -> Unit) {
    val isToday = date == LocalDate.now()
    val isFuture = date.isAfter(LocalDate.now())
    Column(
        modifier = Modifier
            .aspectRatio(1f)
            .clickable(enabled = !isFuture, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(if (isSelected) AppTheme.colors.adorationPurple else androidx.compose.ui.graphics.Color.Transparent)
                .border(if (isToday && !isSelected) 1.5.dp else 0.dp, AppTheme.colors.thanksgivingGold.copy(alpha = 0.7f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                date.dayOfMonth.toString(),
                color = if (isSelected) androidx.compose.ui.graphics.Color.White else if (isFuture) AppTheme.colors.textTertiary else AppTheme.colors.textPrimary,
                style = MaterialTheme.typography.bodySmall,
            )
        }
        Box(
            modifier = Modifier
                .padding(top = 2.dp)
                .size(4.dp)
                .clip(CircleShape)
                .background(if (count > 0) AppTheme.colors.thanksgivingGold.copy(alpha = 0.3f + 0.7f * minOf(count, 3) / 3f) else androidx.compose.ui.graphics.Color.Transparent),
        )
    }
}

@Composable
private fun SelectedDaySection(
    selectedDate: LocalDate?,
    entriesByDay: Map<LocalDate, List<PrayerEntryEntity>>,
    onOpenEntry: (String) -> Unit,
) {
    if (selectedDate == null) return
    val dayEntries = (entriesByDay[selectedDate] ?: emptyList()).sortedBy { it.date }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(dayHeaderLabel(selectedDate), style = MaterialTheme.typography.labelMedium, color = AppTheme.colors.textTertiary)

        if (dayEntries.isEmpty()) {
            EmptyCard(stringResource(R.string.journal_empty_message))
        } else {
            val guided = dayEntries.filter { !it.isFreePrayer }.reversed()
            val free = dayEntries.filter { it.isFreePrayer }.reversed()
            if (guided.isNotEmpty()) {
                PrayerDeck(stringResource(R.string.journal_deck_guided_title), guided, onOpenEntry)
            }
            if (free.isNotEmpty()) {
                PrayerDeck(stringResource(R.string.journal_deck_free_title), free, onOpenEntry)
            }
        }
    }
}

@Composable
private fun dayHeaderLabel(date: LocalDate): String {
    val today = LocalDate.now()
    return when (date) {
        today -> stringResource(R.string.date_today)
        today.minusDays(1) -> stringResource(R.string.date_yesterday)
        else -> date.dayOfWeek.getDisplayName(TextStyle.FULL, Locale.getDefault()).replaceFirstChar { it.uppercase() } + " " + date.dayOfMonth + " " + date.month.getDisplayName(TextStyle.FULL, Locale.getDefault())
    }
}

@Composable
private fun PrayerDeck(title: String, entries: List<PrayerEntryEntity>, onOpenEntry: (String) -> Unit) {
    var isExpanded by remember { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth().clickable { isExpanded = !isExpanded },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(title.uppercase(), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary)
            Text("${entries.size}", style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textPrimary)
        }
        if (isExpanded) {
            entries.forEach { entry -> JournalEntryRow(entry, onClick = { onOpenEntry(entry.id) }) }
        } else {
            entries.firstOrNull()?.let { JournalEntryRow(it, onClick = { isExpanded = true }) }
        }
    }
}

@Composable
fun JournalEntryRow(entry: PrayerEntryEntity, onClick: () -> Unit) {
    val accent = entry.emotion?.pastel ?: AppTheme.colorFor(entry.stepColorName)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(AppTheme.colors.cardSurface)
            .border(1.dp, AppTheme.colors.cardStroke, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(modifier = Modifier.size(6.dp).clip(CircleShape).background(accent))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                entry.displayTitle,
                style = MaterialTheme.typography.bodyMedium,
                color = AppTheme.colors.textPrimary,
                textDecoration = if (entry.isAnswered) TextDecoration.None else null,
            )
            Text(
                text = entry.text.ifEmpty { stringResource(R.string.journal_entry_no_text) },
                style = MaterialTheme.typography.bodySmall,
                color = AppTheme.colors.textSecondary,
                maxLines = 2,
            )
        }
    }
}

@Composable
private fun EmptyCard(text: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(AppTheme.colors.cardSurface)
            .padding(16.dp),
    ) {
        Text(text, color = AppTheme.colors.textTertiary)
    }
}

private fun stringArrayOfWeekdays(): List<String> {
    val symbols = DateFormatSymbols.getInstance(Locale.getDefault())
    val order = listOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY, DayOfWeek.SUNDAY)
    return order.map { it.getDisplayName(TextStyle.NARROW, Locale.getDefault()).uppercase() }
}
