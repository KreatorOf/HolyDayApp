package com.matthiascadet.holyday.ui.settings

import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
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
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.BuildConfig
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.data.prefs.rememberStringPreference
import com.matthiascadet.holyday.service.AvatarService
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.SupportPromptService
import com.matthiascadet.holyday.service.TipService
import com.matthiascadet.holyday.service.notification.NotificationService
import com.matthiascadet.holyday.ui.theme.AppLinks
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.SoftCard
import com.matthiascadet.holyday.ui.theme.softTextFieldColors
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Équivalent de `SettingsView` iOS. */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onOpenLegal: () -> Unit, onOpenPaywall: () -> Unit, onOpenDebugMenu: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val entryDao = remember(context) { AppDatabase.getInstance(context).prayerEntryDao() }
    val entries by entryDao.observeAll().collectAsState(initial = emptyList())
    val firstPrayerDate = entries.minByOrNull { it.date }?.date

    var userName by remember { mutableStateOf(AppPreferences.raw.getString(NotificationService.USER_NAME_KEY, "") ?: "") }
    var colorScheme by remember { mutableStateOf(AppPreferences.raw.getString("holyday.colorScheme", "system") ?: "system") }
    val notificationsEnabled by NotificationService.isDailyReminderEnabled.collectAsState()
    val notificationsPermissionDenied by NotificationService.isPermissionDenied.collectAsState()
    val reminderTime by NotificationService.reminderTime.collectAsState()
    val hasTipped by TipService.hasTipped.collectAsState()
    val supporterTier = TipService.supporterTier

    androidx.compose.runtime.LaunchedEffect(Unit) { NotificationService.checkStatus(context) }

    var isEditingName by remember { mutableStateOf(false) }
    var pendingName by remember { mutableStateOf(userName) }
    var avatarBitmap by remember { mutableStateOf(AvatarService.load(context)) }
    var showResetConfirm by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }

    val notificationPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        NotificationService.setReminder(context, true, granted)
    }
    val photoPickerLauncher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? ->
        if (uri != null) {
            val bitmap = context.contentResolver.openInputStream(uri)?.use { android.graphics.BitmapFactory.decodeStream(it) }
            if (bitmap != null) {
                AvatarService.save(context, bitmap)
                avatarBitmap = AvatarService.load(context)
            }
        }
    }

    Box(Modifier.fillMaxSize()) {
        com.matthiascadet.holyday.ui.common.AppBackground()
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            Text(
                stringResource(R.string.tab_settings),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = AppTheme.colors.textPrimary,
            )

            // Profil
            SettingsCard {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(16.dp)) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(AppTheme.colors.cardSurface)
                            .border(1.dp, AppTheme.colors.cardStroke, CircleShape)
                            .clickable { photoPickerLauncher.launch(androidx.activity.result.PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) },
                        contentAlignment = Alignment.Center,
                    ) {
                        val bmp = avatarBitmap
                        if (bmp != null) {
                            androidx.compose.foundation.Image(bmp.asImageBitmap(), contentDescription = null, modifier = Modifier.fillMaxSize().clip(CircleShape))
                        } else {
                            Text(initials(userName), color = AppTheme.colors.adorationPurple, fontWeight = FontWeight.Bold)
                        }
                    }
                    Spacer(Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        if (isEditingName) {
                            TextField(
                                value = pendingName,
                                onValueChange = { pendingName = it },
                                shape = RoundedCornerShape(16.dp),
                                colors = softTextFieldColors(),
                                modifier = Modifier.fillMaxWidth(),
                            )
                        } else {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text(
                                    userName.ifEmpty { stringResource(R.string.settings_profile_name_placeholder) },
                                    color = if (userName.isEmpty()) AppTheme.colors.textTertiary else AppTheme.colors.textPrimary,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                supporterTier?.let { Text(it.emoji) }
                            }
                        }
                        if (firstPrayerDate != null) {
                            Text(
                                stringResource(R.string.settings_profile_praying_since, formatDateLong(firstPrayerDate)),
                                style = MaterialTheme.typography.labelSmall,
                                color = AppTheme.colors.textTertiary,
                            )
                        } else {
                            Text(stringResource(R.string.settings_profile_edit_hint), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary)
                        }
                    }
                    IconButton2(if (isEditingName) Icons.Filled.Edit else Icons.Filled.Edit) {
                        if (isEditingName) {
                            userName = pendingName.trim()
                            AppPreferences.raw.edit().putString(NotificationService.USER_NAME_KEY, userName).apply()
                            isEditingName = false
                        } else {
                            pendingName = userName
                            isEditingName = true
                        }
                    }
                }
            }

            // Soutien
            SettingsCard {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth().clickable(onClick = onOpenPaywall).padding(16.dp),
                ) {
                    IconBadge(Icons.Filled.Favorite, AppTheme.colors.adorationPurple)
                    Column(modifier = Modifier.weight(1f).padding(start = 14.dp)) {
                        Text(stringResource(R.string.settings_support_title), color = AppTheme.colors.textPrimary)
                        Text(
                            supporterTier?.let { stringResource(it.badgeNameRes) } ?: stringResource(R.string.settings_support_subtitle),
                            style = MaterialTheme.typography.labelSmall,
                            color = AppTheme.colors.textSecondary,
                        )
                    }
                    Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = AppTheme.colors.textTertiary)
                }
            }

            // Apparence
            SectionLabel(stringResource(R.string.settings_appearance_section))
            SettingsCard {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(16.dp)) {
                        IconBadge(Icons.Filled.Info, AppTheme.colors.adorationPurple)
                        Text(stringResource(R.string.settings_appearance_title), color = AppTheme.colors.textPrimary, modifier = Modifier.padding(start = 14.dp))
                    }
                    Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("system" to R.string.settings_appearance_system, "light" to R.string.settings_appearance_light, "dark" to R.string.settings_appearance_dark).forEach { (value, labelRes) ->
                            val selected = colorScheme == value
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .clip(RoundedCornerShape(50))
                                    .background(if (selected) AppTheme.colors.adorationPurple.copy(alpha = 0.3f) else AppTheme.colors.cardFill)
                                    .clickable {
                                        colorScheme = value
                                        AppPreferences.raw.edit().putString("holyday.colorScheme", value).apply()
                                    }
                                    .padding(vertical = 8.dp),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(stringResource(labelRes), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textPrimary)
                            }
                        }
                    }
                }
            }

            // Notifications
            SectionLabel(stringResource(R.string.settings_notifications_section))
            SettingsCard {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(16.dp)) {
                        IconBadge(Icons.Filled.Notifications, AppTheme.colors.thanksgivingGold)
                        Text(stringResource(R.string.settings_notifications_reminder), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                        Switch(
                            checked = notificationsEnabled,
                            onCheckedChange = { enabled ->
                                if (enabled) {
                                    if (android.os.Build.VERSION.SDK_INT >= 33) {
                                        notificationPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
                                    } else {
                                        NotificationService.setReminder(context, true, true)
                                    }
                                } else {
                                    NotificationService.setReminder(context, false, true)
                                }
                            },
                        )
                    }
                    if (notificationsEnabled) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth().clickable { showTimePicker = true }.padding(16.dp),
                        ) {
                            IconBadge(Icons.Filled.Notifications, AppTheme.colors.thanksgivingGold)
                            Text(
                                stringResource(R.string.settings_notifications_time) + " " + reminderTime.format(DateTimeFormatter.ofPattern("HH:mm")),
                                color = AppTheme.colors.textPrimary,
                                modifier = Modifier.padding(start = 14.dp),
                            )
                        }
                    }
                    if (notificationsPermissionDenied) {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(16.dp)) {
                            Icon(Icons.Filled.Warning, contentDescription = null, tint = androidx.compose.ui.graphics.Color(0xFFFF9800))
                            Text(stringResource(R.string.settings_notifications_disabled), color = androidx.compose.ui.graphics.Color(0xFFFF9800), modifier = Modifier.padding(start = 10.dp))
                        }
                    }
                }
            }

            // Communauté
            SectionLabel(stringResource(R.string.settings_community_section))
            SettingsCard {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable {
                            context.startActivity(
                                Intent.createChooser(
                                    Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, AppLinks.PLAY_STORE) },
                                    null,
                                ),
                            )
                        }.padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Share, AppTheme.colors.supplicationGreen)
                        Text(stringResource(R.string.settings_community_share), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable {
                            val manager = com.google.android.play.core.review.ReviewManagerFactory.create(context)
                            val request = manager.requestReviewFlow()
                            request.addOnCompleteListener {
                                if (it.isSuccessful) {
                                    (context as? android.app.Activity)?.let { activity -> manager.launchReviewFlow(activity, it.result) }
                                }
                            }
                        }.padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Star, AppTheme.colors.thanksgivingGold)
                        Text(stringResource(R.string.settings_community_rate), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                }
            }

            // Légal
            SectionLabel(stringResource(R.string.settings_legal_section))
            SettingsCard {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable {
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(AppLinks.PRIVACY_POLICY)))
                        }.padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Lock, AppTheme.colors.supplicationGreen)
                        Text(stringResource(R.string.settings_legal_privacy), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable {
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(AppLinks.TERMS_OF_SERVICE)))
                        }.padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Description, AppTheme.colors.confessionBlue)
                        Text(stringResource(R.string.settings_legal_terms), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable(onClick = onOpenLegal).padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Info, AppTheme.colors.adorationPurple)
                        Text(stringResource(R.string.settings_legal_notice), color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                }
            }

            // À propos
            SectionLabel(stringResource(R.string.settings_about_section))
            SettingsCard {
                Column {
                    InfoRow(stringResource(R.string.settings_about_version), BuildConfig.VERSION_NAME)
                    InfoRow(stringResource(R.string.settings_about_developer), "Matthias Cadet")
                }
            }

            // Zone danger
            SectionLabel(stringResource(R.string.settings_danger_section))
            SettingsCard {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth().clickable { showResetConfirm = true }.padding(16.dp),
                ) {
                    IconBadge(Icons.Filled.Delete, androidx.compose.ui.graphics.Color.Red)
                    Column(modifier = Modifier.weight(1f).padding(start = 14.dp)) {
                        Text(stringResource(R.string.settings_danger_reset_title), color = androidx.compose.ui.graphics.Color.Red)
                        Text(stringResource(R.string.settings_danger_reset_subtitle), style = MaterialTheme.typography.labelSmall, color = androidx.compose.ui.graphics.Color.Red.copy(alpha = 0.65f))
                    }
                }
            }

            if (BuildConfig.DEBUG) {
                SectionLabel("Développeur")
                SettingsCard {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable(onClick = onOpenDebugMenu).padding(16.dp),
                    ) {
                        IconBadge(Icons.Filled.Build, androidx.compose.ui.graphics.Color.Gray)
                        Text("Menu de debug", color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f).padding(start = 14.dp))
                    }
                }
            }

            Text(
                stringResource(R.string.settings_thanks),
                style = MaterialTheme.typography.labelSmall,
                color = AppTheme.colors.textTertiary,
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Text(
                stringResource(R.string.settings_copyright, java.time.Year.now().value.toString()),
                style = MaterialTheme.typography.labelSmall,
                color = AppTheme.colors.textTertiary,
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
        }
    }

    if (showResetConfirm) {
        AlertDialog(
            onDismissRequest = { showResetConfirm = false },
            title = { Text(stringResource(R.string.settings_danger_reset_confirm_title)) },
            text = { Text(stringResource(R.string.settings_danger_reset_confirm_message)) },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        entryDao.deleteAll()
                        AppDatabase.getInstance(context).prayerIntentionDao().deleteAll()
                        PrayerRecordService.reset()
                        SupportPromptService.shared.reset()
                        AvatarService.delete(context)
                        avatarBitmap = null
                        userName = ""
                        AppPreferences.raw.edit().remove(NotificationService.USER_NAME_KEY).apply()
                    }
                    showResetConfirm = false
                }) { Text(stringResource(R.string.settings_danger_reset_confirm_action), color = androidx.compose.ui.graphics.Color.Red) }
            },
            dismissButton = { TextButton(onClick = { showResetConfirm = false }) { Text(stringResource(R.string.common_cancel)) } },
        )
    }

    if (showTimePicker) {
        val state = rememberTimePickerState(initialHour = reminderTime.hour, initialMinute = reminderTime.minute)
        AlertDialog(
            onDismissRequest = { showTimePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    NotificationService.reschedule(context, LocalTime.of(state.hour, state.minute))
                    showTimePicker = false
                }) { Text(stringResource(R.string.common_close)) }
            },
            text = { TimePicker(state = state) },
        )
    }
}

@Composable
private fun SettingsCard(content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) {
    SoftCard(tint = AppTheme.colors.cardSurface, borderColor = AppTheme.colors.cardStroke, content = content)
}

@Composable
private fun SectionLabel(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary, modifier = Modifier.padding(start = 4.dp, bottom = 4.dp))
}

@Composable
private fun IconBadge(icon: androidx.compose.ui.graphics.vector.ImageVector, color: androidx.compose.ui.graphics.Color) {
    Box(
        modifier = Modifier.size(36.dp).clip(RoundedCornerShape(10.dp)).background(color.copy(alpha = 0.15f)),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, contentDescription = null, tint = color) }
}

@Composable
private fun IconButton2(icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .background(AppTheme.colors.buttonFillSubtle)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, contentDescription = null, tint = AppTheme.colors.textTertiary, modifier = Modifier.size(16.dp)) }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp)) {
        Text(label, color = AppTheme.colors.textPrimary, modifier = Modifier.weight(1f))
        Text(value, color = AppTheme.colors.textSecondary)
    }
}

private fun initials(name: String): String {
    val letters = name.trim().split(" ").filter { it.isNotEmpty() }.take(2).mapNotNull { it.firstOrNull()?.uppercaseChar() }
    return if (letters.isEmpty()) "?" else letters.joinToString("")
}

private fun formatDateLong(millis: Long): String {
    val date = Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate()
    return date.format(DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.LONG))
}
