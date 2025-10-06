package com.example.whisptask

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "whisptask/notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createNotificationChannel" -> {
                    val arguments = call.arguments as? Map<String, Any>
                    if (arguments != null) {
                        createNotificationChannel(arguments)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Arguments cannot be null", null)
                    }
                }
                "openAppWithVoiceScreen" -> {
                    val arguments = call.arguments as? Map<String, Any>
                    if (arguments != null) {
                        openAppWithVoiceScreen(arguments)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Arguments cannot be null", null)
                    }
                }
                "getIntentExtras" -> {
                    val extras = getIntentExtras()
                    result.success(extras)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel(arguments: Map<String, Any>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = arguments["channelId"] as String
            val channelName = arguments["channelName"] as String
            val channelDescription = arguments["channelDescription"] as String
            val importance = arguments["importance"] as Int

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            
            // Log for debugging
            android.util.Log.d("MainActivity", "Notification channel created: $channelId")
        }
    }

    private fun openAppWithVoiceScreen(arguments: Map<String, Any>) {
        val command = arguments["command"] as? String ?: ""
        
        // Create intent to bring app to foreground and open voice screen
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("openVoiceScreen", true)
            putExtra("voiceCommand", command)
        }
        
        startActivity(intent)
    }

    private fun getIntentExtras(): Map<String, Any>? {
        val currentIntent = intent
        return if (currentIntent != null && currentIntent.extras != null) {
            val extras = mutableMapOf<String, Any>()
            
            // Get the intent extras that were set by background service
            val openVoiceScreen = currentIntent.getBooleanExtra("openVoiceScreen", false)
            val voiceCommand = currentIntent.getStringExtra("voiceCommand") ?: ""
            
            if (openVoiceScreen) {
                extras["openVoiceScreen"] = true
                extras["voiceCommand"] = voiceCommand
                
                // Clear the extras after reading them to prevent re-processing
                currentIntent.removeExtra("openVoiceScreen")
                currentIntent.removeExtra("voiceCommand")
            }
            
            if (extras.isNotEmpty()) extras else null
        } else {
            null
        }
    }
}
