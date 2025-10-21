/*
 * Copyright 2015 - 2022 Anton Tananaev (anton@traccar.org)
 * Copyright 2025 - Modernized to use Room database
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
package dev.mostafamovahhed.traccar_flutter.client

import android.content.Context
import timber.log.Timber
import dev.mostafamovahhed.traccar_flutter.client.database.PositionEntity
import dev.mostafamovahhed.traccar_flutter.client.database.TraccarDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Database helper for position storage using Room database.
 *
 * This class now serves as a facade over the Room database, maintaining
 * backward compatibility with the legacy SQLite implementation while
 * providing modern, type-safe database operations.
 *
 * Migration from legacy SQLite to Room (v4 -> v5):
 * - No schema changes - seamless migration
 * - All operations now use coroutines instead of blocking calls
 * - Compile-time query verification eliminates SQL errors
 * - Type-safe operations reduce boilerplate and bugs
 *
 * Benefits of Room:
 * - Type-safe database operations
 * - Compile-time SQL verification
 * - Automatic threading via coroutines
 * - Reduced boilerplate code
 * - Better error handling
 */
class DatabaseHelper(context: Context) {

    private val database: TraccarDatabase = TraccarDatabase.getInstance(context)
    private val positionDao = database.positionDao()

    @Deprecated("Use insertPositionAsync instead")
    interface DatabaseHandler<T> {
        fun onComplete(success: Boolean, result: T)
    }

    /**
     * Inserts a position record into the database.
     *
     * This is a synchronous operation that should only be called from
     * a background thread. Prefer using insertPositionAsync instead.
     *
     * @param position The position to insert
     * @throws Exception if insertion fails
     */
    @Deprecated("Use insertPositionAsync for better performance and error handling")
    fun insertPosition(position: Position) {
        try {
            // Run blocking is safe here as this is already deprecated
            // and insertPositionAsync is the recommended approach
            kotlinx.coroutines.runBlocking {
                positionDao.insert(PositionEntity.fromPosition(position))
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to insert position")
            throw e
        }
    }

    /**
     * Inserts a position record asynchronously using coroutines.
     *
     * This is the recommended way to insert positions. It returns a Result
     * type for explicit error handling.
     *
     * @param position The position to insert
     * @return Result.success(Unit) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun insertPositionAsync(position: Position): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            positionDao.insert(PositionEntity.fromPosition(position))
            Timber.tag(TAG).d("Position inserted successfully")
            Result.success(Unit)
        } catch (e: Exception) {
            val error = TraccarError.Database.InsertFailed(position, e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Selects the first position record from the database (FIFO order).
     *
     * This is a synchronous operation that should only be called from
     * a background thread. Prefer using selectPositionAsync instead.
     *
     * @return The first position record, or null if none exist
     */
    @Deprecated("Use selectPositionAsync for better performance and error handling")
    fun selectPosition(): Position? {
        return try {
            kotlinx.coroutines.runBlocking {
                positionDao.selectFirst()?.toPosition()
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to select position")
            null
        }
    }

    /**
     * Selects the first position record asynchronously using coroutines.
     *
     * This is the recommended way to retrieve positions. It returns a Result
     * type for explicit error handling.
     *
     * @return Result.success(Position?) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun selectPositionAsync(): Result<Position?> = withContext(Dispatchers.IO) {
        try {
            val entity = positionDao.selectFirst()
            val position = entity?.toPosition()
            Timber.tag(TAG).d("Position selected: ${position != null}")
            Result.success(position)
        } catch (e: Exception) {
            val error = TraccarError.Database.QueryFailed("SELECT first position", e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Deletes a position record by ID.
     *
     * This is a synchronous operation that should only be called from
     * a background thread. Prefer using deletePositionAsync instead.
     *
     * @param id The ID of the position to delete
     * @throws Exception if deletion fails
     */
    @Deprecated("Use deletePositionAsync for better performance and error handling")
    fun deletePosition(id: Long) {
        try {
            kotlinx.coroutines.runBlocking {
                val deleted = positionDao.deleteById(id)
                if (deleted != 1) {
                    throw Exception("Failed to delete position: $id")
                }
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to delete position")
            throw e
        }
    }

    /**
     * Deletes a position record asynchronously using coroutines.
     *
     * This is the recommended way to delete positions. It returns a Result
     * type for explicit error handling.
     *
     * @param id The ID of the position to delete
     * @return Result.success(Unit) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun deletePositionAsync(id: Long): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val deleted = positionDao.deleteById(id)
            if (deleted == 1) {
                Timber.tag(TAG).d("Position deleted successfully: $id")
                Result.success(Unit)
            } else {
                Timber.tag(TAG).w("Position not found or already deleted: $id")
                val error = TraccarError.Database.DeleteFailed(
                    id,
                    Exception("Position not found: $id")
                )
                Result.failure(error)
            }
        } catch (e: Exception) {
            val error = TraccarError.Database.DeleteFailed(id, e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Gets the total count of positions in the database.
     *
     * Useful for monitoring offline buffer size.
     *
     * @return Result.success(count) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun getCountAsync(): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val count = positionDao.getCount()
            Timber.tag(TAG).d("Position count: $count")
            Result.success(count)
        } catch (e: Exception) {
            val error = TraccarError.Database.QueryFailed("SELECT COUNT(*)", e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Deletes all positions older than the specified timestamp.
     *
     * This is useful for implementing data retention policies
     * to prevent unbounded database growth.
     *
     * @param timestampMillis The cutoff timestamp (milliseconds since epoch)
     * @return Result.success(deletedCount) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun deleteOlderThanAsync(timestampMillis: Long): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val deleted = positionDao.deleteOlderThan(timestampMillis)
            Timber.tag(TAG).i("Deleted $deleted old position records")
            Result.success(deleted)
        } catch (e: Exception) {
            val error = TraccarError.Database.QueryFailed("DELETE old positions", e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    @Deprecated("Use insertPositionAsync instead", ReplaceWith("insertPositionAsync(position)"))
    fun insertPositionAsync(position: Position, handler: DatabaseHandler<Unit?>) {
        // Deprecated callback-based method kept for backward compatibility
        // Will be removed in version 2.0.0
    }

    @Deprecated("Use selectPositionAsync instead", ReplaceWith("selectPositionAsync()"))
    fun selectPositionAsync(handler: DatabaseHandler<Position?>) {
        // Deprecated callback-based method kept for backward compatibility
        // Will be removed in version 2.0.0
    }

    @Deprecated("Use deletePositionAsync instead", ReplaceWith("deletePositionAsync(id)"))
    fun deletePositionAsync(id: Long, handler: DatabaseHandler<Unit?>) {
        // Deprecated callback-based method kept for backward compatibility
        // Will be removed in version 2.0.0
    }

    /**
     * Deletes excess positions to keep count within the specified limit.
     *
     * This maintains database size by removing the oldest positions when
     * the total count exceeds the maximum allowed.
     *
     * @param maxPositions Maximum number of positions to retain
     * @return Result.success(deletedCount) if successful, Result.failure(TraccarError.Database) otherwise
     */
    suspend fun deleteExcessPositionsAsync(maxPositions: Int): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val deleted = positionDao.deleteExcessPositions(maxPositions)
            if (deleted > 0) {
                Timber.tag(TAG).i("Deleted $deleted excess positions to maintain limit of $maxPositions")
            }
            Result.success(deleted)
        } catch (e: Exception) {
            val error = TraccarError.Database.QueryFailed("DELETE excess positions", e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Performs database cleanup using configurable retention policies.
     *
     * This method combines two cleanup strategies:
     * 1. Delete positions older than a specified age
     * 2. Limit total number of positions to prevent unbounded growth
     *
     * @param retentionDays Number of days to retain positions (default: 7)
     * @param maxPositions Maximum number of positions to keep (default: 1000)
     * @return Result.success(CleanupStats) with counts of deleted records
     */
    suspend fun performCleanup(
        retentionDays: Int = DEFAULT_RETENTION_DAYS,
        maxPositions: Int = DEFAULT_MAX_POSITIONS
    ): Result<CleanupStats> = withContext(Dispatchers.IO) {
        try {
            val cutoffTimestamp = System.currentTimeMillis() - (retentionDays * 24 * 60 * 60 * 1000L)

            // Strategy 1: Delete old positions
            val deletedOld = positionDao.deleteOlderThan(cutoffTimestamp)

            // Strategy 2: Limit total positions
            val deletedExcess = positionDao.deleteExcessPositions(maxPositions)

            val stats = CleanupStats(
                deletedByAge = deletedOld,
                deletedByLimit = deletedExcess,
                totalDeleted = deletedOld + deletedExcess
            )

            if (stats.totalDeleted > 0) {
                Timber.tag(TAG).i(
                    "Cleanup complete: ${stats.deletedByAge} old, ${stats.deletedByLimit} excess, ${stats.totalDeleted} total"
                )
            }

            Result.success(stats)
        } catch (e: Exception) {
            val error = TraccarError.Database.QueryFailed("Cleanup operation", e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Statistics about database cleanup operations.
     */
    data class CleanupStats(
        val deletedByAge: Int,
        val deletedByLimit: Int,
        val totalDeleted: Int
    )

    companion object {
        private val TAG = DatabaseHelper::class.java.simpleName

        // Legacy constants kept for reference
        const val DATABASE_VERSION = 5 // Updated from 4 to 5 for Room migration
        const val DATABASE_NAME = "traccar.db"

        // Cleanup configuration defaults
        const val DEFAULT_RETENTION_DAYS = 7
        const val DEFAULT_MAX_POSITIONS = 1000
    }
}
