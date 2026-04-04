package com.tiviplayer.tiviplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val playerEngineChannelHandler = PlayerEngineChannelHandler()
    private val deviceProfileChannelHandler = DeviceProfileChannelHandler()
    private val displayControlChannelHandler = DisplayControlChannelHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playerEngineChannelHandler.attach(flutterEngine)
        deviceProfileChannelHandler.attach(flutterEngine, applicationContext)
        displayControlChannelHandler.attach(flutterEngine, this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        displayControlChannelHandler.detach()
        deviceProfileChannelHandler.detach()
        playerEngineChannelHandler.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
