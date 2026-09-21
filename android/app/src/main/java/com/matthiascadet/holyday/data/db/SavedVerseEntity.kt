package com.matthiascadet.holyday.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "saved_verses")
data class SavedVerseEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val text: String,
    val reference: String,
    val note: String = "",
    val savedAt: Long = System.currentTimeMillis(),
)
