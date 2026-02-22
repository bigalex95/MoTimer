package com.example.mo_timer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DND_CHANNEL = "com.motimer/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DND_CHANNEL)
            .setMethodCallHandler { call, result ->
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                when (call.method) {
                    "checkDndAccess" -> {
                        result.success(nm.isNotificationPolicyAccessGranted)
                    }
                    "requestDndAccess" -> {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    }
                    "setDnd" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        if (!nm.isNotificationPolicyAccessGranted) {
                            result.error(
                                "NO_ACCESS",
                                "DND policy access not granted",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        val filter = if (enabled) {
                            NotificationManager.INTERRUPTION_FILTER_PRIORITY
                        } else {
                            NotificationManager.INTERRUPTION_FILTER_ALL
                        }
                        nm.setInterruptionFilter(filter)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
