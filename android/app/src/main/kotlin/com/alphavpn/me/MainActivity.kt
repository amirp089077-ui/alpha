package com.alphavpn.me

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val VPN_CHANNEL  = "com.alphavpn/vpn_permission"
        private const val APPS_CHANNEL = "com.alphavpn/apps"
        private const val VPN_PERMISSION_CODE = 100
    }

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── VPN permission channel (بدون تغییر) ──────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VPN_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    val intent = VpnService.prepare(this)
                    if (intent == null) {
                        result.success(true)
                    } else {
                        permissionResult = result
                        startActivityForResult(intent, VPN_PERMISSION_CODE)
                    }
                }
                "isPermissionGranted" -> {
                    result.success(VpnService.prepare(this) == null)
                }
                else -> result.notImplemented()
            }
        }

        // ── Apps channel — لیست برنامه‌های نصب‌شده ───────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APPS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    // روی thread جدا تا UI بلاک نشه
                    Thread {
                        try {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("APPS_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── گرفتن لیست برنامه‌ها ─────────────────────────────────────────

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.GET_META_DATA
        } else {
            PackageManager.GET_META_DATA
        }

        val packages = pm.getInstalledApplications(flags)

        return packages
            // برنامه‌هایی که launcher icon دارن (قابل اجرا)
            .filter { app ->
                // سیستمی‌های خالص رو حذف کن، مگه اینکه update شده باشن
                val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val isUpdatedSystem = (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                !isSystem || isUpdatedSystem
            }
            .mapNotNull { app ->
                try {
                    val appName = pm.getApplicationLabel(app).toString()
                    val packageName = app.packageName
                    // خود برنامه ما رو نشون نده
                    if (packageName == this.packageName) return@mapNotNull null

                    val iconBytes = getAppIconBytes(pm.getApplicationIcon(app))

                    mapOf(
                        "packageName" to packageName,
                        "appName"     to appName,
                        "isSystem"    to false,
                        "icon"        to iconBytes,
                    )
                } catch (e: Exception) {
                    null
                }
            }
            .sortedBy { it["appName"] as String }
    }

    // ── تبدیل Drawable → PNG bytes ───────────────────────────────────

    private fun getAppIconBytes(drawable: Drawable): ByteArray {
        val bitmap = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
        return stream.toByteArray()
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        // AdaptiveIcon (Android 8+) — روی پس‌زمینه سفید رندر کن
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            drawable is AdaptiveIconDrawable
        ) {
            val size = 108
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            return bmp
        }

        val w = drawable.intrinsicWidth.takeIf { it > 0 } ?: 48
        val h = drawable.intrinsicHeight.takeIf { it > 0 } ?: 48
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, w, h)
        drawable.draw(canvas)
        return bmp
    }

    // ── VPN permission result ─────────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_CODE) {
            permissionResult?.success(resultCode == Activity.RESULT_OK)
            permissionResult = null
        }
    }
}
