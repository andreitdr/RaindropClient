package com.raindrop.raindrop_client

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The app's one activity, plus the channel Dart keeps a call alive over.
 *
 * A fragment activity because unlocking the app with a fingerprint or face (local_auth) shows the
 * system's biometric prompt, which is a fragment.
 *
 * Everything else is plugins; this exists only because Android has no
 * plugin-free way to run a microphone in the background, or to capture the
 * screen from there — and to reach Block Store ([BlockStoreChannel]). See
 * [CallForegroundService] for why a service is needed at all, and
 * `core/voice/call_session_host.dart` for the Dart end of this channel.
 */
class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val CHANNEL = "raindrop/call_session"
        const val NOTIFICATIONS_REQUEST = 4101
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BlockStoreChannel.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // The one thing the service says back: a screen capture ended from
        // outside the app — its notification's Stop sharing, or the system
        // closing it. Dart ends the share; the service only noticed.
        val main = Handler(Looper.getMainLooper())
        CallForegroundService.onCaptureEnded = {
            main.post { channel.invokeMethod("captureEnded", null) }
        }
        // And the notification's Mute and Leave, which Dart carries out as the
        // call bar's buttons would.
        CallForegroundService.onAction = { action ->
            main.post { channel.invokeMethod("action", action) }
        }

        channel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // `begin` and `update` are the same request here:
                    // starting an already-started foreground service just
                    // re-issues its notification. Dart keeps the two apart
                    // because iOS and desktop hosts may not.
                    "begin", "update" -> {
                        CallForegroundService.start(applicationContext, describe(call))
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
     * The call as Dart sent it (`CallSessionDescription.toMap()`), read
     * leniently: a missing or mistyped key is the quiet default.
     */
    private fun describe(call: MethodCall) = CallDescription(
        title = call.argument<String>("title").orEmpty(),
        body = call.argument<String>("body").orEmpty(),
        connectedAt = call.argument<Number>("connectedAt")?.toLong() ?: 0L,
        micOn = call.argument<Boolean>("micOn") ?: true,
        deafened = call.argument<Boolean>("deafened") ?: false,
        reconnecting = call.argument<Boolean>("reconnecting") ?: false,
        prominent = call.argument<Boolean>("showOutsideApp") ?: true,
    )

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
        CallForegroundService.onAction = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
