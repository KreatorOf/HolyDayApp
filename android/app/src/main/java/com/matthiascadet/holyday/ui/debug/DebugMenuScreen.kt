package com.matthiascadet.holyday.ui.debug

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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.data.db.PrayerIntentionEntity
import com.matthiascadet.holyday.data.db.PrayerStepIcon
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.PrayerStep
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.service.AIAssistantService
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.TipService
import com.matthiascadet.holyday.service.notification.NotificationService
import com.matthiascadet.holyday.ui.navigation.ONBOARDING_DONE_KEY
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.launch

/**
 * Équivalent de `DebugMenuView` iOS — accessible uniquement via la section "Développeur" des
 * réglages, elle-même gate par `BuildConfig.DEBUG`. Libellés volontairement en dur (hors prod),
 * comme dans `DebugActions.swift`.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DebugMenuScreen(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val entryDao = remember(context) { AppDatabase.getInstance(context).prayerEntryDao() }
    val intentionDao = remember(context) { AppDatabase.getInstance(context).prayerIntentionDao() }
    val prayers by entryDao.observeAll().collectAsState(initial = emptyList())
    val intentions by intentionDao.observeAll().collectAsState(initial = emptyList())
    val totalPrayedDays by PrayerRecordService.totalPrayedDays.collectAsState()
    val hasTipped by TipService.hasTipped.collectAsState()

    var toast by remember { mutableStateOf<String?>(null) }
    var showNukeConfirm by remember { mutableStateOf(false) }

    fun flash(message: String) { toast = message }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("🛠 Debug") },
                navigationIcon = { IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = "Fermer") } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                DebugSection("État") {
                    InfoRow("Onboarding terminé", if (AppPreferences.raw.getBoolean(ONBOARDING_DONE_KEY, false)) "oui" else "non")
                    InfoRow("Prénom", AppPreferences.raw.getString(NotificationService.USER_NAME_KEY, "")?.ifEmpty { "—" } ?: "—")
                    InfoRow("Jours priés", "$totalPrayedDays")
                    InfoRow("Prières", "${prayers.size}")
                    InfoRow("Intentions", "${intentions.size}")
                    InfoRow("IA disponible", if (AIAssistantService.isAvailable) "oui" else "non")
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                        Text("Supporter (premium)", color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f))
                        Switch(checked = hasTipped, onCheckedChange = { TipService.debugSetSupporter(it) })
                    }
                }

                DebugSection("Réinitialiser") {
                    ActionRow("Réinitialiser le suivi prière") {
                        PrayerRecordService.reset()
                        flash("Suivi prière remis à zéro")
                    }
                    ActionRow("Vider les prières", destructive = true) {
                        scope.launch { entryDao.deleteAll() }
                        flash("Prières supprimées")
                    }
                    ActionRow("Vider les intentions", destructive = true) {
                        scope.launch { intentionDao.deleteAll() }
                        flash("Intentions supprimées")
                    }
                }

                DebugSection("Données de démo") {
                    ActionRow("Générer 14 jours de prières") {
                        scope.launch { seedDemoPrayers(context, entryDao, intentionDao) }
                        flash("Données de démo créées")
                    }
                }

                DebugSection(null) {
                    ActionRow("Tout réinitialiser", destructive = true) { showNukeConfirm = true }
                }

                toast?.let {
                    Text(it, color = AppTheme.colors.textSecondary, modifier = Modifier.padding(top = 8.dp))
                }
            }
        }
    }

    if (showNukeConfirm) {
        AlertDialog(
            onDismissRequest = { showNukeConfirm = false },
            title = { Text("Tout réinitialiser ?") },
            text = { Text("Prières, intentions, suivi prière, prénom, thème, onboarding et badge supporter.") },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        entryDao.deleteAll()
                        intentionDao.deleteAll()
                        PrayerRecordService.reset()
                        TipService.debugSetSupporter(false)
                        AppPreferences.raw.edit()
                            .remove(NotificationService.USER_NAME_KEY)
                            .putString("holyday.colorScheme", "system")
                            .putBoolean(ONBOARDING_DONE_KEY, false)
                            .apply()
                        flash("Tout réinitialisé")
                    }
                    showNukeConfirm = false
                }) { Text("Tout effacer", color = androidx.compose.ui.graphics.Color.Red) }
            },
            dismissButton = { TextButton(onClick = { showNukeConfirm = false }) { Text("Annuler") } },
        )
    }
}

private suspend fun seedDemoPrayers(
    context: android.content.Context,
    entryDao: com.matthiascadet.holyday.data.db.PrayerEntryDao,
    intentionDao: com.matthiascadet.holyday.data.db.PrayerIntentionDao,
) {
    val freeTexts = listOf(
        "Seigneur, merci pour cette journée et pour ta présence à chaque instant.",
        "Je remets entre tes mains ce qui m'inquiète. Donne-moi la paix.",
        "Apprends-moi à aimer comme tu aimes, sans condition.",
        "Merci pour ma famille, veille sur chacun d'eux aujourd'hui.",
        "Je veux marcher avec toi, pas à pas, sans me presser.",
    )
    val guidedTexts = listOf(
        "Je t'adore pour ta fidélité qui ne change jamais.",
        "Je reconnais mes manques et je reçois ton pardon.",
        "Merci pour les petites grâces de cette semaine.",
        "Je te confie ceux que j'aime et ceux qui souffrent.",
        "Tu es bon, et ta bonté me poursuit chaque jour.",
    )
    val emotions = listOf(Emotion.JOY, Emotion.PEACE, Emotion.GRATITUDE, Emotion.HOPE, Emotion.SADNESS, Emotion.FATIGUE, Emotion.FEAR, Emotion.ANGER)
    val steps = PrayerStep.defaultSteps
    val dayMillis = 24L * 60 * 60 * 1000

    for (dayOffset in 0 until 14) {
        val day = System.currentTimeMillis() - dayOffset * dayMillis
        val entriesForDay = if (dayOffset % 3 == 0) 2 else 1
        for (index in 0 until entriesForDay) {
            val seed = dayOffset + index
            val emotion = emotions[seed % emotions.size]
            val isFree = seed % 4 == 0
            val entry = if (isFree) {
                PrayerEntryEntity(
                    stepTitle = "Prière libre",
                    stepIcon = PrayerStepIcon.FREE_PRAYER,
                    stepColorName = "adorationPurple",
                    text = freeTexts[seed % freeTexts.size],
                    date = day,
                    durationSeconds = (120 + dayOffset * 15).toDouble(),
                    emotionRaw = emotion.id,
                )
            } else {
                val step = steps[seed % steps.size]
                PrayerEntryEntity(
                    stepTitle = context.getString(step.titleRes),
                    stepIcon = when (step.order) {
                        1 -> PrayerStepIcon.ADORATION
                        2 -> PrayerStepIcon.CONFESSION
                        3 -> PrayerStepIcon.THANKSGIVING
                        else -> PrayerStepIcon.SUPPLICATION
                    },
                    stepColorName = step.colorName,
                    text = guidedTexts[seed % guidedTexts.size],
                    date = day,
                    durationSeconds = (90 + dayOffset * 10).toDouble(),
                    emotionRaw = emotion.id,
                )
            }
            entryDao.upsert(entry)
        }
    }

    intentionDao.upsert(PrayerIntentionEntity(text = "Pour la santé de ma famille", createdAt = System.currentTimeMillis()))
    intentionDao.upsert(
        PrayerIntentionEntity(
            text = "Trouver la paix intérieure",
            createdAt = System.currentTimeMillis(),
            isAnswered = true,
            answeredAt = System.currentTimeMillis(),
        ),
    )
    intentionDao.upsert(PrayerIntentionEntity(text = "Sagesse pour une décision importante", createdAt = System.currentTimeMillis()))
}

@Composable
private fun DebugSection(title: String?, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        title?.let { Text(it.uppercase(), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary) }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(AppTheme.colors.cardSurface)
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) { content() }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Text(label, color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f))
        Text(value, color = AppTheme.colors.textSecondary)
    }
}

@Composable
private fun ActionRow(title: String, destructive: Boolean = false, onClick: () -> Unit) {
    Text(
        title,
        color = if (destructive) androidx.compose.ui.graphics.Color.Red else AppTheme.colors.textPrimary,
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 8.dp),
    )
}
