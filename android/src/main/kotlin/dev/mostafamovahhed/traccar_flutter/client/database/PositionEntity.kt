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

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import dev.mostafamovahhed.traccar_flutter.client.Position
import java.util.Date

/**
 * Room entity representing a position record in the local database.
 *
 * This entity maintains compatibility with the existing SQLite schema
 * to enable seamless migration from the legacy DatabaseHelper.
 *
 * Benefits of Room over raw SQLite:
 * - Compile-time SQL query verification
 * - Type-safe database operations
 * - Automatic mapping between objects and database rows
 * - Built-in support for coroutines and Flow
 * - Reduced boilerplate code
 */
@Entity(tableName = "position")
data class PositionEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0,

    @ColumnInfo(name = "deviceId")
    val deviceId: String,

    @ColumnInfo(name = "time")
    val time: Date,

    @ColumnInfo(name = "latitude")
    val latitude: Double,

    @ColumnInfo(name = "longitude")
    val longitude: Double,

    @ColumnInfo(name = "altitude")
    val altitude: Double,

    @ColumnInfo(name = "speed")
    val speed: Double,

    @ColumnInfo(name = "course")
    val course: Double,

    @ColumnInfo(name = "accuracy")
    val accuracy: Double,

    @ColumnInfo(name = "battery")
    val battery: Double,

    @ColumnInfo(name = "charging")
    val charging: Boolean,

    @ColumnInfo(name = "mock")
    val mock: Boolean
) {
    /**
     * Converts this entity to a Position domain object.
     */
    fun toPosition(): Position {
        return Position(
            id = id,
            deviceId = deviceId,
            time = time,
            latitude = latitude,
            longitude = longitude,
            altitude = altitude,
            speed = speed,
            course = course,
            accuracy = accuracy,
            battery = battery,
            charging = charging,
            mock = mock
        )
    }

    companion object {
        /**
         * Converts a Position domain object to a PositionEntity.
         */
        fun fromPosition(position: Position): PositionEntity {
            return PositionEntity(
                id = position.id,
                deviceId = position.deviceId,
                time = position.time,
                latitude = position.latitude,
                longitude = position.longitude,
                altitude = position.altitude,
                speed = position.speed,
                course = position.course,
                accuracy = position.accuracy,
                battery = position.battery,
                charging = position.charging,
                mock = position.mock
            )
        }
    }
}
