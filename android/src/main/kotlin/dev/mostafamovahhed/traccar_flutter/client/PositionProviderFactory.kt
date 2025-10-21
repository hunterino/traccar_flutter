/*
 * Copyright 2019 - 2021 Anton Tananaev (anton@traccar.org)
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
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability

/**
 * Factory for creating the appropriate position provider.
 *
 * Prefers FusedPositionProvider (modern, battery-efficient) when Google Play Services
 * is available, falls back to AndroidPositionProvider (deprecated LocationManager)
 * when Google Play Services is not available.
 */
object PositionProviderFactory {

    private val TAG = PositionProviderFactory::class.java.simpleName

    fun create(context: Context, listener: PositionProvider.PositionListener): PositionProvider {
        return if (isGooglePlayServicesAvailable(context)) {
            Timber.tag(TAG).i("Using FusedPositionProvider (Google Play Services)")
            FusedPositionProvider(context, listener)
        } else {
            Timber.tag(TAG).w("Google Play Services not available, using legacy AndroidPositionProvider")
            AndroidPositionProvider(context, listener)
        }
    }

    /**
     * Checks if Google Play Services is available on the device.
     *
     * @return true if Google Play Services is available and up to date
     */
    private fun isGooglePlayServicesAvailable(context: Context): Boolean {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = googleApiAvailability.isGooglePlayServicesAvailable(context)

        return when (resultCode) {
            ConnectionResult.SUCCESS -> {
                Timber.tag(TAG).d("Google Play Services is available")
                true
            }
            ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED -> {
                Timber.tag(TAG).w("Google Play Services needs to be updated")
                false
            }
            ConnectionResult.SERVICE_DISABLED -> {
                Timber.tag(TAG).w("Google Play Services is disabled")
                false
            }
            ConnectionResult.SERVICE_MISSING -> {
                Timber.tag(TAG).w("Google Play Services is missing")
                false
            }
            else -> {
                Timber.tag(TAG).w("Google Play Services error: $resultCode")
                false
            }
        }
    }
}
