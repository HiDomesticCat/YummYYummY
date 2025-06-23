package com.example.sample_capture_app // 請將此處換成您自己的 package name

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.spectralens.dev/location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isMockLocation") {
                val isMock = isMockLocation()
                result.success(isMock)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isMockLocation(): Boolean {
        // 在 Android 12 (API 31) 以上，isMock() 方法已經被整合進 Location 物件
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            val location: Location? = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            if (location != null) {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    location.isMock()
                } else {
                    // 對於舊版 Android，使用 isFromMockProvider
                    @Suppress("DEPRECATION")
                    location.isFromMockProvider
                }
            }
        } catch (e: SecurityException) {
            // 如果沒有權限，保守地回傳 false
            return false
        }
        return false
    }
}
