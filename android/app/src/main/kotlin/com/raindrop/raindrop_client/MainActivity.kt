package com.raindrop.raindrop_client

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's one activity, plus the channel Dart keeps a call alive over.
 *
 * Everything else is plugins; this exists only because Android has no
 * plugin-free way to run a microphone in the background, or to capture the
 * screen from there. See
 * [CallForegroundService] for why a service is needed at all, and
 * `core/voice/call_session_host.dart` for the Dart end of this channel.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "raindrop/call_session"
        const val NOTIFICATIONS_REQUEST = 4101
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // The one thing the service says back: a screen capture ended from
        // outside the app — its notification's Stop sharing, or the system
        // closing it. Dart ends the share; the service only noticed.
        val main = Handler(Looper.getMainLooper())
        CallForegroundService.onCaptureEnded = {
            main.post { channel.invokeMethod("captureEnded", null) }
        }

        channel
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
                        if (call.method == "begin") askForNotifications()
                        result.success(null)
                    }

                    "end" -> {
                        CallForegroundService.stop(applicationContext)
                        result.success(null)
                    }

                    // The call starts or stops capturing the screen. Answered
                    // with whether the service took (or dropped) the type,
                    // because the capture that follows needs it in place.
                    "capture" -> result.success(
                        CallForegroundService.setCapturing(
                            call.argument<Boolean>("capturing") ?: false,
                        ),
                    )

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Asks to show notifications, the first time a call starts.
     *
     * From Android 13 an app shows none until the user has said it may, and
     * that includes the ongoing-call one: the service still runs without it,
     * but the call is then invisible outside the app — and so is the only way
     * to stop sharing a screen without coming back. Asked when a call begins
     * because that is the moment the notification means something. Android
     * itself stops asking after two refusals, so this never nags.
     */
    private fun askForNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATIONS_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        // Plugins take their own answers from here too.
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATIONS_REQUEST &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        ) {
            // The notification was posted before it was allowed, and dropped.
            CallForegroundService.refresh()
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Nothing left to tell: the engine it would be told through is going.
        CallForegroundService.onCaptureEnded = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
