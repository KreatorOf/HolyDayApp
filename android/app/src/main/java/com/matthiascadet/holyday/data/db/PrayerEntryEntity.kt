package com.matthiascadet.holyday.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.matthiascadet.holyday.data.model.Emotion
import java.util.UUID

/** Icônes de catégorie de prière — équivalent des noms SF Symbol stockés côté iOS (`stepIcon`). */
object PrayerStepIcon {
    const val FREE_PRAYER = "free_prayer"
    const val ADORATION = "adoration"
    const val CONFESSION = "confession"
    const val THANKSGIVING = "thanksgiving"
    const val SUPPLICATION = "supplication"
}

enum class TitleSource {
    FALLBACK, AI, USER;

    companion object {
        fun fromRaw(raw: String): TitleSource = entries.find { it.name.equals(raw, ignoreCase = true) } ?: FALLBACK
    }
}

/**
 * Équivalent Room du `@Model` SwiftData `PrayerEntry` — cœur du journal de prière.
 * `id` est généré côté app (UUID) car Room n'a pas d'équivalent à l'identité d'objet SwiftData.
 */
@Entity(tableName = "prayer_entries")
data class PrayerEntryEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val stepTitle: String,
    val stepIcon: String,
    val stepColorName: String,
    val text: String,
    val date: Long,
    val isAnswered: Boolean = false,
    val answeredAt: Long? = null,
    val durationSeconds: Double = 0.0,
    val emotionRaw: String? = null,
    val verseReference: String? = null,
    val customTitle: String? = null,
    val titleSourceRaw: String = TitleSource.FALLBACK.name,
) {
    val emotion: Emotion? get() = Emotion.fromId(emotionRaw)
    val titleSource: TitleSource get() = TitleSource.fromRaw(titleSourceRaw)
    val displayTitle: String get() = customTitle ?: stepTitle
    val isFreePrayer: Boolean get() = stepIcon == PrayerStepIcon.FREE_PRAYER

    companion object {
        /** Repli de titre quand l'IA est indisponible : première ligne non vide, tronquée à 40 caractères. */
        fun fallbackTitle(from: String): String {
            val firstLine = from.lineSequence().firstOrNull()?.trim() ?: ""
            val limit = 40
            if (firstLine.length <= limit) return firstLine
            return firstLine.take(limit).trim() + "…"
        }
    }
}
