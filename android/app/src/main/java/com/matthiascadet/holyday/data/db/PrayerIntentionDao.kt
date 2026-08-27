package com.matthiascadet.holyday.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface PrayerIntentionDao {
    @Query("SELECT * FROM prayer_intentions ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<PrayerIntentionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(intention: PrayerIntentionEntity)

    @Update
    suspend fun update(intention: PrayerIntentionEntity)

    @Delete
    suspend fun delete(intention: PrayerIntentionEntity)

    @Query("DELETE FROM prayer_intentions")
    suspend fun deleteAll()
}
