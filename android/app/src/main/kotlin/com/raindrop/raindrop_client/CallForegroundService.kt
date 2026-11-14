package com.raindrop.raindrop_client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Display
import androidx.core.app.NotificationCompat

/**
 * Keeps a voice call running while the app is not on screen.
 *
 * Android stops an app's process — and with it the microphone and the WebRTC
 * connection — shortly after it leaves the foreground, unless a foreground
 * service says otherwise. From Android 14 that service must declare what it
 * is for, and a call is `microphone`: the permission the user already granted
 * for the call is what backs it, and the notification is what makes the
 * recording visible, which is the deal the platform asks for.
 *
 * **A call that shares its screen is `mediaProjection` as well**, for as long
 * as it does. Android will not hand an app the screen unless a service of
 * that type is already running, and from Android 14 will not let a service
 * take the type until the user has agreed to the capture — so the type is
 * added after the consent sheet and before the capture ([setCapturing]), and
 * dropped again when the share ends rather than held for the whole call.
 *
 * The service holds no call state of its own. Dart owns the call (see
 * `core/voice/call_session_host.dart`); this only keeps the process alive and
 * shows what is going on, so a call that ends while the app is backgrounded
 * still takes the notification with it.
 */
class CallForegroundService : Service() {

    companion object {
        private const val TAG = "RaindropCall"

        // There is no separate "update": starting an already-started
        // foreground service just re-issues its notification, so describing a
        // call again and starting one are the same request.
        const val ACTION_START = "com.raindrop.raindrop_client.CALL_START"
        const val ACTION_STOP = "com.raindrop.raindrop_client.CALL_STOP"

        /** The notification's own "Stop sharing". */
        const val ACTION_STOP_CAPTURE = "com.raindrop.raindrop_client.CAPTURE_STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        /**
         * Low importance: an ongoing call is worth a visible entry, not a
         * sound or a heads-up banner every time its text changes.
         */
        private const val CHANNEL_ID = "raindrop.call"
        private const val NOTIFICATION_ID = 1

        /**
         * The name flutter_webrtc gives the virtual display a screen capture
         * draws into (`OrientationAwareScreenCapturer`). It is the only handle
         * there is on a capture this app did not start itself: see
         * [watchCapture].
         */
        private const val CAPTURE_DISPLAY = "WebRTC_ScreenCapture"

        /**
         * How long a capture's display may be missing before it counts as
         * gone. Turning the phone releases the display and makes another, so
         * a moment without one is a rotation, not an ending.
         */
        private const val CAPTURE_GONE_AFTER_MS = 1500L

        /** The running service, if there is one. Only touched on the main thread. */
        private var instance: CallForegroundService? = null

        /**
         * Told when a capture ended from outside the app: the notification's
         * Stop sharing, or the system closing the capture itself. Set by
         * `MainActivity`, which is what can reach Dart.
         */
        var onCaptureEnded: (() -> Unit)? = null

        /** Starts, or updates the text of, the ongoing-call notification. */
        fun start(context: Context, title: String, body: String) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
            }
            // A foreground service may be started from the background only
            // because the app is in a call the user began themselves.
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            // Not startForegroundService: stopping must not promise a
            // startForeground() call the service will never make.
            context.startService(intent)
        }

        /**
         * Shows the notification again as it stands — for when it was posted
         * before the user allowed notifications, which Android drops.
         */
        fun refresh() {
            val service = instance ?: return
            runCatching { service.startInForeground() }
        }

        /**
         * Says the call is about to capture the screen, or has stopped, and
         * answers whether the service now stands as it was asked to.
         *
         * Done on the running service directly rather than through an intent:
         * the capture starts the moment this returns, and an intent would only
         * be delivered some time after. False when there is no service to ask
         * — no call — or the system refused it the type, which it does when
         * the user has not agreed to a capture.
         */
        fun setCapturing(capturing: Boolean): Boolean {
            val service = instance ?: return !capturing
            return service.setCapturing(capturing)
        }
    }

    private var title = ""
    private var body = ""
    private var capturing = false

    /** Whether this capture's display has been seen yet: see [captureDisplayIsLive]. */
    private var captureSeen = false

    private val main = Handler(Looper.getMainLooper())
    private var displayListener: DisplayManager.DisplayListener? = null
    private val captureGone = Runnable { reportCaptureGone() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        unwatchCapture()
        if (instance === this) instance = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_START -> {
                title = intent.getStringExtra(EXTRA_TITLE) ?: getString(R.string.call_ongoing)
                body = intent.getStringExtra(EXTRA_BODY).orEmpty()
                startInForeground()
            }

            // Tapped in the notification. The share is Dart's to end — the
            // server has to be told — so this only passes the word on; the
            // type and the notification follow when Dart says it has stopped.
            ACTION_STOP_CAPTURE -> onCaptureEnded?.invoke()

            // Restarted by the system with no intent: there is no call to
            // keep alive any more, since Dart's call state did not survive.
            else -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        // The call is Dart's state; a service the system restarts on its own
        // would show a notification for a call that is no longer happening.
        return START_NOT_STICKY
    }

    private fun setCapturing(wanted: Boolean): Boolean {
        if (capturing == wanted) return true
        capturing = wanted
        captureSeen = false
        return try {
            startInForeground()
            if (wanted) watchCapture() else unwatchCapture()
            true
        } catch (e: Exception) {
            // Android 14+ refuses the type without the user's consent to a
            // capture (a SecurityException), and has other ways of saying no
            // to a foreground service besides. Whichever it was, the call
            // carries on as a call; the share does not start.
            Log.w(TAG, "the call service could not take the screen-capture type", e)
            capturing = false
            unwatchCapture()
            runCatching { startInForeground() }
            false
        }
    }

    private fun startInForeground() {
        ensureChannel()
        val notification = buildNotification()
        when {
            // Named outright from Android 11, where both types exist: only
            // what is really going on, so a call that is not sharing never
            // claims to be capturing the screen.
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> startForeground(
                NOTIFICATION_ID,
                notification,
                if (capturing) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                },
            )

            // Before that the service simply has every type its manifest
            // entry lists, which is what an untyped start means.
            else -> startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        // Tapping it comes back to the call rather than starting a second
        // copy of the app: the launch activity is `singleTop`.
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = launch?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            // The call ends from inside the app, not by swiping this away.
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setContentIntent(pending)

        if (capturing) {
            // Said first, because it is the part somebody would want to know
            // from a glance at the shade — and stoppable from there, since
            // the whole point of sharing is being in some other app.
            builder
                .setContentText(getString(R.string.call_sharing_screen))
                .setSubText(title)
                .addAction(
                    0,
                    getString(R.string.call_stop_sharing),
                    PendingIntent.getService(
                        this,
                        1,
                        Intent(this, CallForegroundService::class.java).apply {
                            action = ACTION_STOP_CAPTURE
                        },
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
        }

        return builder.build()
    }

    /**
     * Notices a capture the *system* ended: its own stop control in the
     * status bar, or — from Android 14 — the screen locking.
     *
     * Nothing reports this. The projection belongs to flutter_webrtc, whose
     * `MediaProjection.Callback.onStop` does nothing, and the media track
     * simply stops receiving frames, which is also what a screen that is not
     * changing looks like. What does change is the virtual display the
     * capture draws into: the system switches it off when the projection
     * stops, and it disappears when the capture is released. So that display
     * is watched, by the name flutter_webrtc gives it.
     *
     * A display that is briefly missing is a rotation, which replaces it —
     * hence the wait before believing it ([CAPTURE_GONE_AFTER_MS]).
     */
    private fun watchCapture() {
        if (displayListener != null) return
        val manager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val listener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = checkCaptureSoon()
            override fun onDisplayRemoved(displayId: Int) = checkCaptureSoon()
            override fun onDisplayChanged(displayId: Int) = checkCaptureSoon()
        }
        displayListener = listener
        manager.registerDisplayListener(listener, main)
    }

    private fun unwatchCapture() {
        main.removeCallbacks(captureGone)
        val listener = displayListener ?: return
        displayListener = null
        (getSystemService(Context.DISPLAY_SERVICE) as DisplayManager)
            .unregisterDisplayListener(listener)
    }

    private fun checkCaptureSoon() {
        main.removeCallbacks(captureGone)
        main.postDelayed(captureGone, CAPTURE_GONE_AFTER_MS)
    }

    private fun reportCaptureGone() {
        if (!capturing || captureDisplayIsLive()) return
        onCaptureEnded?.invoke()
    }

    /**
     * Whether a capture's display is there and switched on. One that was
     * never seen at all counts as live: the listener is registered just
     * before the capture opens it, and a share must not be ended for not
     * having started yet.
     */
    private fun captureDisplayIsLive(): Boolean {
        val manager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val display = manager.displays.firstOrNull { it.name == CAPTURE_DISPLAY }
        if (display == null) return !captureSeen
        captureSeen = true
        return display.state != Display.STATE_OFF
    }

    private fun ensureChannel() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.call_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.call_channel_description)
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }
}
