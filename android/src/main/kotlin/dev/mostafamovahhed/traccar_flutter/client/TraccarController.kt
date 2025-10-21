/*
 * Copyright 2012 - 2023 Anton Tananaev (anton@traccar.org)
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

import android.Manifest
import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import timber.log.Timber
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import androidx.preference.PreferenceManager
import java.util.*
import dev.mostafamovahhed.traccar_flutter.R
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class TraccarController {

    companion object {
        private val TAG = TraccarController::class.java.simpleName
        const val PRIMARY_CHANNEL = "location_tracking_default"
        private const val ALARM_MANAGER_INTERVAL = 15000
        const val KEY_DEVICE = "id"
        const val KEY_URL = "url"
        const val KEY_INTERVAL = "interval"
        const val KEY_NOTIFICATION_ICON = "notification_icon"
        const val KEY_DISTANCE = "distance"
        const val KEY_ANGLE = "angle"
        const val KEY_ACCURACY = "accuracy"
        const val KEY_STATUS = "status"
        const val KEY_BUFFER = "buffer"
        const val KEY_WAKELOCK = "wakelock"
        private const val PERMISSIONS_REQUEST_LOCATION = 2
        private const val PERMISSIONS_REQUEST_BACKGROUND_LOCATION = 3
        private const val PERMISSIONS_REQUEST_NOTIFICATION = 4

        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var instance: TraccarController? = null

        fun getInstance(): TraccarController =
            instance ?: synchronized(this) {
                instance ?: TraccarController().also { instance = it }
            }

        fun addStatusLog(message: String) {
            StatusActivity.addMessage(message)
        }

        @Volatile
        private var methodChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }

        fun sendPositionToFlutter(position: Position) {
            methodChannel?.let { channel ->
                mainHandler.post {
                    try {
                        channel.invokeMethod("onPositionUpdate", position.toMap())
                    } catch (e: Exception) {
                        timber.log.Timber.tag(TAG).e(e, "Failed to send position to Flutter")
                    }
                }
            }
        }

        fun sendStatusToFlutter(status: String) {
            methodChannel?.let { channel ->
                mainHandler.post {
                    try {
                        channel.invokeMethod("onStatusUpdate", status)
                    } catch (e: Exception) {
                        timber.log.Timber.tag(TAG).e(e, "Failed to send status to Flutter")
                    }
                }
            }
        }

    }

    private lateinit var applicationContext: Context
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var alarmManager: AlarmManager
    private lateinit var alarmIntent: PendingIntent
    private var requestingPermissions: Boolean = false

    fun setup(activity: Activity) {
        // Store application context instead of activity to avoid memory leak
        this.applicationContext = activity.applicationContext

        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(applicationContext)
        sharedPreferences.registerOnSharedPreferenceChangeListener(this::onSharedPreferenceChanged)
        initPreferences(applicationContext)

        System.setProperty("http.keepAliveDuration", (30 * 60 * 1000).toString())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            registerChannel(applicationContext)
        } else {
            Timber.tag(TAG).i("There is no need to create Notification Channel")
        }

        alarmManager = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val originalIntent = Intent(applicationContext, AutostartReceiver::class.java)
        originalIntent.addFlags(Intent.FLAG_RECEIVER_FOREGROUND)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        alarmIntent = PendingIntent.getBroadcast(applicationContext, 0, originalIntent, flags)

//        if (sharedPreferences.getBoolean(KEY_STATUS, false)) {
//            startTrackingService(
//                checkLocationPermission = true,
//                checkNotificationPermission = true,
//                initialPermission = false,
//            )
//        }
    }

    fun setConfigs(
        deviceId: String?, serverUrl: String?, interval: Int?, distance: Int?,
        angle: Int?, accuracyLevel: AccuracyLevel?,
        offlineBuffering: Boolean?, wakelock: Boolean?,
        notificationIcon: String?
    ) {
        sharedPreferences.edit(commit = true) {
            if (deviceId != null) putString(KEY_DEVICE, deviceId)
            if (serverUrl != null) putString(KEY_URL, serverUrl)
            if (interval != null) putString(KEY_INTERVAL, interval.toString())
            if (distance != null) putString(KEY_DISTANCE, distance.toString())
            if (angle != null) putString(KEY_ANGLE, angle.toString())
            if (accuracyLevel != null) putString(KEY_ACCURACY, accuracyLevel.name.lowercase())
            if (offlineBuffering != null) putBoolean(KEY_BUFFER, offlineBuffering)
            if (wakelock != null) putBoolean(KEY_WAKELOCK, wakelock)
            if (notificationIcon != null) putString(KEY_NOTIFICATION_ICON, notificationIcon)
        }
    }

    fun onStart(activity: Activity) {
        if (requestingPermissions) {
            requestingPermissions = BatteryOptimizationHelper().requestException(activity)
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun registerChannel(context: Context) {
        val channel = NotificationChannel(
            PRIMARY_CHANNEL,
            context.getString(R.string.channel_default),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.channel_default_desc)
        }
        channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun initPreferences(context: Context) {
        PreferenceManager.setDefaultValues(context, R.xml.preferences, false)
        if (!sharedPreferences.contains(KEY_DEVICE)) {
            val id = (Random().nextInt(900000) + 100000).toString()
            sharedPreferences.edit().putString(KEY_DEVICE, id).apply()
        }
    }

    private fun onSharedPreferenceChanged(
        sharedPreferences: SharedPreferences?,
        key: String?,
    ) {
        // Note: This method is kept for SharedPreferences listener but cannot start service
        // without activity reference. The service should be started via the plugin's
        // startService method call which provides the activity reference.
        if (key == KEY_STATUS) {
            if (sharedPreferences?.getBoolean(KEY_STATUS, false) == false) {
                stopTrackingService()
            }
        }
    }

    private fun showBackgroundLocationDialog(context: Context, onSuccess: () -> Unit) {
        val builder = AlertDialog.Builder(context, androidx.appcompat.R.style.Theme_AppCompat_Light_Dialog)
        val option = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            context.packageManager.backgroundPermissionOptionLabel
        } else {
            context.getString(R.string.request_background_option)
        }
        builder.setMessage(context.getString(R.string.request_background, option))
        builder.setPositiveButton(android.R.string.ok) { _, _ -> onSuccess() }
        builder.setNegativeButton(android.R.string.cancel, null)
        builder.show()
    }

    private fun requestNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val requiredPermissions = HashSet<String>().apply {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
            val isNotGranted = ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED

            if (isNotGranted) {
                activity.requestPermissions(
                    requiredPermissions.toTypedArray(),
                    PERMISSIONS_REQUEST_NOTIFICATION
                )
            }
        }
    }

//    private fun hasPermission(context: Context, permission: String): Boolean {
//        return ContextCompat.checkSelfPermission(
//            context,
//            permission
//        ) == PackageManager.PERMISSION_GRANTED
//    }

    fun startTrackingService(
        activity: Activity? = null,
        checkLocationPermission: Boolean,
        checkNotificationPermission: Boolean,
        initialPermission: Boolean,
    ) {
        var permission = initialPermission
        if (checkLocationPermission && activity != null) {
            val requiredPermissions: MutableSet<String> = HashSet()
            if (ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requiredPermissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
            }
            permission = requiredPermissions.isEmpty()
            if (!permission) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    activity.requestPermissions(
                        requiredPermissions.toTypedArray(),
                        PERMISSIONS_REQUEST_LOCATION
                    )
                }
                return
            }
        }

        if (checkNotificationPermission && activity != null) {
            val requiredPermissions: MutableSet<String> = HashSet()
            if (ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
            permission = requiredPermissions.isEmpty()
            if (!permission) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    activity.requestPermissions(
                        requiredPermissions.toTypedArray(),
                        PERMISSIONS_REQUEST_NOTIFICATION
                    )
                }
                return
            }
        }

        if (permission) {
            ContextCompat.startForegroundService(
                applicationContext,
                Intent(applicationContext, TrackingService::class.java)
            )
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                alarmManager.setInexactRepeating(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    ALARM_MANAGER_INTERVAL.toLong(), ALARM_MANAGER_INTERVAL.toLong(), alarmIntent
                )
            }

            if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                && ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestingPermissions = true
                showBackgroundLocationDialog(activity) {
                    activity.requestPermissions(
                        arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                        PERMISSIONS_REQUEST_BACKGROUND_LOCATION
                    )
                }
            } else if (activity != null) {
            requestingPermissions =
                    BatteryOptimizationHelper().requestException(activity)
            }
        } else {
            sharedPreferences.edit().putBoolean(KEY_STATUS, false).apply()
        }
    }

    fun stopTrackingService() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            try {
                alarmManager.cancel(alarmIntent)
            } catch (_: Exception) {
            }
        }
        applicationContext.stopService(Intent(applicationContext, TrackingService::class.java))
    }

    fun getServiceStatus(): String {
        // Check if service is configured to run
        val isConfigured = sharedPreferences.getBoolean(KEY_STATUS, false)

        if (!isConfigured) {
            return "stopped"
        }

        // Check if service is actually running
        val manager = applicationContext.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        @Suppress("DEPRECATION")
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (TrackingService::class.java.name == service.service.className) {
                return "running"
            }
        }

        // Service is configured but not running (error state)
        return "error"
    }

    fun onRequestPermissionsResult(
        activity: Activity,
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSIONS_REQUEST_LOCATION) {
            var granted = true
            for (result in grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    granted = false
                    break
                }
            }
            startTrackingService(
                activity,
                checkLocationPermission = false,
                checkNotificationPermission = true,
                initialPermission = granted
            )
            return true
        } else if (requestCode == PERMISSIONS_REQUEST_NOTIFICATION) {
            startTrackingService(
                activity,
                checkLocationPermission = true,
                checkNotificationPermission = false,
                initialPermission = true
            )
        }
        return false
    }


}
