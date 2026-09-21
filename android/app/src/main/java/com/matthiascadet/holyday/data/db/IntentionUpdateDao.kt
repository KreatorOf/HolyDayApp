package com.matthiascadet.holyday.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface IntentionUpdateDao {
    @Query("SELECT * FROM intention_updates WHERE intentionId = :intentionId ORDER BY createdAt DESC")
    fun observeFor(intentionId: String): Flow<List<IntentionUpdateEntity>>

    @Insert suspend fun insert(update: IntentionUpdateEntity)
    @Delete suspend fun delete(update: IntentionUpdateEntity)
}
