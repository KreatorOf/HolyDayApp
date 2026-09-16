package com.matthiascadet.holyday.service.notification

import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.VerseCorpus
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Ce que l'app sait de la vie de prière au moment de choisir le contenu d'un rappel. Sur Android
 * il est lu au déclenchement (le récepteur tourne dans le process de l'app), là où iOS doit le
 * figer à la planification — le résultat perçu est le même.
 */
data class ReminderContext(
    val lastPrayerDate: LocalDate? = null,
    val lastEmotion: Emotion? = null,
    val lastEmotionDate: LocalDate? = null,
    val oldestOpenIntentionDate: LocalDate? = null,
)

sealed interface ReminderKind {
    /** Question de réflexion tournante (comportement historique). */
    data object Question : ReminderKind

    /** Verset du thème de la dernière émotion déclarée ; index dans `VerseCorpus.all`. */
    data class Verse(val corpusIndex: Int) : ReminderKind

    /** Invitation à revenir sur ses intentions — sans jamais en citer le texte (écran verrouillé). */
    data object Intentions : ReminderKind
}

/**
 * Règles de contenu des rappels, pures et déterministes : miroir exact de `ReminderPlanner.swift`.
 * Toute modification doit être portée des deux côtés.
 */
object ReminderPlanner {
    /** Jours de suivi après une prière portant une émotion. Court à dessein : on accompagne, on ne ressasse pas. */
    const val EMOTION_FOLLOW_UP_DAYS = 2L

    /** Âge minimal d'une intention ouverte avant qu'on invite à y revenir. */
    const val INTENTION_MINIMUM_AGE_DAYS = 7L

    /** Jour fixe, pour que l'invitation reste hebdomadaire. */
    val INTENTION_DAY: DayOfWeek = DayOfWeek.SUNDAY

    /**
     * `null` : pas de rappel ce jour-là (l'utilisateur a déjà prié — on ne relance pas).
     * Priorité : silence > verset d'émotion > intentions du dimanche > question.
     */
    fun kindFor(day: LocalDate, context: ReminderContext): ReminderKind? {
        if (context.lastPrayerDate == day) return null

        val emotion = context.lastEmotion
        val emotionDate = context.lastEmotionDate
        if (emotion != null && emotionDate != null) {
            val elapsed = ChronoUnit.DAYS.between(emotionDate, day)
            if (elapsed in 1..EMOTION_FOLLOW_UP_DAYS) {
                verseIndex(emotion, day)?.let { return ReminderKind.Verse(it) }
            }
        }

        val oldest = context.oldestOpenIntentionDate
        if (day.dayOfWeek == INTENTION_DAY && oldest != null &&
            ChronoUnit.DAYS.between(oldest, day) >= INTENTION_MINIMUM_AGE_DAYS
        ) {
            return ReminderKind.Intentions
        }

        return ReminderKind.Question
    }

    /**
     * Choix par jour de l'année et non via les pioches de `VerseService` : préparer un rappel ne
     * doit pas consommer la pioche que l'utilisateur voit dans l'app.
     */
    fun verseIndex(emotion: Emotion, day: LocalDate): Int? {
        val pool = VerseCorpus.all.indices.filter { VerseCorpus.all[it].emotionTags.contains(emotion.id) }
        if (pool.isEmpty()) return null
        return pool[day.dayOfYear % pool.size]
    }
}
