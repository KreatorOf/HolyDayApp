package com.matthiascadet.holyday.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.TitleSource
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.launch
import java.text.DateFormat
import java.util.Date

/** Équivalent de `PrayerEntryDetailView` iOS. */
@Composable
fun PrayerEntryDetailScreen(entryId: String, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).prayerEntryDao() }
    val scope = rememberCoroutineScope()
    val entries by dao.observeAll().collectAsState(initial = emptyList())
    val entry = entries.find { it.id == entryId } ?: return

    var titleDraft by remember(entry.id) { mutableStateOf(entry.displayTitle) }
    val accent = entry.emotion?.pastel ?: AppTheme.colorFor(entry.stepColorName)

    Scaffold { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            AppBackground()
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Box(
                        modifier = Modifier.size(50.dp).clip(CircleShape).background(accent.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(entry.emotion?.icon ?: androidx.compose.material.icons.Icons.Filled.Check, contentDescription = null, tint = accent)
                    }
                    Column {
                        if (entry.isFreePrayer) {
                            OutlinedTextField(
                                value = titleDraft,
                                onValueChange = { titleDraft = it },
                                textStyle = MaterialTheme.typography.titleMedium,
                                placeholder = { Text(stringResource(R.string.entry_title_placeholder)) },
                                modifier = Modifier.fillMaxWidth(),
                            )
                        } else {
                            Text(entry.stepTitle, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary)
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            if (entry.titleSource == TitleSource.AI) {
                                Text(stringResource(R.string.entry_title_suggested) + " ·", style = MaterialTheme.typography.bodySmall, color = AppTheme.colors.textSecondary)
                            }
                            Text(
                                DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.SHORT).format(Date(entry.date)),
                                style = MaterialTheme.typography.bodySmall,
                                color = AppTheme.colors.textSecondary,
                            )
                        }
                    }
                }

                if (entry.text.isEmpty()) {
                    Text(stringResource(R.string.entry_no_text), fontStyle = FontStyle.Italic, color = AppTheme.colors.textSecondary)
                } else {
                    Text(entry.text, color = AppTheme.colors.textPrimary)
                }

                if (entry.stepColorName == "supplicationGreen") {
                    Button(
                        onClick = {
                            scope.launch {
                                dao.update(
                                    entry.copy(
                                        isAnswered = !entry.isAnswered,
                                        answeredAt = if (!entry.isAnswered) System.currentTimeMillis() else null,
                                    ),
                                )
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (entry.isAnswered) AppTheme.colors.supplicationGreen else AppTheme.colors.supplicationGreen.copy(alpha = 0.12f),
                            contentColor = if (entry.isAnswered) androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.7f) else AppTheme.colors.supplicationGreen,
                        ),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(stringResource(if (entry.isAnswered) R.string.entry_answered_label else R.string.entry_mark_answered_label))
                    }
                }

                if (entry.isFreePrayer) {
                    Button(
                        onClick = {
                            val trimmed = titleDraft.trim()
                            if (trimmed.isNotEmpty() && trimmed != entry.customTitle) {
                                scope.launch { dao.update(entry.copy(customTitle = trimmed, titleSourceRaw = TitleSource.USER.name)) }
                            }
                            onDismiss()
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(stringResource(R.string.common_close)) }
                }
            }
        }
    }
}
