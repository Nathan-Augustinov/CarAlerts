package com.example.car_alerts

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private val requestCode = 4301
    // This records only whether we asked before, never the permission status.
    private val promptHistory by lazy { getSharedPreferences("notification_prompt", MODE_PRIVATE) }

    private fun permissionStatus(): String {
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            if (Build.VERSION.SDK_INT >= 26) {
                val manager = getSystemService(android.app.NotificationManager::class.java)
                if (manager.getNotificationChannel("1")?.importance == android.app.NotificationManager.IMPORTANCE_NONE) return "disabled"
            }
            return "enabled"
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            !promptHistory.getBoolean("asked", false)) return "notRequested"
        return "disabled"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "car_alerts/feedback")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deviceDetails" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val build = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                        result.success(mapOf(
                            "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                            "os" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
                            "version" to "${info.versionName} ($build)"
                        ))
                    }
                    "compose" -> {
                        try {
                            val uri = call.argument<String>("uri") ?: throw IllegalArgumentException("Missing email")
                            val intent = Intent(Intent.ACTION_SENDTO, android.net.Uri.parse(uri))
                            if (intent.resolveActivity(packageManager) == null) {
                                result.error("email_unavailable", "No email app is available", null)
                            } else {
                                startActivity(Intent.createChooser(intent, "Choose an email app"))
                                result.success(null)
                            }
                        } catch (error: Exception) {
                            result.error("email_unavailable", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "car_alerts/notification_permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "timezone" -> result.success(java.util.TimeZone.getDefault().id)
                    "loadReminderIds" -> result.success(promptHistory.getString("reminder_ids", "{}"))
                    "saveReminderIds" -> {
                        if (promptHistory.edit().putString("reminder_ids", call.arguments as String).commit()) result.success(null)
                        else result.error("storage_failed", "Could not persist reminder IDs", null)
                    }
                    "loadReminderHistory" -> result.success(promptHistory.getString("reminder_history", "{}"))
                    "saveReminderHistory" -> {
                        if (promptHistory.edit().putString("reminder_history", call.arguments as String).commit()) result.success(null)
                        else result.error("storage_failed", "Could not persist reminder history", null)
                    }
                    "status" -> result.success(permissionStatus())
                    "request" -> {
                        if (permissionStatus() != "notRequested" || Build.VERSION.SDK_INT < 33) {
                            result.success(permissionStatus())
                        } else if (permissionResult != null) {
                            result.error("request_in_progress", "Permission request is already open", null)
                        } else {
                            permissionResult = result
                            promptHistory.edit().putBoolean("asked", true).apply()
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), requestCode)
                        }
                    }
                    "openSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= 26) {
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            } else {
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    android.net.Uri.parse("package:$packageName"))
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("settings_unavailable", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == this.requestCode) {
            if (grantResults.isEmpty()) promptHistory.edit().remove("asked").apply()
            permissionResult?.success(permissionStatus())
            permissionResult = null
        }
    }
}
