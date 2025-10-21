/*
 * Copyright 2025 - Structured error handling implementation
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

/**
 * Sealed class hierarchy for Traccar errors.
 *
 * Benefits of sealed classes for error handling:
 * - Exhaustive when() expressions - compiler ensures all cases are handled
 * - Type-safe error information - no string parsing or error code lookups
 * - Rich error context - each error type can carry relevant data
 * - Better IDE support - autocomplete shows all possible error types
 * - Easier testing - can create specific error instances for test cases
 *
 * Usage:
 * ```kotlin
 * when (val error = result.exceptionOrNull() as? TraccarError) {
 *     is TraccarError.Network.ServerError -> // Handle server error
 *     is TraccarError.Network.Timeout -> // Handle timeout
 *     is TraccarError.Database.InsertFailed -> // Handle DB error
 *     is TraccarError.Location.PermissionDenied -> // Handle permission
 *     null -> // Success case
 * }
 * ```
 */
sealed class TraccarError(message: String, cause: Throwable? = null) : Exception(message, cause) {

    /**
     * Network-related errors.
     */
    sealed class Network(message: String, cause: Throwable? = null) : TraccarError(message, cause) {

        /**
         * HTTP 4xx client errors (invalid request, unauthorized, etc.)
         */
        data class ClientError(
            val statusCode: Int,
            val responseMessage: String? = null
        ) : Network("Client error: $statusCode ${responseMessage ?: ""}")

        /**
         * HTTP 5xx server errors (internal server error, service unavailable, etc.)
         */
        data class ServerError(
            val statusCode: Int,
            val responseMessage: String? = null
        ) : Network("Server error: $statusCode ${responseMessage ?: ""}")

        /**
         * Network timeout (connection timeout, read timeout, etc.)
         */
        data class Timeout(
            val timeoutMillis: Long
        ) : Network("Request timeout after ${timeoutMillis}ms")

        /**
         * Connection failed (no network, host unreachable, etc.)
         */
        data class ConnectionFailed(
            val reason: String
        ) : Network("Connection failed: $reason")

        /**
         * Unexpected network error (malformed URL, SSL error, etc.)
         */
        data class Unexpected(
            val originalException: Exception
        ) : Network("Unexpected network error: ${originalException.message}", originalException)
    }

    /**
     * Database-related errors.
     */
    sealed class Database(message: String, cause: Throwable? = null) : TraccarError(message, cause) {

        /**
         * Failed to insert a position record.
         */
        data class InsertFailed(
            val position: Position?,
            val originalException: Exception
        ) : Database("Failed to insert position: ${originalException.message}", originalException)

        /**
         * Failed to delete a position record.
         */
        data class DeleteFailed(
            val positionId: Long,
            val originalException: Exception
        ) : Database("Failed to delete position $positionId: ${originalException.message}", originalException)

        /**
         * Failed to query position records.
         */
        data class QueryFailed(
            val query: String,
            val originalException: Exception
        ) : Database("Failed to execute query '$query': ${originalException.message}", originalException)

        /**
         * Database migration failed.
         */
        data class MigrationFailed(
            val fromVersion: Int,
            val toVersion: Int,
            val originalException: Exception
        ) : Database("Failed to migrate database from v$fromVersion to v$toVersion: ${originalException.message}", originalException)

        /**
         * Database corrupted or inaccessible.
         */
        data class Corrupted(
            val originalException: Exception
        ) : Database("Database corrupted or inaccessible: ${originalException.message}", originalException)
    }

    /**
     * Location-related errors.
     */
    sealed class Location(message: String, cause: Throwable? = null) : TraccarError(message, cause) {

        /**
         * Location permission denied by user.
         */
        data class PermissionDenied(
            val permissionType: String
        ) : Location("Location permission denied: $permissionType")

        /**
         * Location services disabled on device.
         */
        object ServicesDisabled : Location("Location services are disabled")

        /**
         * Google Play Services not available or outdated.
         */
        data class PlayServicesUnavailable(
            val errorCode: Int
        ) : Location("Google Play Services unavailable: error code $errorCode")

        /**
         * Failed to obtain location fix.
         */
        data class FixFailed(
            val reason: String
        ) : Location("Failed to obtain location: $reason")

        /**
         * Location provider unavailable (GPS, Network, etc.)
         */
        data class ProviderUnavailable(
            val provider: String
        ) : Location("Location provider unavailable: $provider")
    }

    /**
     * Configuration-related errors.
     */
    sealed class Configuration(message: String, cause: Throwable? = null) : TraccarError(message, cause) {

        /**
         * Invalid device ID.
         */
        data class InvalidDeviceId(
            val deviceId: String?
        ) : Configuration("Invalid device ID: ${deviceId ?: "null"}")

        /**
         * Invalid server URL.
         */
        data class InvalidServerUrl(
            val url: String?
        ) : Configuration("Invalid server URL: ${url ?: "null"}")

        /**
         * Invalid tracking interval.
         */
        data class InvalidInterval(
            val interval: Long
        ) : Configuration("Invalid tracking interval: $interval (must be > 0)")

        /**
         * Invalid distance threshold.
         */
        data class InvalidDistance(
            val distance: Int
        ) : Configuration("Invalid distance: $distance (must be >= 0)")

        /**
         * Service not initialized.
         */
        object NotInitialized : Configuration("Traccar service not initialized - call init() first")

        /**
         * Service already running.
         */
        object AlreadyRunning : Configuration("Tracking service is already running")
    }

    /**
     * Service lifecycle errors.
     */
    sealed class Service(message: String, cause: Throwable? = null) : TraccarError(message, cause) {

        /**
         * Failed to start tracking service.
         */
        data class StartFailed(
            val reason: String,
            val originalException: Exception? = null
        ) : Service("Failed to start tracking service: $reason", originalException)

        /**
         * Failed to stop tracking service.
         */
        data class StopFailed(
            val reason: String,
            val originalException: Exception? = null
        ) : Service("Failed to stop tracking service: $reason", originalException)

        /**
         * Service crashed or stopped unexpectedly.
         */
        data class Crashed(
            val originalException: Exception
        ) : Service("Tracking service crashed: ${originalException.message}", originalException)
    }

    /**
     * Converts this error to a user-friendly message.
     */
    fun toUserMessage(): String {
        return when (this) {
            is Network.ClientError -> "Invalid request to server (error $statusCode)"
            is Network.ServerError -> "Server error (error $statusCode). Please try again later."
            is Network.Timeout -> "Request timed out. Please check your connection."
            is Network.ConnectionFailed -> "No connection to server. Please check your network."
            is Network.Unexpected -> "Network error: ${originalException.message}"

            is Database.InsertFailed -> "Failed to save location data"
            is Database.DeleteFailed -> "Failed to remove location data"
            is Database.QueryFailed -> "Failed to retrieve location data"
            is Database.MigrationFailed -> "Database upgrade failed. You may need to reinstall the app."
            is Database.Corrupted -> "Database corrupted. You may need to reinstall the app."

            is Location.PermissionDenied -> "Location permission required: $permissionType"
            is Location.ServicesDisabled -> "Please enable location services"
            is Location.PlayServicesUnavailable -> "Google Play Services not available"
            is Location.FixFailed -> "Unable to determine location: $reason"
            is Location.ProviderUnavailable -> "Location provider unavailable: $provider"

            is Configuration.InvalidDeviceId -> "Invalid device ID"
            is Configuration.InvalidServerUrl -> "Invalid server URL"
            is Configuration.InvalidInterval -> "Invalid tracking interval"
            is Configuration.InvalidDistance -> "Invalid distance threshold"
            is Configuration.NotInitialized -> "Service not initialized"
            is Configuration.AlreadyRunning -> "Tracking is already running"

            is Service.StartFailed -> "Failed to start tracking: $reason"
            is Service.StopFailed -> "Failed to stop tracking: $reason"
            is Service.Crashed -> "Tracking service crashed"
        }
    }

    /**
     * Converts this error to a developer-friendly diagnostic message.
     */
    fun toDiagnosticMessage(): String {
        return buildString {
            append("[${this@TraccarError.javaClass.simpleName}] ")
            append(message)
            cause?.let { append(" | Cause: ${it.javaClass.simpleName}: ${it.message}") }
        }
    }
}

/**
 * Extension function to wrap exceptions in TraccarError types.
 */
fun Exception.toTraccarError(): TraccarError {
    return when (this) {
        is TraccarError -> this
        is java.net.SocketTimeoutException -> TraccarError.Network.Timeout(15000)
        is java.io.IOException -> TraccarError.Network.ConnectionFailed(message ?: "Unknown IO error")
        is SecurityException -> TraccarError.Location.PermissionDenied(message ?: "Unknown permission")
        else -> TraccarError.Network.Unexpected(this)
    }
}
