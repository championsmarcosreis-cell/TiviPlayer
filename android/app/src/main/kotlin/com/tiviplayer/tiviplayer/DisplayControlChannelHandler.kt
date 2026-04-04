package com.tiviplayer.tiviplayer

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DisplayControlChannelHandler {
    companion object {
        private const val CHANNEL = "tiviplayer/display_control_android"
    }

    private var activity: Activity? = null
    private var methodChannel: MethodChannel? = null

    fun attach(flutterEngine: FlutterEngine, activity: Activity) {
        this.activity = activity
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(::onMethodCall)
    }

    fun detach() {
        activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        activity = null
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setKeepScreenOn" -> {
                val enabled = call.argument<Boolean>("enabled") == true
                val currentActivity = activity
                if (currentActivity == null) {
                    result.success(false)
                    return
                }

                currentActivity.runOnUiThread {
                    if (enabled) {
                        currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(true)
                }
            }

            else -> result.notImplemented()
        }
    }
}
