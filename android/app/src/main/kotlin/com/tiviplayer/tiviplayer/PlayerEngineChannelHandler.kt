package com.tiviplayer.tiviplayer

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PlayerEngineChannelHandler {
    companion object {
        private const val CHANNEL = "tiviplayer/player_engine_android"
    }

    private var methodChannel: MethodChannel? = null

    fun attach(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(::onMethodCall)
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(
                mapOf(
                    "audioTrackSelection" to false,
                    "subtitleTrackSelection" to false,
                    "manualQualitySelection" to false,
                    "autoQualitySelection" to false
                )
            )

            "selectAudioTrack" -> result.success(notSupported("audio_track_selection_not_available"))
            "selectSubtitleTrack" -> result.success(notSupported("subtitle_track_selection_not_available"))
            "selectQualityVariant" -> result.success(notSupported("manual_quality_selection_not_available"))
            "setAutoQuality" -> result.success(notSupported("auto_quality_selection_not_available"))
            else -> result.notImplemented()
        }
    }

    private fun notSupported(reason: String): Map<String, Any> {
        return mapOf(
            "status" to "not_supported",
            "reason" to reason
        )
    }
}
