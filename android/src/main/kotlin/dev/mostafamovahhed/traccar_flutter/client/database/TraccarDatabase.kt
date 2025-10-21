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

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Room database for Traccar position storage.
 *
 * This database provides type-safe access to position records with
 * automatic migration from the legacy SQLite implementation.
 *
 * Version history:
 * - Version 4: Legacy SQLite schema (inherited from DatabaseHelper)
 * - Version 5: Room migration with no schema changes (seamless upgrade)
 *
 * Benefits over raw SQLite:
 * - Compile-time query verification prevents runtime SQL errors
 * - Type-safe operations eliminate casting and null-handling boilerplate
 * - Automatic migration management with rollback support
 * - Coroutine support for non-blocking database operations
 * - Observable queries with Flow for reactive UI updates
 */
@Database(
    entities = [PositionEntity::class],
    version = 5,
    exportSchema = true
)
@TypeConverters(DateConverters::class)
abstract class TraccarDatabase : RoomDatabase() {

    /**
     * Provides access to position database operations.
     */
    abstract fun positionDao(): PositionDao

    companion object {
        private const val DATABASE_NAME = "traccar.db"

        @Volatile
        private var INSTANCE: TraccarDatabase? = null

        /**
         * Migration from version 4 (legacy SQLite) to version 5 (Room).
         *
         * The schema is identical, so no SQL changes are needed.
         * This migration exists solely to mark the transition to Room.
         */
        private val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // No schema changes needed - Room uses the same table structure
                // This migration just marks the transition from legacy SQLite to Room
            }
        }

        /**
         * Gets or creates the singleton database instance.
         *
         * Uses double-checked locking for thread-safe singleton creation.
         *
         * @param context Application context
         * @return The TraccarDatabase instance
         */
        fun getInstance(context: Context): TraccarDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: buildDatabase(context).also { INSTANCE = it }
            }
        }

        private fun buildDatabase(context: Context): TraccarDatabase {
            return Room.databaseBuilder(
                context.applicationContext,
                TraccarDatabase::class.java,
                DATABASE_NAME
            )
                .addMigrations(MIGRATION_4_5)
                .fallbackToDestructiveMigration() // For development only - remove in production
                .build()
        }

        /**
         * Closes and clears the database instance.
         *
         * Used primarily for testing to ensure clean state.
         */
        @Synchronized
        fun clearInstance() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}
