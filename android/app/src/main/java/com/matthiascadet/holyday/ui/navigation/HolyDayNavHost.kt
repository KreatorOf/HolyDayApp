package com.matthiascadet.holyday.ui.navigation

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.SupporterTier
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.SupportPromptService
import com.matthiascadet.holyday.service.VerseService
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.ui.debug.DebugMenuScreen
import com.matthiascadet.holyday.ui.home.HomeScreen
import com.matthiascadet.holyday.ui.intentions.IntentionDetailScreen
import com.matthiascadet.holyday.ui.intentions.IntentionsScreen
import com.matthiascadet.holyday.ui.journal.JournalStatsScreen
import com.matthiascadet.holyday.ui.journal.PrayerEntryDetailScreen
import com.matthiascadet.holyday.ui.journal.PrayerHistoryScreen
import com.matthiascadet.holyday.ui.onboarding.OnboardingScreen
import com.matthiascadet.holyday.ui.prayer.FreePrayerScreen
import com.matthiascadet.holyday.ui.prayer.StructuredPrayerScreen
import com.matthiascadet.holyday.ui.settings.LegalNoticeScreen
import com.matthiascadet.holyday.ui.settings.SettingsScreen
import com.matthiascadet.holyday.ui.support.DonationThankYouScreen
import com.matthiascadet.holyday.ui.support.PaywallScreen
import com.matthiascadet.holyday.ui.support.SupportPromptScreen
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softSurface
import java.util.UUID

const val ONBOARDING_DONE_KEY = "holyday.hasCompletedOnboarding"

@Composable
fun HolyDayNavHost() {
    val navController = rememberNavController()
    val context = LocalContext.current
    var hasCompletedOnboarding by rememberSaveable {
        mutableStateOf(AppPreferences.raw.getBoolean(ONBOARDING_DONE_KEY, false))
    }

    var selectedEmotion by remember { mutableStateOf<Emotion?>(null) }
    var emotionVerse by remember { mutableStateOf<Verse?>(null) }
    var recordTokenBeforePrayer by remember { mutableStateOf<UUID?>(null) }

    // Reproduit `presentSupportPromptIfEligible` de ContentView : à la fermeture d'une feuille de
    // prière, si une nouvelle prière vient d'être enregistrée pendant la session ET que le service
    // juge la sollicitation opportune, on l'affiche.
    fun onPrayerSheetDismissed() {
        selectedEmotion = null
        emotionVerse = null
        val recorded = PrayerRecordService.lastRecordToken.value != recordTokenBeforePrayer
        navController.popBackStack()
        if (recorded && SupportPromptService.shared.shouldPrompt) {
            SupportPromptService.shared.markShown()
            navController.navigate(NavRoutes.SUPPORT_PROMPT)
        }
    }

    NavHost(navController = navController, startDestination = if (hasCompletedOnboarding) NavRoutes.MAIN else NavRoutes.ONBOARDING) {
        composable(NavRoutes.ONBOARDING) {
            OnboardingScreen(
                onFinished = {
                    AppPreferences.raw.edit().putBoolean(ONBOARDING_DONE_KEY, true).apply()
                    hasCompletedOnboarding = true
                    navController.navigate(NavRoutes.MAIN) {
                        popUpTo(NavRoutes.ONBOARDING) { inclusive = true }
                    }
                },
            )
        }

        composable(NavRoutes.MAIN) {
            MainScreen(
                navController = navController,
                selectedEmotion = selectedEmotion,
                emotionVerse = emotionVerse,
                onSelectEmotion = { emotion ->
                    selectedEmotion = emotion
                    val verse = VerseService.verse(emotion)
                    emotionVerse = verse
                    WidgetSyncService.updateLastVerse(verse.text, verse.reference, emotion.id)
                },
                onBeforeStartingPrayer = { recordTokenBeforePrayer = PrayerRecordService.lastRecordToken.value },
            )
        }

        composable(NavRoutes.FREE_PRAYER) {
            FreePrayerScreen(
                verse = emotionVerse,
                accent = selectedEmotion?.let { AppTheme.colorFor(it.colorName) } ?: AppTheme.colors.adorationPurple,
                onSave = { text ->
                    com.matthiascadet.holyday.ui.home.saveFreePrayerEntry(
                        context,
                        text,
                        selectedEmotion,
                        emotionVerse,
                    )
                },
                onDismiss = ::onPrayerSheetDismissed,
            )
        }

        composable(NavRoutes.STRUCTURED_PRAYER) {
            StructuredPrayerScreen(
                verse = emotionVerse,
                accent = selectedEmotion?.let { AppTheme.colorFor(it.colorName) } ?: AppTheme.colors.adorationPurple,
                onDismiss = ::onPrayerSheetDismissed,
            )
        }

        composable(NavRoutes.SUPPORT_PROMPT) {
            SupportPromptScreen(
                onSupport = {
                    navController.navigate(NavRoutes.PAYWALL) { popUpTo(NavRoutes.SUPPORT_PROMPT) { inclusive = true } }
                },
                onLater = { navController.popBackStack() },
                onDontAskAgain = {
                    SupportPromptService.shared.dontAskAgain()
                    navController.popBackStack()
                },
            )
        }

        composable(NavRoutes.INTENTIONS) {
            IntentionsScreen(
                onDismiss = { navController.popBackStack() },
                onOpenDetail = { id -> navController.navigate(NavRoutes.intentionDetail(id)) },
            )
        }

        composable(NavRoutes.INTENTION_DETAIL) { backStackEntry ->
            val id = backStackEntry.arguments?.getString("intentionId").orEmpty()
            IntentionDetailScreen(intentionId = id, onDismiss = { navController.popBackStack() })
        }

        composable(NavRoutes.JOURNAL_ENTRY) { backStackEntry ->
            val id = backStackEntry.arguments?.getString("entryId").orEmpty()
            PrayerEntryDetailScreen(entryId = id, onDismiss = { navController.popBackStack() })
        }

        composable(NavRoutes.JOURNAL_STATS) {
            JournalStatsScreen(onDismiss = { navController.popBackStack() })
        }

        composable(NavRoutes.LEGAL) {
            LegalNoticeScreen(onDismiss = { navController.popBackStack() })
        }

        composable(NavRoutes.PAYWALL) {
            PaywallScreen(
                onDismiss = { navController.popBackStack() },
                onDonated = { tier -> navController.navigate(NavRoutes.donationThankYou(tier.name)) },
            )
        }

        composable(
            NavRoutes.DONATION_THANK_YOU,
            arguments = listOf(navArgument("tier") { type = NavType.StringType; nullable = true; defaultValue = null }),
        ) { backStackEntry ->
            val tier = backStackEntry.arguments?.getString("tier")?.let { name ->
                runCatching { SupporterTier.valueOf(name) }.getOrNull()
            }
            DonationThankYouScreen(
                tier = tier,
                onDismiss = { navController.popBackStack(NavRoutes.PAYWALL, inclusive = true) },
            )
        }

        composable(NavRoutes.DEBUG_MENU) {
            DebugMenuScreen(onDismiss = { navController.popBackStack() })
        }
    }
}

@Composable
private fun MainScreen(
    navController: NavHostController,
    selectedEmotion: Emotion?,
    emotionVerse: Verse?,
    onSelectEmotion: (Emotion) -> Unit,
    onBeforeStartingPrayer: () -> Unit,
) {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    Scaffold(
        containerColor = Color.Transparent,
        bottomBar = { HolyDayBottomBar(selectedTab = selectedTab, onSelect = { selectedTab = it }) },
    ) { padding ->
        androidx.compose.foundation.layout.Box(Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> HomeScreen(
                    selectedEmotion = selectedEmotion,
                    emotionVerse = emotionVerse,
                    onSelectEmotion = onSelectEmotion,
                    onOpenIntentions = { navController.navigate(NavRoutes.INTENTIONS) },
                    onStartFreePrayer = { onBeforeStartingPrayer(); navController.navigate(NavRoutes.FREE_PRAYER) },
                    onStartStructuredPrayer = { onBeforeStartingPrayer(); navController.navigate(NavRoutes.STRUCTURED_PRAYER) },
                )
                1 -> PrayerHistoryScreen(
                    onOpenEntry = { id -> navController.navigate(NavRoutes.journalEntry(id)) },
                    onOpenStats = { navController.navigate(NavRoutes.JOURNAL_STATS) },
                )
                else -> SettingsScreen(
                    onOpenLegal = { navController.navigate(NavRoutes.LEGAL) },
                    onOpenPaywall = { navController.navigate(NavRoutes.PAYWALL) },
                    onOpenDebugMenu = { navController.navigate(NavRoutes.DEBUG_MENU) },
                )
            }
        }
    }
}

private data class BottomTab(val index: Int, val icon: ImageVector, val labelRes: Int)

// Barre flottante plutôt que le `NavigationBar` Material plein-largeur par défaut : reprend le
// langage visuel du reste de l'app (carte tonale arrondie + ombre douce via `softSurface`) au lieu
// du bloc compact standard, avec le libellé qui n'apparaît qu'à côté de l'onglet actif.
@Composable
private fun HolyDayBottomBar(selectedTab: Int, onSelect: (Int) -> Unit) {
    val tabs = remember {
        listOf(
            BottomTab(0, Icons.Filled.AutoAwesome, R.string.tab_prayer),
            BottomTab(1, Icons.AutoMirrored.Filled.MenuBook, R.string.tab_journal),
            BottomTab(2, Icons.Filled.Settings, R.string.tab_settings),
        )
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 28.dp, vertical = 16.dp)
            .softSurface(shape = MaterialTheme.shapes.extraLarge, tint = MaterialTheme.colorScheme.surface, elevation = 10.dp)
            .padding(horizontal = 10.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        tabs.forEach { tab ->
            BottomTabItem(tab = tab, selected = selectedTab == tab.index, onClick = { onSelect(tab.index) })
        }
    }
}

@Composable
private fun BottomTabItem(tab: BottomTab, selected: Boolean, onClick: () -> Unit) {
    val indicatorColor by animateColorAsState(
        targetValue = if (selected) AppTheme.colors.adorationPurple.copy(alpha = 0.14f) else Color.Transparent,
        animationSpec = tween(200),
        label = "navIndicator",
    )
    val contentColor = if (selected) AppTheme.colors.adorationPurple else AppTheme.colors.textTertiary

    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(indicatorColor)
            .clickable(onClick = onClick)
            .padding(horizontal = if (selected) 18.dp else 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(tab.icon, contentDescription = stringResource(tab.labelRes), tint = contentColor, modifier = Modifier.size(24.dp))
        if (selected) {
            Text(stringResource(tab.labelRes), color = contentColor, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
        }
    }
}
