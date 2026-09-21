package com.matthiascadet.holyday.data.db

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "intention_updates",
    foreignKeys = [
        ForeignKey(
            entity = PrayerIntentionEntity::class,
            parentColumns = ["id"],
            childColumns = ["intentionId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("intentionId")],
)
data class IntentionUpdateEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val intentionId: String,
    val text: String,
    val createdAt: Long = System.currentTimeMillis(),
)
