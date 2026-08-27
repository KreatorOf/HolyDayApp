package com.matthiascadet.holyday.service

import android.content.SharedPreferences
import com.matthiascadet.holyday.data.prefs.AppPreferences
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * Décide quand proposer (avec retenue) de soutenir le développeur, à un moment calme de fin de
 * prière. Jamais pour un donateur, jamais après un opt-out, avec un plafond et un délai
 * croissant entre deux sollicitations.
 *
 * Les entrées externes (jours priés, statut donateur, horloge) et le stockage sont injectables
 * pour rendre la décision testable en isolation — voir `SupportPromptServiceTest`.
 */
class SupportPromptService(
    private val prefs: SharedPreferences = AppPreferences.raw,
    private val prayedDaysProvider: () -> Int = { PrayerRecordService.totalPrayedDays.value },
    private val hasTippedProvider: () -> Boolean = { TipService.hasTipped.value },
    private val now: () -> Instant = { Instant.now() },
) {
    private var timesShown: Int
        get() = prefs.getInt(TIMES_SHOWN_KEY, 0)
        set(value) { prefs.edit().putInt(TIMES_SHOWN_KEY, value).apply() }

    private var lastShownMillis: Long?
        get() = prefs.getLong(LAST_SHOWN_KEY, -1L).takeIf { it >= 0 }
        set(value) {
            val editor = prefs.edit()
            if (value == null) editor.remove(LAST_SHOWN_KEY) else editor.putLong(LAST_SHOWN_KEY, value)
            editor.apply()
        }

    private var dismissedForever: Boolean
        get() = prefs.getBoolean(DISMISSED_FOREVER_KEY, false)
        set(value) { prefs.edit().putBoolean(DISMISSED_FOREVER_KEY, value).apply() }

    val shouldPrompt: Boolean
        get() {
            if (hasTippedProvider()) return false
            if (dismissedForever) return false
            if (timesShown >= MAX_PROMPTS) return false
            if (prayedDaysProvider() < MIN_PRAYED_DAYS) return false

            val last = lastShownMillis ?: return true
            val required = COOLDOWN_DAYS[minOf(timesShown, COOLDOWN_DAYS.size - 1)]
            val daysSince = ChronoUnit.DAYS.between(
                Instant.ofEpochMilli(last).atZone(ZONE).toLocalDate(),
                now().atZone(ZONE).toLocalDate(),
            )
            return daysSince >= required
        }

    /** À appeler au moment où la page est effectivement présentée : démarre le délai de repos. */
    fun markShown() {
        timesShown += 1
        lastShownMillis = now().toEpochMilli()
    }

    /** L'utilisateur choisit de ne plus jamais être sollicité. */
    fun dontAskAgain() {
        dismissedForever = true
    }

    /** Remet l'état à neuf. Appelé lors d'un effacement complet des données. */
    fun reset() {
        prefs.edit()
            .remove(TIMES_SHOWN_KEY)
            .remove(LAST_SHOWN_KEY)
            .remove(DISMISSED_FOREVER_KEY)
            .apply()
    }

    companion object {
        val shared: SupportPromptService by lazy { SupportPromptService() }

        private val ZONE = ZoneId.systemDefault()
        private const val MIN_PRAYED_DAYS = 5
        private const val MAX_PROMPTS = 3
        private val COOLDOWN_DAYS = listOf(0, 30, 90)

        private const val TIMES_SHOWN_KEY = "holyday.support.timesShown"
        private const val LAST_SHOWN_KEY = "holyday.support.lastShown"
        private const val DISMISSED_FOREVER_KEY = "holyday.support.dismissedForever"
    }
}
