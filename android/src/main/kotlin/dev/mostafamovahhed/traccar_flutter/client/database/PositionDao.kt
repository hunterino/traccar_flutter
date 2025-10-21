/*
 * Copyright 2025 - Room database implementation
 * Based on original Traccar code by Anton Tananaev (anton@traccar.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package dev.mostafamovahhed.traccar_flutter.client.database

import androidx.room.*

/**
 * Data Access Object for position records.
 *
 * Room automatically generates implementation of this interface at compile time.
 * All methods are suspend functions for coroutine support, eliminating the need
 * for manual thread handling.
 *
 * Benefits:
 * - Compile-time verification of SQL queries
 * - Type-safe operations
 * - Automatic threading via coroutines
 * - No manual Cursor management required
 */
@Dao
interface PositionDao {

    /**
     * Inserts a new position record.
     *
     * @param position The position entity to insert
     * @return The row ID of the inserted position
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(position: PositionEntity): Long

    /**
     * Selects the first position record (oldest).
     *
     * This is used for retrieving positions from the offline buffer
     * for transmission to the server (FIFO order).
     *
     * @return The first position record, or null if none exist
     */
    @Query("SELECT * FROM position ORDER BY id LIMIT 1")
    suspend fun selectFirst(): PositionEntity?

    /**
     * Deletes a position record by ID.
     *
     * @param id The ID of the position to delete
     * @return The number of rows deleted (should be 1 if successful)
     */
    @Query("DELETE FROM position WHERE id = :id")
    suspend fun deleteById(id: Long): Int

    /**
     * Gets the total count of positions in the database.
     *
     * Useful for monitoring offline buffer size.
     *
     * @return The total number of position records
     */
    @Query("SELECT COUNT(*) FROM position")
    suspend fun getCount(): Int

    /**
     * Deletes all positions older than the specified timestamp.
     *
     * This is useful for implementing data retention policies
     * to prevent unbounded database growth.
     *
     * @param timestamp The cutoff timestamp (milliseconds since epoch)
     * @return The number of rows deleted
     */
    @Query("DELETE FROM position WHERE time < :timestamp")
    suspend fun deleteOlderThan(timestamp: Long): Int

    /**
     * Deletes all position records.
     *
     * WARNING: This is a destructive operation used primarily for testing.
     */
    @Query("DELETE FROM position")
    suspend fun deleteAll()

    /**
     * Deletes the oldest positions to keep count within specified limit.
     *
     * This query deletes all positions except the newest [limit] records.
     * Useful for implementing maximum database size policies.
     *
     * @param limit The maximum number of positions to retain
     * @return The number of rows deleted
     */
    @Query("""
        DELETE FROM position
        WHERE id NOT IN (
            SELECT id FROM position
            ORDER BY time DESC
            LIMIT :limit
        )
    """)
    suspend fun deleteExcessPositions(limit: Int): Int
}
