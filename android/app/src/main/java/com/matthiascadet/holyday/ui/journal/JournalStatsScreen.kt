package com.matthiascadet.holyday.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.model.PrayerStats
import com.matthiascadet.holyday.data.model.StatsBucket
import com.matthiascadet.holyday.data.model.StatsPeriod
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `JournalStatsView` iOS (Canvas custom au lieu de Swift Charts). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JournalStatsScreen(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).prayerEntryDao() }
    val entries by dao.observeAll().collectAsState(initial = emptyList())
    var period by remember { mutableStateOf(StatsPeriod.MONTH) }

    val activity = remember(entries, period) { PrayerStats.activity(entries, period) }
    val emotions = remember(entries, period) { PrayerStats.emotionTotals(entries, period) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.common_close)) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                PeriodChip(stringResource(R.string.stats_period_week), period == StatsPeriod.WEEK) { period = StatsPeriod.WEEK }
                PeriodChip(stringResource(R.string.stats_period_month), period == StatsPeriod.MONTH) { period = StatsPeriod.MONTH }
                PeriodChip(stringResource(R.string.stats_period_sixmonths), period == StatsPeriod.SIX_MONTHS) { period = StatsPeriod.SIX_MONTHS }
                PeriodChip(stringResource(R.string.stats_period_year), period == StatsPeriod.YEAR) { period = StatsPeriod.YEAR }
                PeriodChip(stringResource(R.string.stats_period_all), period == StatsPeriod.ALL) { period = StatsPeriod.ALL }
            }

            if (activity.isEmpty()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth().padding(top = 40.dp)) {
                    Text(stringResource(R.string.stats_empty_title), style = MaterialTheme.typography.titleMedium, color = AppTheme.colors.textPrimary)
                    Text(stringResource(R.string.stats_empty_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary)
                }
            } else {
                ChartCard(
                    title = stringResource(
                        when (period.bucket) {
                            StatsBucket.DAY -> R.string.stats_activity_daily
                            StatsBucket.WEEK -> R.string.stats_activity_weekly
                            StatsBucket.MONTH -> R.string.stats_activity_monthly
                        },
                    ),
                ) {
                    ActivityLineChart(points = activity, color = AppTheme.colors.adorationPurple)
                }

                if (emotions.isNotEmpty()) {
                    ChartCard(title = stringResource(R.string.stats_emotions_title)) {
                        EmotionsDonutChart(totals = emotions)
                        Column(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                            emotions.forEach { total ->
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Box(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(50))
                                            .background(total.emotion.pastel)
                                            .padding(6.dp),
                                    ) {}
                                    Text(stringResource(total.emotion.titleRes) + " (${total.count})", color = AppTheme.colors.textSecondary, style = MaterialTheme.typography.bodySmall)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PeriodChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(if (selected) AppTheme.colors.adorationPurple.copy(alpha = 0.3f) else AppTheme.colors.cardFill)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = if (selected) AppTheme.colors.textPrimary else AppTheme.colors.textSecondary)
    }
}

@Composable
private fun ChartCard(title: String, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AppTheme.colors.cardSurface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = AppTheme.colors.textPrimary)
        content()
    }
}
