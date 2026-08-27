package com.matthiascadet.holyday.ui.intentions

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerIntentionEntity
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softSurface
import com.matthiascadet.holyday.ui.theme.softTextFieldColors
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit

private enum class IntentionsSegment { ACTIVE, ANSWERED }

/** Équivalent de `IntentionsView` iOS : CRUD des sujets de prière avec bascule "exaucé". */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IntentionsScreen(onDismiss: () -> Unit, onOpenDetail: (String) -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).prayerIntentionDao() }
    val scope = rememberCoroutineScope()
    val intentions by dao.observeAll().collectAsState(initial = emptyList())

    var segment by remember { mutableStateOf(IntentionsSegment.ACTIVE) }
    var newText by remember { mutableStateOf("") }

    val active = intentions.filter { !it.isAnswered }
    val answered = intentions.filter { it.isAnswered }
    val shown = if (segment == IntentionsSegment.ACTIVE) active else answered

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.intentions_nav_title), color = AppTheme.colors.textPrimary) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.common_close))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            AppBackground()
            Column(Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    SegmentButton(
                        label = stringResource(R.string.intentions_segment_active) + " ${active.size}",
                        selected = segment == IntentionsSegment.ACTIVE,
                        onClick = { segment = IntentionsSegment.ACTIVE },
                        modifier = Modifier.weight(1f),
                    )
                    SegmentButton(
                        label = stringResource(R.string.intentions_section_answered) + " ${answered.size}",
                        selected = segment == IntentionsSegment.ANSWERED,
                        onClick = { segment = IntentionsSegment.ANSWERED },
                        modifier = Modifier.weight(1f),
                    )
                }

                if (shown.isEmpty()) {
                    Box(Modifier.fillMaxSize().weight(1f), contentAlignment = Alignment.Center) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.padding(horizontal = 32.dp),
                        ) {
                            Text(
                                stringResource(
                                    if (segment == IntentionsSegment.ACTIVE) R.string.intentions_empty_title else R.string.intentions_empty_answered_title,
                                ),
                                style = MaterialTheme.typography.titleMedium.copy(fontSize = 19.sp, lineHeight = 24.sp),
                                fontWeight = FontWeight.SemiBold,
                                color = AppTheme.colors.textPrimary,
                                textAlign = TextAlign.Center,
                            )
                            Text(
                                stringResource(
                                    if (segment == IntentionsSegment.ACTIVE) R.string.intentions_empty_subtitle else R.string.intentions_empty_answered_subtitle,
                                ),
                                style = MaterialTheme.typography.bodyLarge,
                                color = AppTheme.colors.textSecondary,
                                textAlign = TextAlign.Center,
                            )
                        }
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.weight(1f).fillMaxWidth(),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        items(shown, key = { it.id }) { intention ->
                            IntentionRow(intention, onClick = { onOpenDetail(intention.id) })
                        }
                    }
                }

                if (segment == IntentionsSegment.ACTIVE) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.Bottom,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        TextField(
                            value = newText,
                            onValueChange = { newText = it },
                            placeholder = { Text(stringResource(R.string.intentions_add_placeholder)) },
                            shape = RoundedCornerShape(20.dp),
                            colors = softTextFieldColors(),
                            modifier = Modifier.weight(1f),
                        )
                        val canSend = newText.trim().isNotEmpty()
                        IconButton(
                            enabled = canSend,
                            onClick = {
                                val trimmed = newText.trim()
                                if (trimmed.isNotEmpty()) {
                                    scope.launch { dao.upsert(PrayerIntentionEntity(text = trimmed, createdAt = System.currentTimeMillis())) }
                                    newText = ""
                                }
                            },
                        ) {
                            Icon(
                                Icons.Filled.ArrowUpward,
                                contentDescription = stringResource(R.string.intentions_suggest_add),
                                tint = if (canSend) AppTheme.colors.adorationPurple else AppTheme.colors.textTertiary,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SegmentButton(label: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(if (selected) AppTheme.colors.adorationPurple.copy(alpha = 0.35f) else AppTheme.colors.cardFill)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            color = if (selected) AppTheme.colors.textPrimary else AppTheme.colors.textSecondary,
        )
    }
}

@Composable
private fun IntentionRow(intention: PrayerIntentionEntity, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .softSurface(shape = RoundedCornerShape(24.dp), tint = AppTheme.colors.cardSurface, borderColor = AppTheme.colors.cardStroke)
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 16.dp),
    ) {
        Text(
            intention.text,
            style = MaterialTheme.typography.bodyLarge,
            color = if (intention.isAnswered) AppTheme.colors.textSecondary else AppTheme.colors.textPrimary,
            textDecoration = if (intention.isAnswered) TextDecoration.LineThrough else null,
        )
        Text(
            subtitleFor(intention),
            style = MaterialTheme.typography.labelMedium,
            color = if (intention.isAnswered) AppTheme.colors.supplicationGreen else AppTheme.colors.textTertiary,
        )
    }
}

@Composable
private fun subtitleFor(intention: PrayerIntentionEntity): String {
    if (intention.isAnswered && intention.answeredAt != null) {
        val zone = ZoneId.systemDefault()
        val date = Instant.ofEpochMilli(intention.answeredAt).atZone(zone).toLocalDate()
        return "${stringResource(R.string.intentions_answered_label)} · $date"
    }
    val zone = ZoneId.systemDefault()
    val days = ChronoUnit.DAYS.between(
        Instant.ofEpochMilli(intention.createdAt).atZone(zone).toLocalDate(),
        Instant.now().atZone(zone).toLocalDate(),
    )
    return when {
        days <= 0 -> stringResource(R.string.intentions_duration_today)
        days == 1L -> stringResource(R.string.intentions_duration_yesterday)
        else -> stringResource(R.string.intentions_duration_days, days.toInt())
    }
}
