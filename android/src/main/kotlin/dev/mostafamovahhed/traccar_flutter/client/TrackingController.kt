/*
 * Copyright 2015 - 2021 Anton Tananaev (anton@traccar.org)
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
import android.os.Handler
import android.os.Looper
import androidx.preference.PreferenceManager
import timber.log.Timber
import dev.mostafamovahhed.traccar_flutter.R
import dev.mostafamovahhed.traccar_flutter.client.ProtocolFormatter.formatRequest
import dev.mostafamovahhed.traccar_flutter.client.RequestManager.sendRequestAsync
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class TrackingController(private val context: Context) : PositionProvider.PositionListener,
    NetworkManager.NetworkHandler {

    private val handler = Handler(Looper.getMainLooper())
    private val preferences = PreferenceManager.getDefaultSharedPreferences(context)
    private val positionProvider = PositionProviderFactory.create(context, this)
    private val databaseHelper = DatabaseHelper(context)
    private val networkManager = NetworkManager(context, this)
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val url: String = preferences.getString(TraccarController.KEY_URL, context.getString(R.string.settings_url_default_value))!!
    private val buffer: Boolean = preferences.getBoolean(TraccarController.KEY_BUFFER, true)

    private var isOnline = networkManager.isOnline
    private var isWaiting = false
    private var lastCleanupTime: Long = 0

    fun start() {
        if (isOnline) {
            read()
        }
        try {
            positionProvider.startUpdates()
        } catch (e: SecurityException) {
            Timber.tag(TAG).w(e)
        }
        networkManager.start()
    }

    fun stop() {
        networkManager.stop()
        try {
            positionProvider.stopUpdates()
        } catch (e: SecurityException) {
            Timber.tag(TAG).w(e)
        }
        handler.removeCallbacksAndMessages(null)
        coroutineScope.cancel()
    }

    override fun onPositionUpdate(position: Position) {
        TraccarController.addStatusLog(context.getString(R.string.status_location_update))

        // Send position to Flutter
        TraccarController.sendPositionToFlutter(position)

        if (buffer) {
            write(position)
        } else {
            send(position)
        }
    }

    override fun onPositionError(error: Throwable) {}
    override fun onNetworkUpdate(isOnline: Boolean) {
        val message = if (isOnline) R.string.status_network_online else R.string.status_network_offline
        TraccarController.addStatusLog(context.getString(message))
        if (!this.isOnline && isOnline) {
            read()
        }
        this.isOnline = isOnline
    }

    //
    // State transition examples:
    //
    // write -> read -> send -> delete -> read
    //
    // read -> send -> retry -> read -> send
    //

    private fun log(action: String, position: Position?) {
        var formattedAction: String = action
        if (position != null) {
            formattedAction +=
                    " (id:" + position.id +
                    " time:" + position.time.time / 1000 +
                    " lat:" + position.latitude +
                    " lon:" + position.longitude + ")"
        }
        Timber.tag(TAG).d(formattedAction)
    }

    private fun write(position: Position) {
        log("write", position)
        coroutineScope.launch {
            databaseHelper.insertPositionAsync(position).onSuccess {
                if (isOnline && isWaiting) {
                    read()
                    isWaiting = false
                }

                // Periodic cleanup: run every 24 hours
                performCleanupIfNeeded()
            }.onFailure { error ->
                Timber.tag(TAG).w(error, "Failed to insert position")
            }
        }
    }

    private fun performCleanupIfNeeded() {
        val now = System.currentTimeMillis()
        if (now - lastCleanupTime > CLEANUP_INTERVAL_MS) {
            lastCleanupTime = now
            coroutineScope.launch {
                databaseHelper.performCleanup().onSuccess { stats ->
                    if (stats.totalDeleted > 0) {
                        Timber.tag(TAG).i("Database cleanup: deleted ${stats.totalDeleted} positions")
                        TraccarController.addStatusLog("Cleaned up ${stats.totalDeleted} old positions")
                    }
                }.onFailure { error ->
                    Timber.tag(TAG).w(error, "Database cleanup failed")
                }
            }
        }
    }

    private fun read() {
        log("read", null)
        coroutineScope.launch {
            databaseHelper.selectPositionAsync().onSuccess { position ->
                if (position != null) {
                    if (position.deviceId == preferences.getString(TraccarController.KEY_DEVICE, null)) {
                        send(position)
                    } else {
                        delete(position)
                    }
                } else {
                    isWaiting = true
                }
            }.onFailure { error ->
                Timber.tag(TAG).w(error, "Failed to select position")
                retry()
            }
        }
    }

    private fun delete(position: Position) {
        log("delete", position)
        coroutineScope.launch {
            databaseHelper.deletePositionAsync(position.id).onSuccess {
                read()
            }.onFailure { error ->
                Timber.tag(TAG).w(error, "Failed to delete position")
                retry()
            }
        }
    }

    private fun send(position: Position) {
        log("send", position)
        val request = formatRequest(url, position)
        coroutineScope.launch {
            sendRequestAsync(request).onSuccess {
                TraccarController.addStatusLog(context.getString(R.string.status_send_success))
                if (buffer) {
                    delete(position)
                }
            }.onFailure { error ->
                Timber.tag(TAG).w(error, "Failed to send request")
                TraccarController.addStatusLog(context.getString(R.string.status_send_fail))
                if (buffer) {
                    retry()
                }
            }
        }
    }

    private fun retry() {
        log("retry", null)
        handler.postDelayed({
            if (isOnline) {
                read()
            }
        }, RETRY_DELAY.toLong())
    }

    companion object {
        private val TAG = TrackingController::class.java.simpleName
        private const val RETRY_DELAY = 30 * 1000
        private const val CLEANUP_INTERVAL_MS = 24 * 60 * 60 * 1000L // 24 hours
    }

}
