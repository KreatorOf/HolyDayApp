package com.matthiascadet.holyday.data.model

import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.time.temporal.TemporalAdjusters
import java.util.UUID

private val ZONE = ZoneId.systemDefault()

/**
 * Période d'observation des statistiques. Le "bucket" fixe la granularité des courbes :
 * quotidien sur 1 semaine, hebdomadaire jusqu'à 6 mois, mensuel au-delà.
 */
enum class StatsPeriod(val id: String) {
    WEEK("week"),
    MONTH("month"),
    SIX_MONTHS("sixMonths"),
    YEAR("year"),
    ALL("all");

    val cutoffMillis: Long?
        get() {
            val today = LocalDate.now(ZONE)
            val date = when (this) {
                WEEK -> today.minusDays(7)
                MONTH -> today.minusDays(30)
                SIX_MONTHS -> today.minusDays(180)
                YEAR -> today.minusDays(365)
                ALL -> return null
            }
            return date.atStartOfDay(ZONE).toInstant().toEpochMilli()
        }

    val bucket: StatsBucket
        get() = when (this) {
            WEEK -> StatsBucket.DAY
            MONTH, SIX_MONTHS -> StatsBucket.WEEK
            YEAR, ALL -> StatsBucket.MONTH
        }
}

enum class StatsBucket { DAY, WEEK, MONTH }

/** Un point d'une courbe : la date de début de bucket (epoch millis) et la valeur agrégée. */
data class StatPoint(val id: UUID = UUID.randomUUID(), val dateMillis: Long, val value: Double)

/** Part d'une émotion dans la répartition globale sur la période. */
data class EmotionTotal(val id: UUID = UUID.randomUUID(), val emotion: Emotion, val count: Int)

/** Agrégateur pur (sans UI) : transforme une liste de `PrayerEntryEntity` en séries prêtes à tracer. */
object PrayerStats {

    fun activity(entries: List<PrayerEntryEntity>, period: StatsPeriod): List<StatPoint> {
        return filtered(entries, period)
            .groupBy { bucketStart(it.date, period.bucket) }
            .map { (date, group) -> StatPoint(dateMillis = date, value = group.size.toDouble()) }
            .sortedBy { it.dateMillis }
    }

    /** Triée dans l'ordre stable de `Emotion.entries` pour des couleurs de secteurs cohérentes. */
    fun emotionTotals(entries: List<PrayerEntryEntity>, period: StatsPeriod): List<EmotionTotal> {
        val counts = filtered(entries, period)
            .mapNotNull { it.emotion }
            .groupingBy { it }
            .eachCount()
        return Emotion.entries.mapNotNull { emotion ->
            counts[emotion]?.let { EmotionTotal(emotion = emotion, count = it) }
        }
    }

    private fun filtered(entries: List<PrayerEntryEntity>, period: StatsPeriod): List<PrayerEntryEntity> {
        val cutoff = period.cutoffMillis ?: return entries
        return entries.filter { it.date >= cutoff }
    }

    private fun bucketStart(dateMillis: Long, bucket: StatsBucket): Long {
        val date = Instant.ofEpochMilli(dateMillis).atZone(ZONE).toLocalDate()
        val start = when (bucket) {
            StatsBucket.DAY -> date
            StatsBucket.WEEK -> date.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
            StatsBucket.MONTH -> date.withDayOfMonth(1)
        }
        return start.atStartOfDay(ZONE).toInstant().toEpochMilli()
    }
}

/** Nombre de jours entiers entre deux instants, au fuseau horaire de l'appareil (équivalent `Calendar.dateComponents([.day])`). */
fun daysBetween(from: Instant, to: Instant): Long =
    ChronoUnit.DAYS.between(from.atZone(ZONE).toLocalDate(), to.atZone(ZONE).toLocalDate())
