package com.tiviplayer.tiviplayer

import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceProfileChannelHandler {
    companion object {
        private const val CHANNEL = "tiviplayer/device_profile_android"
    }

    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null

    fun attach(flutterEngine: FlutterEngine, context: Context) {
        applicationContext = context.applicationContext
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(::onMethodCall)
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        applicationContext = null
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceProfile" -> {
                val context = applicationContext
                if (context == null) {
                    result.success(emptyMap<String, Any>())
                    return
                }
                result.success(buildDeviceProfile(context))
            }

            else -> result.notImplemented()
        }
    }

    private fun buildDeviceProfile(context: Context): Map<String, Any> {
        val packageManager = context.packageManager
        val configuration = context.resources.configuration
        val uiModeType = configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
        val navigation = configuration.navigation
        val keyboard = configuration.keyboard

        return mapOf(
            "isTelevisionUiMode" to (uiModeType == Configuration.UI_MODE_TYPE_TELEVISION),
            "hasLeanbackFeature" to packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK),
            "hasTelevisionFeature" to packageManager.hasSystemFeature(PackageManager.FEATURE_TELEVISION),
            "hasTouchscreen" to packageManager.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN),
            "hasDirectionalNavigation" to (navigation == Configuration.NAVIGATION_DPAD),
            "hasHardwareKeyboard" to (keyboard != Configuration.KEYBOARD_NOKEYS)
        )
    }
}
