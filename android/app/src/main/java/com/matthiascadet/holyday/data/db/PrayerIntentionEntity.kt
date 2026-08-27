package com.matthiascadet.holyday.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

/** Équivalent Room du `@Model` SwiftData `PrayerIntention`. */
@Entity(tableName = "prayer_intentions")
data class PrayerIntentionEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val text: String,
    val createdAt: Long,
    val isAnswered: Boolean = false,
    val answeredAt: Long? = null,
)
