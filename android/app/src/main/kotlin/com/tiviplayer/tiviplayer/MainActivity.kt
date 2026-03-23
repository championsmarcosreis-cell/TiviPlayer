package com.tiviplayer.tiviplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val playerEngineChannelHandler = PlayerEngineChannelHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playerEngineChannelHandler.attach(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        playerEngineChannelHandler.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
