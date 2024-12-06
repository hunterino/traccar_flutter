/*
 * Copyright 2012 - 2021 Anton Tananaev (anton@traccar.org)
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

import android.net.Uri

object ProtocolFormatter {

    fun formatRequest(url: String, position: Position, alarm: String? = null): String {
        val serverUrl = Uri.parse(url)
        val builder = serverUrl.buildUpon()
            .appendQueryParameter("UnidId", position.deviceId)
            .appendQueryParameter("Timestamp", (position.time.time / 1000).toString())
            .appendQueryParameter("Latitude", position.latitude.toString())
            .appendQueryParameter("Longitude", position.longitude.toString())
            .appendQueryParameter("Speed", position.speed.toString())
            .appendQueryParameter("Bearing", position.course.toString())
            .appendQueryParameter("Altitude", position.altitude.toString())
            .appendQueryParameter("Accuracy", position.accuracy.toString())
            .appendQueryParameter("BatteryLevel", position.battery.toString())
        if (position.charging) {
            builder.appendQueryParameter("charge", position.charging.toString())
        }
        if (position.mock) {
            builder.appendQueryParameter("Mock", position.mock.toString())
        }
        if (alarm != null) {
            builder.appendQueryParameter("Alarm", alarm)
        }
        return builder.build().toString()
    }
}
