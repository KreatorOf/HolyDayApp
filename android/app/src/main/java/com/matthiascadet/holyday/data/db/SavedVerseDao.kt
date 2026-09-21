package com.matthiascadet.holyday.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface SavedVerseDao {
    @Query("SELECT * FROM saved_verses ORDER BY savedAt DESC")
    fun observeAll(): Flow<List<SavedVerseEntity>>

    @Query("SELECT * FROM saved_verses WHERE text = :text AND reference = :reference LIMIT 1")
    suspend fun find(text: String, reference: String): SavedVerseEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(verse: SavedVerseEntity)

    @Update suspend fun update(verse: SavedVerseEntity)
    @Delete suspend fun delete(verse: SavedVerseEntity)
    @Query("DELETE FROM saved_verses") suspend fun deleteAll()
}
