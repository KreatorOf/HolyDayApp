package com.matthiascadet.holyday.service.notification

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.prefs.AppPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId

/**
 * Équivalent de `NotificationService` iOS, adapté à Android : au lieu de pré-planifier une
 * fenêtre glissante de 60 notifications (contournement de la limite iOS de 64 notifications
 * locales en attente), une seule alarme exacte est programmée à la fois ; à chaque déclenchement
 * elle poste la notification du jour ET replanifie elle-même celle du lendemain
 * (voir `PrayerReminderReceiver`). Android n'a pas la limite qui motivait le pré-remplissage
 * côté iOS, donc ce mécanisme plus simple est fonctionnellement équivalent (un rappel quotidien
 * au contenu rotatif et déterministe), pas une simplification qui changerait le comportement
 * perçu par l'utilisateur.
 */
object NotificationService {
    private const val HOUR_KEY = "holyday.reminderHour"
    private const val MINUTE_KEY = "holyday.reminderMinute"
    private const val ENABLED_KEY = "holyday.reminderEnabled"
    const val USER_NAME_KEY = "holyday.userName"

    const val CHANNEL_ID = "daily_prayer_reminder"
    const val NOTIFICATION_ID = 1001
    private const val REQUEST_CODE = 2001

    private val zone: ZoneId = ZoneId.systemDefault()

    private val _isDailyReminderEnabled = MutableStateFlow(false)
    val isDailyReminderEnabled: StateFlow<Boolean> = _isDailyReminderEnabled.asStateFlow()

    private val _isPermissionDenied = MutableStateFlow(false)
    val isPermissionDenied: StateFlow<Boolean> = _isPermissionDenied.asStateFlow()

    private val _reminderTime = MutableStateFlow(LocalTime.of(8, 0))
    val reminderTime: StateFlow<LocalTime> = _reminderTime.asStateFlow()

    fun init(context: Context) {
        val prefs = AppPreferences.raw
        _reminderTime.value = LocalTime.of(
            prefs.getInt(HOUR_KEY, 8),
            prefs.getInt(MINUTE_KEY, 0),
        )
        checkStatus(context)
    }

    fun checkStatus(context: Context) {
        val notificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        _isPermissionDenied.value = !notificationsEnabled
        _isDailyReminderEnabled.value = notificationsEnabled && AppPreferences.raw.getBoolean(ENABLED_KEY, false)
    }

    /** À appeler après que la permission POST_NOTIFICATIONS a été demandée dans l'UI. */
    fun setReminder(context: Context, enabled: Boolean, notificationsPermitted: Boolean) {
        if (enabled) {
            if (!notificationsPermitted) {
                _isPermissionDenied.value = true
                _isDailyReminderEnabled.value = false
                AppPreferences.raw.edit().putBoolean(ENABLED_KEY, false).apply()
                return
            }
            _isDailyReminderEnabled.value = true
            _isPermissionDenied.value = false
            AppPreferences.raw.edit().putBoolean(ENABLED_KEY, true).apply()
            reschedule(context, _reminderTime.value)
        } else {
            removeScheduledReminder(context)
            _isDailyReminderEnabled.value = false
            AppPreferences.raw.edit().putBoolean(ENABLED_KEY, false).apply()
        }
    }

    /** Reprend la chaîne d'alarme si elle a été perdue (redémarrage, mise à jour de l'app). */
    fun refreshScheduledReminders(context: Context) {
        if (!_isDailyReminderEnabled.value) return
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
        reschedule(context, _reminderTime.value)
    }

    fun reschedule(context: Context, time: LocalTime) {
        persist(time)
        _reminderTime.value = time
        scheduleNext(context, time)
    }

    /** Appelé par le récepteur après avoir posté la notification du jour : programme demain. */
    internal fun scheduleNext(context: Context, time: LocalTime) {
        val now = LocalDateTime.now(zone)
        var next = LocalDateTime.of(now.toLocalDate(), time)
        if (!next.isAfter(now)) {
            next = LocalDateTime.of(now.toLocalDate().plusDays(1), time)
        }
        val triggerAtMillis = next.atZone(zone).toInstant().toEpochMilli()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = reminderPendingIntent(context)

        val canScheduleExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
        if (canScheduleExact) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }

    private fun removeScheduledReminder(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(reminderPendingIntent(context))
    }

    private fun reminderPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerReminderReceiver::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)
    }

    /**
     * Titre + corps déterministes par jour de l'année : un jour donné mappe toujours sur le même
     * couple, et deux jours consécutifs diffèrent toujours (titre mod 5, question mod 10). Le
     * titre est personnalisé avec le prénom s'il est connu, sinon repli générique.
     */
    fun reminderContent(context: Context, date: LocalDate, name: String): Pair<String, String> {
        val dayIndex = date.dayOfYear
        val titleIndex = dayIndex % TITLES_GENERIC.size

        val title = if (name.isBlank()) {
            context.getString(TITLES_GENERIC[titleIndex])
        } else {
            context.getString(TITLES_NAMED[titleIndex], name)
        }
        val body = context.getString(QUESTIONS[dayIndex % QUESTIONS.size])
        return title to body
    }

    private fun persist(time: LocalTime) {
        AppPreferences.raw.edit()
            .putInt(HOUR_KEY, time.hour)
            .putInt(MINUTE_KEY, time.minute)
            .apply()
    }

    private val TITLES_GENERIC = listOf(
        R.string.notification_invite_0,
        R.string.notification_invite_1,
        R.string.notification_invite_2,
        R.string.notification_invite_3,
        R.string.notification_invite_4,
    )

    private val TITLES_NAMED = listOf(
        R.string.notification_invite_named_0,
        R.string.notification_invite_named_1,
        R.string.notification_invite_named_2,
        R.string.notification_invite_named_3,
        R.string.notification_invite_named_4,
    )

    private val QUESTIONS = listOf(
        R.string.notification_question_0,
        R.string.notification_question_1,
        R.string.notification_question_2,
        R.string.notification_question_3,
        R.string.notification_question_4,
        R.string.notification_question_5,
        R.string.notification_question_6,
        R.string.notification_question_7,
        R.string.notification_question_8,
        R.string.notification_question_9,
    )
}
