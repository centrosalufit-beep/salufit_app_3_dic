package com.salufit.app

import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val channel = "com.salufit.app/test_lab"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "isFirebaseTestLab") {
                    val isTestLab = Settings.System.getString(contentResolver, "firebase.test.lab") == "true"
                    result.success(isTestLab)
                } else {
                    result.notImplemented()
                }
            }
    }
}
