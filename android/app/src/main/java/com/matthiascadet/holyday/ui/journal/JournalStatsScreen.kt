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
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import com.matthiascadet.holyday.ui.common.HolyDayScaffold
import com.matthiascadet.holyday.ui.theme.softSurface

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

    HolyDayScaffold(
        title = stringResource(R.string.accessibility_stats_button),
        onBack = onDismiss,
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            val periods = listOf(
                StatsPeriod.WEEK to stringResource(R.string.stats_period_week),
                StatsPeriod.MONTH to stringResource(R.string.stats_period_month),
                StatsPeriod.SIX_MONTHS to stringResource(R.string.stats_period_sixmonths),
                StatsPeriod.YEAR to stringResource(R.string.stats_period_year),
                StatsPeriod.ALL to stringResource(R.string.stats_period_all),
            )
            SingleChoiceSegmentedButtonRow(
                modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
            ) {
                periods.forEachIndexed { index, item ->
                    SegmentedButton(
                        selected = period == item.first,
                        onClick = { period = item.first },
                        shape = SegmentedButtonDefaults.itemShape(index, periods.size),
                        label = { Text(item.second) },
                    )
                }
            }

            if (activity.isEmpty()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth().padding(top = 40.dp)) {
                    Icon(
                        Icons.Filled.Insights,
                        contentDescription = null,
                        tint = AppTheme.colors.adorationPurple,
                        modifier = Modifier.padding(bottom = 16.dp),
                    )
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
private fun ChartCard(title: String, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .softSurface(
                shape = MaterialTheme.shapes.large,
                tint = AppTheme.colors.cardSurface,
                borderColor = AppTheme.colors.cardStroke,
                elevation = 2.dp,
            )
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = AppTheme.colors.textPrimary)
        content()
    }
}
