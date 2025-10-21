/*
 * Copyright 2025 - Modern implementation using FusedLocationProviderClient
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
package dev.mostafamovahhed.traccar_flutter.client

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import timber.log.Timber
import com.google.android.gms.location.*

/**
 * Modern position provider using Google Play Services FusedLocationProviderClient.
 *
 * Benefits over deprecated LocationManager:
 * - Better battery efficiency through automatic provider selection
 * - More accurate locations using sensor fusion
 * - Faster location fixes
 * - Automatic fallback between GPS, WiFi, and cell towers
 * - Industry standard for Android location tracking
 */
class FusedPositionProvider(
    context: Context,
    listener: PositionListener
) : PositionProvider(context, listener) {

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private val locationRequest: LocationRequest = createLocationRequest()

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { location ->
                Timber.tag(TAG).i("Fused location update: $location")
                processLocation(location)
            }
        }

        override fun onLocationAvailability(availability: LocationAvailability) {
            if (!availability.isLocationAvailable) {
                Timber.tag(TAG).w("Location unavailable")
                listener.onPositionError(Exception("Location unavailable"))
            }
        }
    }

    /**
     * Creates a LocationRequest with appropriate settings based on user preferences.
     */
    private fun createLocationRequest(): LocationRequest {
        val priority = getPriority(
            preferences.getString(TraccarController.KEY_ACCURACY, "medium")?.lowercase()
        )

        return LocationRequest.Builder(priority, interval)
            .apply {
                // Set minimum update interval (can be faster than requested interval)
                setMinUpdateIntervalMillis(interval / 2)

                // Set minimum distance between updates if configured
                if (distance > 0) {
                    setMinUpdateDistanceMeters(distance.toFloat())
                }

                // Wait for accurate location before delivering
                setWaitForAccurateLocation(priority == Priority.PRIORITY_HIGH_ACCURACY)

                // Maximum time to wait for location update
                setMaxUpdateDelayMillis(interval * 2)
            }
            .build()
    }

    @SuppressLint("MissingPermission")
    override fun startUpdates() {
        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            ).addOnSuccessListener {
                Timber.tag(TAG).i("Location updates started successfully")
            }.addOnFailureListener { exception ->
                Timber.tag(TAG).e(exception, "Failed to start location updates")
                listener.onPositionError(exception)
            }
        } catch (e: SecurityException) {
            Timber.tag(TAG).e(e, "Missing location permission")
            listener.onPositionError(e)
        }
    }

    override fun stopUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
            .addOnSuccessListener {
                Timber.tag(TAG).i("Location updates stopped successfully")
            }
            .addOnFailureListener { exception ->
                Timber.tag(TAG).w("Failed to stop location updates", exception)
            }
    }

    @SuppressLint("MissingPermission")
    override fun requestSingleLocation() {
        try {
            // First try to get last known location (fastest, no battery use)
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location: Location? ->
                    if (location != null) {
                        Timber.tag(TAG).i("Using last known location: $location")
                        listener.onPositionUpdate(
                            Position(deviceId, location, getBatteryStatus(context))
                        )
                    } else {
                        // No cached location, request current location
                        requestCurrentLocation()
                    }
                }
                .addOnFailureListener { exception ->
                    Timber.tag(TAG).w("Failed to get last known location, requesting current", exception)
                    requestCurrentLocation()
                }
        } catch (e: SecurityException) {
            Timber.tag(TAG).e(e, "Missing location permission")
            listener.onPositionError(e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun requestCurrentLocation() {
        val currentLocationRequest = CurrentLocationRequest.Builder()
            .setPriority(getPriority(
                preferences.getString(TraccarController.KEY_ACCURACY, "medium")?.lowercase()
            ))
            .setMaxUpdateAgeMillis(SINGLE_LOCATION_MAX_AGE)
            .build()

        fusedLocationClient.getCurrentLocation(
            currentLocationRequest,
            null // CancellationToken - null means not cancellable
        ).addOnSuccessListener { location: Location? ->
            if (location != null) {
                Timber.tag(TAG).i("Current location obtained: $location")
                listener.onPositionUpdate(
                    Position(deviceId, location, getBatteryStatus(context))
                )
            } else {
                Timber.tag(TAG).w("Current location is null")
                listener.onPositionError(Exception("Unable to obtain current location"))
            }
        }.addOnFailureListener { exception ->
            Timber.tag(TAG).e(exception, "Failed to get current location")
            listener.onPositionError(exception)
        }
    }

    /**
     * Maps accuracy level preference to Google Play Services priority constant.
     *
     * - High: GPS-level accuracy, highest battery usage
     * - Medium: Block-level accuracy, balanced battery usage
     * - Low: City-level accuracy, lowest battery usage
     */
    private fun getPriority(accuracy: String?): Int {
        return when (accuracy) {
            "high" -> Priority.PRIORITY_HIGH_ACCURACY // GPS + WiFi + Cell
            "low" -> Priority.PRIORITY_PASSIVE // Only when other apps request location
            else -> Priority.PRIORITY_BALANCED_POWER_ACCURACY // WiFi + Cell (default)
        }
    }

    companion object {
        private val TAG = FusedPositionProvider::class.java.simpleName

        // Maximum age for single location request (5 minutes)
        private const val SINGLE_LOCATION_MAX_AGE = 5 * 60 * 1000L
    }
}
