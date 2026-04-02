package com.tiviplayer.tiviplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val playerEngineChannelHandler = PlayerEngineChannelHandler()
    private val deviceProfileChannelHandler = DeviceProfileChannelHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playerEngineChannelHandler.attach(flutterEngine)
        deviceProfileChannelHandler.attach(flutterEngine, applicationContext)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        deviceProfileChannelHandler.detach()
        playerEngineChannelHandler.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
