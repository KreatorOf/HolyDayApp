package com.matthiascadet.holyday.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockPerson
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerIntentionEntity
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.service.notification.NotificationService
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.launch

private const val STEP_COUNT = 6

/** Équivalent de `OnboardingView` iOS : 6 étapes (hero, valeur, prénom, 1re intention, confidentialité, notifications). */
@Composable
fun OnboardingScreen(onFinished: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var step by remember { mutableIntStateOf(0) }
    var goingForward by remember { mutableStateOf(true) }
    var name by remember { mutableStateOf("") }

    fun advance() { goingForward = true; if (step < STEP_COUNT - 1) step++ else onFinished() }
    fun back() { goingForward = false; if (step > 0) step-- }

    val notificationLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        NotificationService.setReminder(context, true, granted)
        onFinished()
    }

    Box(Modifier.fillMaxSize()) {
        AppBackground()

        AnimatedContent(
            targetState = step,
            transitionSpec = {
                if (goingForward) {
                    (slideInHorizontally(tween(300)) { it } togetherWith slideOutHorizontally(tween(300)) { -it })
                } else {
                    (slideInHorizontally(tween(300)) { -it } togetherWith slideOutHorizontally(tween(300)) { it })
                }
            },
            label = "onboardingStep",
        ) { currentStep ->
            when (currentStep) {
                0 -> HeroPage(onNext = ::advance)
                1 -> ValuePage(onNext = ::advance)
                2 -> NamePage(name = name, onNameChange = { name = it }, onNext = {
                    AppPreferences.raw.edit().putString(NotificationService.USER_NAME_KEY, name.trim()).apply()
                    advance()
                })
                3 -> FirstIntentionPage(onNext = { text ->
                    if (text.isNotBlank()) {
                        scope.launch {
                            AppDatabase.getInstance(context).prayerIntentionDao()
                                .upsert(PrayerIntentionEntity(text = text.trim(), createdAt = System.currentTimeMillis()))
                        }
                    }
                    advance()
                })
                4 -> PrivacyPage(onNext = ::advance)
                else -> NotificationsPage(
                    onEnable = {
                        if (Build.VERSION.SDK_INT >= 33) {
                            notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        } else {
                            NotificationService.setReminder(context, true, true)
                            onFinished()
                        }
                    },
                    onSkip = onFinished,
                )
            }
        }

        if (step > 0) {
            IconButton(onClick = ::back, modifier = Modifier.padding(start = 8.dp, top = 8.dp)) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.onboarding_back), tint = AppTheme.colors.textSecondary)
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth().align(Alignment.BottomCenter).padding(bottom = 24.dp),
            horizontalArrangement = Arrangement.Center,
        ) {
            repeat(STEP_COUNT) { index ->
                Box(
                    modifier = Modifier
                        .padding(horizontal = 3.dp)
                        .height(6.dp)
                        .width(if (index == step) 20.dp else 6.dp)
                        .clip(RoundedCornerShape(50))
                        .background(if (index == step) AppTheme.colors.textPrimary else AppTheme.colors.textTertiary.copy(alpha = 0.4f)),
                )
            }
        }
    }
}

@Composable
private fun OnboardingScaffold(footer: @Composable () -> Unit, content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
        content()
        Spacer(Modifier.height(48.dp))
        footer()
        Spacer(Modifier.height(36.dp))
    }
}

@Composable
private fun HeroIcon(icon: ImageVector, color: androidx.compose.ui.graphics.Color) {
    Box(
        modifier = Modifier.size(96.dp).clip(CircleShape).background(color.copy(alpha = 0.15f)),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(48.dp)) }
}

@Composable
private fun PrimaryButton(title: String, enabled: Boolean = true, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(containerColor = AppTheme.colors.thanksgivingGold, contentColor = androidx.compose.ui.graphics.Color.Black),
        shape = RoundedCornerShape(30.dp),
        modifier = Modifier.fillMaxWidth().height(52.dp),
    ) { Text(title, fontWeight = FontWeight.SemiBold) }
}

@Composable
private fun HeroPage(onNext: () -> Unit) {
    OnboardingScaffold(footer = { PrimaryButton(stringResource(R.string.onboarding_welcome_cta), onClick = onNext) }) {
        HeroIcon(Icons.Filled.WbSunny, AppTheme.colors.thanksgivingGold)
        Spacer(Modifier.height(32.dp))
        Row {
            Text("Holy", fontStyle = FontStyle.Italic, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.headlineLarge, color = AppTheme.colors.textPrimary)
            Text("Day", fontWeight = FontWeight.Light, style = MaterialTheme.typography.headlineLarge, color = AppTheme.colors.textSecondary)
        }
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.onboarding_welcome_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textTertiary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun ValuePage(onNext: () -> Unit) {
    OnboardingScaffold(footer = { PrimaryButton(stringResource(R.string.onboarding_name_cta), onClick = onNext) }) {
        HeroIcon(Icons.Filled.VolunteerActivism, AppTheme.colors.adorationPurple)
        Spacer(Modifier.height(24.dp))
        Text(stringResource(R.string.onboarding_value_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(36.dp))
        Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
            FeatureRow(Icons.Filled.Check, stringResource(R.string.onboarding_pillar_way_label), stringResource(R.string.onboarding_pillar_way_desc), AppTheme.colors.adorationPurple)
            FeatureRow(Icons.Filled.VolunteerActivism, stringResource(R.string.onboarding_pillar_intentions_label), stringResource(R.string.onboarding_pillar_intentions_desc), AppTheme.colors.thanksgivingGold)
            FeatureRow(Icons.AutoMirrored.Filled.MenuBook, stringResource(R.string.onboarding_pillar_thread_label), stringResource(R.string.onboarding_pillar_thread_desc), AppTheme.colors.confessionBlue)
        }
    }
}

@Composable
private fun FeatureRow(icon: ImageVector, label: String, description: String, color: androidx.compose.ui.graphics.Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Box(modifier = Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(color.copy(alpha = 0.15f)), contentAlignment = Alignment.Center) {
            Icon(icon, contentDescription = null, tint = color)
        }
        Column {
            Text(label, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = AppTheme.colors.textPrimary)
            Text(description, style = MaterialTheme.typography.bodySmall, color = AppTheme.colors.textTertiary)
        }
    }
}

@Composable
private fun NamePage(name: String, onNameChange: (String) -> Unit, onNext: () -> Unit) {
    OnboardingScaffold(footer = { PrimaryButton(stringResource(R.string.onboarding_name_cta), enabled = name.isNotBlank(), onClick = onNext) }) {
        HeroIcon(Icons.Filled.Person, AppTheme.colors.confessionBlue)
        Spacer(Modifier.height(24.dp))
        Text(stringResource(R.string.onboarding_name_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary, textAlign = TextAlign.Center)
        Text(stringResource(R.string.onboarding_name_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textTertiary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        OutlinedTextField(
            value = name,
            onValueChange = onNameChange,
            placeholder = { Text(stringResource(R.string.onboarding_name_placeholder)) },
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun FirstIntentionPage(onNext: (String) -> Unit) {
    var text by remember { mutableStateOf("") }
    OnboardingScaffold(footer = { PrimaryButton(stringResource(R.string.onboarding_name_cta), onClick = { onNext(text) }) }) {
        HeroIcon(Icons.Filled.VolunteerActivism, AppTheme.colors.adorationPurple)
        Spacer(Modifier.height(24.dp))
        Text(stringResource(R.string.onboarding_intention_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary, textAlign = TextAlign.Center)
        Text(stringResource(R.string.onboarding_intention_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textTertiary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            placeholder = { Text(stringResource(R.string.onboarding_intention_placeholder)) },
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun PrivacyPage(onNext: () -> Unit) {
    OnboardingScaffold(footer = { PrimaryButton(stringResource(R.string.onboarding_name_cta), onClick = onNext) }) {
        HeroIcon(Icons.Filled.Lock, AppTheme.colors.confessionBlue)
        Spacer(Modifier.height(24.dp))
        Text(stringResource(R.string.onboarding_privacy_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary, textAlign = TextAlign.Center)
        Text(stringResource(R.string.onboarding_privacy_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textTertiary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(36.dp))
        Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
            FeatureRow(Icons.Filled.PhoneAndroid, stringResource(R.string.onboarding_privacy_local_label), stringResource(R.string.onboarding_privacy_local_desc), AppTheme.colors.confessionBlue)
            FeatureRow(Icons.Filled.VisibilityOff, stringResource(R.string.onboarding_privacy_private_label), stringResource(R.string.onboarding_privacy_private_desc), AppTheme.colors.confessionBlue)
            FeatureRow(Icons.Filled.LockPerson, stringResource(R.string.onboarding_privacy_you_label), stringResource(R.string.onboarding_privacy_you_desc), AppTheme.colors.confessionBlue)
        }
    }
}

@Composable
private fun NotificationsPage(onEnable: () -> Unit, onSkip: () -> Unit) {
    OnboardingScaffold(
        footer = {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                PrimaryButton(stringResource(R.string.onboarding_notifications_cta), onClick = onEnable)
                Spacer(Modifier.height(14.dp))
                Text(
                    stringResource(R.string.onboarding_notifications_skip),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppTheme.colors.textTertiary,
                    modifier = Modifier.clickable(onClick = onSkip),
                )
            }
        },
    ) {
        HeroIcon(Icons.Filled.NotificationsActive, AppTheme.colors.supplicationGreen)
        Spacer(Modifier.height(24.dp))
        Text(stringResource(R.string.onboarding_notifications_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = AppTheme.colors.textPrimary, textAlign = TextAlign.Center)
        Text(stringResource(R.string.onboarding_notifications_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ReassurancePill(Icons.Filled.WbSunny, stringResource(R.string.onboarding_notifications_pill_frequency))
            ReassurancePill(Icons.Filled.Favorite, stringResource(R.string.onboarding_notifications_pill_timing))
            ReassurancePill(Icons.Filled.Star, stringResource(R.string.onboarding_notifications_pill_control))
        }
    }
}

@Composable
private fun ReassurancePill(icon: ImageVector, text: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(AppTheme.colors.supplicationGreen.copy(alpha = 0.08f))
            .padding(vertical = 12.dp, horizontal = 8.dp),
    ) {
        Icon(icon, contentDescription = null, tint = AppTheme.colors.supplicationGreen, modifier = Modifier.size(18.dp))
        Text(text, style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary, textAlign = TextAlign.Center)
    }
}
