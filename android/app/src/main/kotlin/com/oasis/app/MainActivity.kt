package com.oasis.app

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Required for notification taps to be delivered to Flutter 
        // when the app is already running in the background.
        setIntent(intent)
    }
}