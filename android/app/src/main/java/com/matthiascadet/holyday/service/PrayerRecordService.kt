package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.prefs.AppPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/**
 * Suivi minimal et sans pression des prières : retient le nombre de jours distincts où
 * l'utilisateur a prié et la date de la dernière prière (miroir vers les widgets via
 * `WidgetSyncService`). Aucune notion de série/streak — prier reste libre, sans compteur de
 * jours consécutifs ni culpabilisation. `totalPrayedDays` ne sert que de signal discret pour
 * la sollicitation de don.
 */
object PrayerRecordService {
    private const val LAST_PRAYER_DATE_KEY = "holyday.lastPrayerDate"
    private const val TOTAL_PRAYED_DAYS_KEY = "holyday.totalPrayedDays"

    private val zone = ZoneId.systemDefault()

    private val _totalPrayedDays = MutableStateFlow(0)
    val totalPrayedDays: StateFlow<Int> = _totalPrayedDays.asStateFlow()

    private val _lastRecordToken = MutableStateFlow<UUID?>(null)
    val lastRecordToken: StateFlow<UUID?> = _lastRecordToken.asStateFlow()

    init {
        recalculate()
    }

    val isPrayedToday: Boolean
        get() {
            val lastMillis = AppPreferences.raw.getLong(LAST_PRAYER_DATE_KEY, -1L)
            if (lastMillis < 0) return false
            val lastDate = Instant.ofEpochMilli(lastMillis).atZone(zone).toLocalDate()
            return lastDate == LocalDate.now(zone)
        }

    /**
     * Retourne `true` uniquement si un nouveau jour prié vient d'être enregistré (sinon l'appel
     * est sans effet car déjà prié aujourd'hui) — sert à ne déclencher la sollicitation de don
     * qu'à un vrai moment de fin de prière.
     */
    fun recordPrayer(): Boolean {
        val prefs = AppPreferences.raw
        val today = LocalDate.now(zone)
        val lastMillis = prefs.getLong(LAST_PRAYER_DATE_KEY, -1L)
        if (lastMillis >= 0) {
            val lastDate = Instant.ofEpochMilli(lastMillis).atZone(zone).toLocalDate()
            if (lastDate == today) return false
        }

        val todayMillis = today.atStartOfDay(zone).toInstant().toEpochMilli()
        prefs.edit().putLong(LAST_PRAYER_DATE_KEY, todayMillis).apply()
        WidgetSyncService.setLastPrayerDate(todayMillis)

        val newTotal = _totalPrayedDays.value + 1
        prefs.edit().putInt(TOTAL_PRAYED_DAYS_KEY, newTotal).apply()
        _totalPrayedDays.value = newTotal

        _lastRecordToken.value = UUID.randomUUID()
        return true
    }

    fun refresh() = recalculate()

    fun reset() {
        AppPreferences.raw.edit()
            .remove(LAST_PRAYER_DATE_KEY)
            .remove(TOTAL_PRAYED_DAYS_KEY)
            .apply()
        recalculate()
    }

    private fun recalculate() {
        val prefs = AppPreferences.raw
        _totalPrayedDays.value = prefs.getInt(TOTAL_PRAYED_DAYS_KEY, 0)
        val lastMillis = prefs.getLong(LAST_PRAYER_DATE_KEY, -1L).takeIf { it >= 0 }
        WidgetSyncService.setLastPrayerDate(lastMillis)
    }
}
