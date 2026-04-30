package com.oasis.app

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService

class MainApplication : FlutterApplication(), PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        // This ensures the background isolate is correctly registered for FCM
        FlutterFirebaseMessagingBackgroundService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        // Register all plugins with the background isolate
        if (registry != null) {
            GeneratedPluginRegistrant.registerWith(registry)
        }
    }
}
