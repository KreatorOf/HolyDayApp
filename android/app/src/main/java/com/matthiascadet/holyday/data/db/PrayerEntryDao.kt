package com.matthiascadet.holyday.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface PrayerEntryDao {
    @Query("SELECT * FROM prayer_entries ORDER BY date DESC")
    fun observeAll(): Flow<List<PrayerEntryEntity>>

    @Query("SELECT * FROM prayer_entries ORDER BY date DESC")
    suspend fun getAll(): List<PrayerEntryEntity>

    @Query("SELECT * FROM prayer_entries WHERE id = :id")
    suspend fun getById(id: String): PrayerEntryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entry: PrayerEntryEntity)

    @Update
    suspend fun update(entry: PrayerEntryEntity)

    @Delete
    suspend fun delete(entry: PrayerEntryEntity)

    @Query("DELETE FROM prayer_entries")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM prayer_entries")
    suspend fun count(): Int
}
