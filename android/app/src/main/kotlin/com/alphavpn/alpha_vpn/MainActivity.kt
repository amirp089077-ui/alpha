package com.alphavpn.alpha_vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val VPN_PERMISSION_CODE = 100
        private const val CHANNEL = "com.alphavpn/vpn_permission"
    }

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    val intent = VpnService.prepare(this)
                    if (intent == null) {
                        // permission قبلاً گرفته شده
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
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_CODE) {
            permissionResult?.success(resultCode == Activity.RESULT_OK)
            permissionResult = null
        }
    }
}
