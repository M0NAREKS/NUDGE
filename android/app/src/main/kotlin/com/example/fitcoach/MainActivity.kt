package com.example.fitcoach

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "nudge/platform_capabilities"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapabilities" -> {
                    result.success(
                        mapOf(
                            "hasGms" to hasPackage("com.google.android.gms"),
                            "hasHms" to (hasPackage("com.huawei.hwid") || hasPackage("com.huawei.hms")),
                            "brand" to (Build.BRAND ?: ""),
                            "manufacturer" to (Build.MANUFACTURER ?: "")
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun hasPackage(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
