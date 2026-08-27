package com.matthiascadet.holyday.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Équivalent du `ModelContainer` SwiftData de `HolyDayApp.swift`.
 * Base SQLite locale, jamais synchronisée : toutes les données restent sur l'appareil
 * (voir la section confidentialité "local-first" des mentions légales).
 */
@Database(
    entities = [PrayerEntryEntity::class, PrayerIntentionEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun prayerEntryDao(): PrayerEntryDao
    abstract fun prayerIntentionDao(): PrayerIntentionDao

    companion object {
        @Volatile private var instance: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "holyday.db",
                ).build().also { instance = it }
            }
    }
}
