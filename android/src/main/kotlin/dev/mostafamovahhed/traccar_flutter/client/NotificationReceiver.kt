package dev.mostafamovahhed.traccar_flutter.client

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val actionType = intent?.getIntExtra("action", -1)
        when (actionType) {
            START_SERVICE_ACTION -> {
                TraccarController.getInstance().startTrackingService(
                    checkLocationPermission = true,
                    checkNotificationPermission = true,
                    initialPermission = false
                )
            }

            STOP_SERVICE_ACTION -> {
                TraccarController.getInstance().stopTrackingService()
            }
        }
    }

    companion object {
        const val START_SERVICE_ACTION = 11
        const val STOP_SERVICE_ACTION = 22
    }
}
