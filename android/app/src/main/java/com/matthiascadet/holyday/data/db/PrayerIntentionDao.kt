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

    @Query("SELECT * FROM prayer_intentions WHERE isAnswered = 0 ORDER BY createdAt ASC LIMIT 1")
    suspend fun oldestOpen(): PrayerIntentionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(intention: PrayerIntentionEntity)

    @Update
    suspend fun update(intention: PrayerIntentionEntity)

    @Delete
    suspend fun delete(intention: PrayerIntentionEntity)

    @Query("DELETE FROM prayer_intentions")
    suspend fun deleteAll()
}
