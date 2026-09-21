package com.matthiascadet.holyday.ui.prayer

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.data.db.PrayerStepIcon
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.service.notification.NotificationService
import com.matthiascadet.holyday.ui.common.HolyDayScaffold
import kotlinx.coroutines.launch

@Composable
fun EveningReviewScreen(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var emotion by remember { mutableStateOf<Emotion?>(null) }
    var gratitude by remember { mutableStateOf("") }
    var difficulty by remember { mutableStateOf("") }
    var tomorrow by remember { mutableStateOf("") }
    val canSave = gratitude.isNotBlank() || difficulty.isNotBlank() || tomorrow.isNotBlank()

    HolyDayScaffold(title = stringResource(R.string.evening_review_title), onBack = onDismiss) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(stringResource(R.string.evening_review_feeling), style = MaterialTheme.typography.titleMedium)
            Row(
                Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Emotion.entries.forEach { item ->
                    FilterChip(
                        selected = emotion == item,
                        onClick = { emotion = item },
                        label = { Text(stringResource(item.titleRes)) },
                    )
                }
            }
            ReviewField(R.string.evening_review_gratitude, gratitude) { gratitude = it }
            ReviewField(R.string.evening_review_difficulty, difficulty) { difficulty = it }
            ReviewField(R.string.evening_review_tomorrow, tomorrow) { tomorrow = it }
            Button(
                enabled = canSave,
                onClick = {
                    val labels = listOf(
                        context.getString(R.string.evening_review_gratitude) to gratitude,
                        context.getString(R.string.evening_review_difficulty) to difficulty,
                        context.getString(R.string.evening_review_tomorrow) to tomorrow,
                    )
                    val text = labels.filter { it.second.isNotBlank() }
                        .joinToString("\n\n") { "${it.first}\n${it.second.trim()}" }
                    scope.launch {
                        AppDatabase.getInstance(context).prayerEntryDao().upsert(
                            PrayerEntryEntity(
                                stepTitle = context.getString(R.string.evening_review_title),
                                stepIcon = PrayerStepIcon.EVENING_REVIEW,
                                stepColorName = "confessionBlue",
                                text = text,
                                date = System.currentTimeMillis(),
                                emotionRaw = emotion?.id,
                            ),
                        )
                        PrayerRecordService.recordPrayer()
                        NotificationService.refreshScheduledReminders(context)
                        WidgetSyncService.sync()
                        onDismiss()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            ) { Text(stringResource(R.string.evening_review_save)) }
        }
    }
}

@Composable
private fun ReviewField(labelRes: Int, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(stringResource(labelRes)) },
        placeholder = { Text(stringResource(R.string.evening_review_placeholder)) },
        minLines = 2,
        modifier = Modifier.fillMaxWidth(),
    )
}
