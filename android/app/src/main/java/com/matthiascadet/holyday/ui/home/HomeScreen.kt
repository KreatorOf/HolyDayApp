package com.matthiascadet.holyday.ui.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.core.tween
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import android.content.Context
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.data.db.PrayerStepIcon
import com.matthiascadet.holyday.data.db.TitleSource
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.data.prefs.rememberStringPreference
import com.matthiascadet.holyday.service.AIAssistantService
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.service.notification.NotificationService as PrayerNotificationService
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.prayer.EmotionRibbon
import com.matthiascadet.holyday.ui.prayer.EmotionVerse
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Enregistre une prière libre : repli immédiat (1re ligne) pour le titre, puis enrichissement
 * asynchrone par l'IA on-device si disponible (toujours dégradé sur Android, voir
 * `AIAssistantService`). Équivalent de `ContentView.saveFreePrayer`.
 */
fun saveFreePrayerEntry(context: Context, text: String, emotion: Emotion?, verse: Verse?) {
    val trimmed = text.trim()
    if (trimmed.isEmpty()) return

    val dao = AppDatabase.getInstance(context).prayerEntryDao()
    val entry = PrayerEntryEntity(
        stepTitle = context.getString(R.string.prayer_free_title),
        stepIcon = PrayerStepIcon.FREE_PRAYER,
        stepColorName = "adorationPurple",
        text = trimmed,
        date = System.currentTimeMillis(),
        emotionRaw = emotion?.id,
        verseReference = verse?.reference,
        customTitle = PrayerEntryEntity.fallbackTitle(trimmed),
        titleSourceRaw = TitleSource.FALLBACK.name,
    )

    CoroutineScope(Dispatchers.IO).launch {
        dao.upsert(entry)
        PrayerRecordService.recordPrayer()
        WidgetSyncService.sync()

        if (trimmed.length >= 15) {
            val aiTitle = AIAssistantService.generateTitle(trimmed)
            if (aiTitle != null) {
                dao.update(entry.copy(customTitle = aiTitle, titleSourceRaw = TitleSource.AI.name))
            }
        }
    }
}

/** Équivalent de `ContentView` iOS (onglet Prière). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    selectedEmotion: Emotion?,
    emotionVerse: Verse?,
    onSelectEmotion: (Emotion) -> Unit,
    onOpenIntentions: () -> Unit,
    onStartFreePrayer: () -> Unit,
    onStartStructuredPrayer: () -> Unit,
) {
    val userName by rememberStringPreference(PrayerNotificationService.USER_NAME_KEY)
    var menuExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { BrandingTitle() },
                actions = {
                    IconButton(onClick = onOpenIntentions) {
                        Icon(
                            Icons.AutoMirrored.Filled.List,
                            contentDescription = stringResource(R.string.intentions_nav_title),
                            tint = AppTheme.colors.textPrimary,
                            modifier = Modifier.size(32.dp),
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
        containerColor = androidx.compose.ui.graphics.Color.Transparent,
    ) { padding ->
        Box(Modifier.fillMaxSize()) {
            AppBackground()
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(padding),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Spacer(Modifier.height(24.dp))
                Text(
                    text = feelingQuestion(userName),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = AppTheme.colors.textPrimary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp),
                )
                Spacer(Modifier.height(20.dp))
                EmotionRibbon(onSelect = onSelectEmotion, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(12.dp))
                Box(Modifier.fillMaxWidth().height(168.dp), contentAlignment = Alignment.TopCenter) {
                    emotionVerse?.let { verse ->
                        EmotionVerse(
                            verse = verse,
                            accent = selectedEmotion?.let { AppTheme.colorFor(it.colorName) } ?: AppTheme.colors.adorationPurple,
                        )
                    }
                }
                Spacer(Modifier.height(24.dp))
            }

            // Scrim plein écran : capte un tap en dehors des pilules pour refermer le choix, sans
            // bloquer le reste de l'écran quand le bouton est à l'état replié.
            if (menuExpanded) {
                Box(
                    Modifier
                        .fillMaxSize()
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                            onClick = { menuExpanded = false },
                        ),
                )
            }

            Box(Modifier.fillMaxSize().padding(bottom = 28.dp), contentAlignment = Alignment.BottomCenter) {
                // Éventail façon speed-dial : les deux pilules apparaissent au-dessus du bouton
                // principal (qui reste l'ancre visuelle et devient le bouton pour refermer), avec un
                // léger décalage d'apparition — la pilule la plus proche du bouton sort en premier.
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    AnimatedVisibility(
                        visible = menuExpanded,
                        enter = fadeIn(tween(200, delayMillis = 70)) + slideInVertically(tween(200, delayMillis = 70)) { it / 2 },
                        exit = fadeOut(tween(120)) + slideOutVertically(tween(120)) { it / 2 },
                    ) {
                        PrayChoicePill(
                            icon = Icons.Filled.AutoAwesome,
                            label = stringResource(R.string.prayer_guided_title),
                            onClick = { menuExpanded = false; onStartStructuredPrayer() },
                        )
                    }
                    AnimatedVisibility(
                        visible = menuExpanded,
                        enter = fadeIn(tween(200)) + slideInVertically(tween(200)) { it / 2 },
                        exit = fadeOut(tween(120, delayMillis = 60)) + slideOutVertically(tween(120, delayMillis = 60)) { it / 2 },
                    ) {
                        PrayChoicePill(
                            icon = Icons.Filled.Edit,
                            label = stringResource(R.string.prayer_free_title),
                            onClick = { menuExpanded = false; onStartFreePrayer() },
                        )
                    }
                    Button(
                        onClick = { menuExpanded = !menuExpanded },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AppTheme.colors.adorationPurple,
                            contentColor = androidx.compose.ui.graphics.Color.White,
                        ),
                        elevation = ButtonDefaults.buttonElevation(defaultElevation = 6.dp, pressedElevation = 2.dp),
                        shape = MaterialTheme.shapes.extraLarge,
                        contentPadding = PaddingValues(horizontal = 26.dp, vertical = 14.dp),
                    ) {
                        Crossfade(targetState = menuExpanded, label = "prayButtonIcon") { expanded ->
                            Icon(if (expanded) Icons.Filled.Close else Icons.Filled.AutoAwesome, contentDescription = null)
                        }
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.home_pray_cta), fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

@Composable
private fun PrayChoicePill(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = AppTheme.colors.adorationPurple,
            contentColor = androidx.compose.ui.graphics.Color.White,
        ),
        elevation = ButtonDefaults.buttonElevation(defaultElevation = 6.dp, pressedElevation = 2.dp),
        shape = MaterialTheme.shapes.extraLarge,
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 14.dp),
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
private fun BrandingTitle() {
    Row {
        Text("Holy", fontStyle = FontStyle.Italic, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.headlineLarge, color = AppTheme.colors.textPrimary)
        Text("Day", fontWeight = FontWeight.Light, style = MaterialTheme.typography.headlineLarge, color = AppTheme.colors.textPrimary)
    }
}

@Composable
private fun feelingQuestion(userName: String): String =
    if (userName.isBlank()) {
        stringResource(R.string.home_feeling_question)
    } else {
        stringResource(R.string.home_feeling_question_named, userName)
    }
