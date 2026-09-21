package com.matthiascadet.holyday.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Équivalent du `ModelContainer` SwiftData de `HolyDayApp.swift`.
 * Base SQLite locale, jamais synchronisée : toutes les données restent sur l'appareil
 * (voir la section confidentialité "local-first" des mentions légales).
 */
@Database(
    entities = [
        PrayerEntryEntity::class,
        PrayerIntentionEntity::class,
        SavedVerseEntity::class,
        IntentionUpdateEntity::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun prayerEntryDao(): PrayerEntryDao
    abstract fun prayerIntentionDao(): PrayerIntentionDao
    abstract fun savedVerseDao(): SavedVerseDao
    abstract fun intentionUpdateDao(): IntentionUpdateDao

    companion object {
        @Volatile private var instance: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "holyday.db",
                ).addMigrations(MIGRATION_1_2).build().also { instance = it }
            }

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `saved_verses` (`id` TEXT NOT NULL, `text` TEXT NOT NULL, `reference` TEXT NOT NULL, `note` TEXT NOT NULL, `savedAt` INTEGER NOT NULL, PRIMARY KEY(`id`))",
                )
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `intention_updates` (`id` TEXT NOT NULL, `intentionId` TEXT NOT NULL, `text` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`intentionId`) REFERENCES `prayer_intentions`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE)",
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_intention_updates_intentionId` ON `intention_updates` (`intentionId`)")
            }
        }
    }
}
