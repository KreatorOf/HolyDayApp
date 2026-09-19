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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.service.TourService
import com.matthiascadet.holyday.ui.common.TourTip
import com.matthiascadet.holyday.ui.common.TourTipPlacement
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softSurface
import com.matthiascadet.holyday.ui.theme.softTextFieldColors
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
    val tourStep by TourService.step.collectAsState()

    var displayedMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(LocalDate.now()) }
    var isSearching by remember { mutableStateOf(false) }
    var searchText by remember { mutableStateOf("") }
    val searchFocusRequester = remember { FocusRequester() }

    val entriesByDay = remember(entries) {
        entries.groupBy { Instant.ofEpochMilli(it.date).atZone(ZONE).toLocalDate() }
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(AppTheme.colors.backgroundPrimary),
    ) {
        Scaffold(
            containerColor = androidx.compose.ui.graphics.Color.Transparent,
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            stringResource(R.string.tab_journal),
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                            color = AppTheme.colors.textPrimary,
                        )
                    },
                    actions = {
                        JournalTopBarAction(
                            onClick = onOpenStats,
                            icon = Icons.Filled.BarChart,
                            contentDescription = stringResource(R.string.accessibility_stats_button),
                        )
                        JournalTopBarAction(
                            onClick = { isSearching = !isSearching; if (!isSearching) searchText = "" },
                            icon = if (isSearching) Icons.Filled.Close else Icons.Filled.Search,
                            contentDescription = stringResource(
                                if (isSearching) R.string.accessibility_search_close else R.string.accessibility_search_open,
                            ),
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
                )
            },
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                Column(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .fillMaxWidth()
                    .widthIn(max = 720.dp)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                if (isSearching) {
                    OutlinedTextField(
                        value = searchText,
                        onValueChange = { searchText = it },
                        placeholder = { Text(stringResource(R.string.journal_search_placeholder)) },
                        leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                        trailingIcon = {
                            if (searchText.isNotEmpty()) {
                                IconButton(onClick = { searchText = "" }) {
                                    Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.accessibility_search_clear))
                                }
                            }
                        },
                        singleLine = true,
                        shape = RoundedCornerShape(28.dp),
                        colors = softTextFieldColors(),
                        modifier = Modifier.fillMaxWidth().focusRequester(searchFocusRequester),
                    )
                    LaunchedEffect(Unit) { searchFocusRequester.requestFocus() }
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

    if (tourStep == TourService.Step.JOURNAL) {
        TourTip(step = tourStep, placement = TourTipPlacement.BOTTOM, onDismiss = { TourService.dismiss(tourStep) })
    }
}

@Composable
private fun JournalTopBarAction(
    onClick: () -> Unit,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    contentDescription: String,
) {
    Surface(
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        tonalElevation = 2.dp,
    ) {
        IconButton(onClick = onClick, modifier = Modifier.size(48.dp)) {
            Icon(icon, contentDescription = contentDescription, tint = AppTheme.colors.textPrimary)
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
            .softSurface(
                shape = MaterialTheme.shapes.large,
                tint = AppTheme.colors.cardSurface,
                borderColor = AppTheme.colors.cardStroke,
                elevation = 2.dp,
            )
            .padding(vertical = 12.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = { onMonthChange(displayedMonth.minusMonths(1)) }) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = stringResource(R.string.accessibility_previous_month),
                    tint = AppTheme.colors.textSecondary,
                )
            }
            Text(monthLabel, style = MaterialTheme.typography.titleSmall, color = AppTheme.colors.textPrimary)
            IconButton(onClick = { onMonthChange(displayedMonth.plusMonths(1)) }) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = stringResource(R.string.accessibility_next_month),
                    tint = AppTheme.colors.textSecondary,
                )
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
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp).height(((cells.size / 7) * 50).dp),
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
    val dayCircleModifier = Modifier
        .size(32.dp)
        .clip(CircleShape)
        .background(if (isSelected) AppTheme.colors.adorationPurple else androidx.compose.ui.graphics.Color.Transparent)
        .then(
            if (isToday && !isSelected) {
                Modifier.border(1.5.dp, AppTheme.colors.adorationPurple.copy(alpha = 0.7f), CircleShape)
            } else {
                Modifier
            },
        )
    Column(
        modifier = Modifier
            .aspectRatio(1f)
            .clickable(enabled = !isFuture, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = dayCircleModifier,
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
                .size(if (count > 1) 6.dp else 4.dp)
                .clip(CircleShape)
                .background(if (count > 0) AppTheme.colors.adorationPurple.copy(alpha = 0.35f + 0.65f * minOf(count, 3) / 3f) else androidx.compose.ui.graphics.Color.Transparent),
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
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(42.dp)
                .clip(CircleShape)
                .background(accent),
        )
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
            .padding(horizontal = 18.dp, vertical = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(Icons.AutoMirrored.Filled.MenuBook, contentDescription = null, tint = AppTheme.colors.adorationPurple.copy(alpha = 0.65f))
        Text(text, color = AppTheme.colors.textSecondary, style = MaterialTheme.typography.bodyMedium)
    }
}

private fun stringArrayOfWeekdays(): List<String> {
    val symbols = DateFormatSymbols.getInstance(Locale.getDefault())
    val order = listOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY, DayOfWeek.SUNDAY)
    return order.map { it.getDisplayName(TextStyle.NARROW, Locale.getDefault()).uppercase() }
}
