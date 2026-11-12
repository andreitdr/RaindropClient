package com.raindrop.raindrop_client

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's one activity, plus the channel Dart keeps a call alive over.
 *
 * Everything else is plugins; this exists only because Android has no
 * plugin-free way to run a microphone in the background. See
 * [CallForegroundService] for why a service is needed at all, and
 * `core/voice/call_session_host.dart` for the Dart end of this channel.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "raindrop/call_session"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // `begin` and `update` are the same request here:
                    // starting an already-started foreground service just
                    // re-issues its notification. Dart keeps the two apart
                    // because iOS and desktop hosts may not.
                    "begin", "update" -> {
                        val title = call.argument<String>("title").orEmpty()
                        val body = call.argument<String>("body").orEmpty()
                        CallForegroundService.start(applicationContext, title, body)
                        result.success(null)
                    }

                    "end" -> {
                        CallForegroundService.stop(applicationContext)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
