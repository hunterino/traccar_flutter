package dev.mostafamovahhed.traccar_flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Bundle
import dev.mostafamovahhed.traccar_flutter.client.AccuracyLevel
import dev.mostafamovahhed.traccar_flutter.client.StatusActivity
import dev.mostafamovahhed.traccar_flutter.client.TraccarController
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/** TraccarFlutterPlugin */
class TraccarFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

   private lateinit var channel: MethodChannel
   private lateinit var context: Context
   private lateinit var activity: Activity
   private lateinit var traccarController: TraccarController
   private lateinit var binding: ActivityPluginBinding

   override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
       context = flutterPluginBinding.applicationContext
       channel = MethodChannel(flutterPluginBinding.binaryMessenger, "traccar_flutter")
       channel.setMethodCallHandler(this)
   }

   override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
       when (call.method) {
           "init" -> {
               traccarController.setup(activity)
               result.success("initialized successfully")
           }

           "setConfigs" -> {
               traccarController.setConfigs(
                   deviceId = call.argument<String?>("deviceId"),
                   serverUrl = call.argument<String?>("serverUrl"),
                   interval = call.argument<Int?>("interval"),
                   distance = call.argument<Int?>("distance"),
                   angle = call.argument<Int?>("angle"),
                   accuracyLevel = AccuracyLevel.valueOf(call.argument<String>("accuracy")!!),
                   offlineBuffering = call.argument<Boolean?>("offlineBuffering"),
                   wakelock = call.argument<Boolean?>("wakelock"),
                   notificationIcon = call.argument<String?>("notificationIcon"),
               )
               result.success("configs set")
           }

           "startService" -> {
               traccarController.startTrackingService(
                   checkLocationPermission = true,
                   checkNotificationPermission = true,
                   initialPermission = false
               )
               result.success("service started")
           }

           "stopService" -> {
               traccarController.stopTrackingService()
               result.success("service stopped")
           }

           "statusActivity" -> {
               activity.startActivity(Intent(activity, StatusActivity::class.java))
               result.success("launch status activity")
           }

           else -> {
               result.notImplemented()
           }
       }
   }

   override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
       channel.setMethodCallHandler(null)
   }

   override fun onAttachedToActivity(binding: ActivityPluginBinding) {
       handleStart(binding)
   }

   override fun onDetachedFromActivityForConfigChanges() {
   }

   override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
       handleStart(binding)
   }

   override fun onDetachedFromActivity() {
   }

   private fun handleStart(binding: ActivityPluginBinding){
       this.activity = binding.getActivity()
       this.binding = binding
       this.traccarController = TraccarController.getInstance()

       // Register the permission result listener
       binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
           this.traccarController.onRequestPermissionsResult(
               requestCode,
               permissions,
               grantResults
           )
       }

       // Register lifecycle callback with the application
       val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
           override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

           override fun onActivityStarted(activity: Activity) {
               if (activity == this@TraccarFlutterPlugin.activity) {
                   this@TraccarFlutterPlugin.traccarController.onStart()
               }
           }

           override fun onActivityResumed(activity: Activity) {}

           override fun onActivityPaused(activity: Activity) {}

           override fun onActivityStopped(activity: Activity) {}

           override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

           override fun onActivityDestroyed(activity: Activity) {}
       }
       activity.application?.registerActivityLifecycleCallbacks(lifecycleCallbacks)
   }

}
