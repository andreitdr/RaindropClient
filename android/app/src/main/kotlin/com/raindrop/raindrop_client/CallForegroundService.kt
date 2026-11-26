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
import androidx.core.app.Person

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
 *
 * **It shows the call as a call** while the person wants that (Settings,
 * "Show calls in the status bar"): a `CallStyle` notification, which Android
 * 12+ draws as a chip with the call's time in the status bar, asking to be
 * promoted to a Live Update on Android 16 — which is what Samsung's Now Bar and
 * other makers' islands show. Its Mute and Leave are sent to Dart like the
 * call bar's buttons ([onAction]). Otherwise it is a plain ongoing
 * notification, with the same two actions.
 *
 * **Swiping the app away ends the call**, as on an iPhone ([onTaskRemoved]).
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

        /** The notification's Mute/Unmute and Leave call. */
        const val ACTION_TOGGLE_MUTE = "com.raindrop.raindrop_client.CALL_TOGGLE_MUTE"
        const val ACTION_LEAVE = "com.raindrop.raindrop_client.CALL_LEAVE"

        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_CONNECTED_AT = "connectedAt"
        const val EXTRA_MIC_ON = "micOn"
        const val EXTRA_DEAFENED = "deafened"
        const val EXTRA_RECONNECTING = "reconnecting"
        const val EXTRA_PROMINENT = "prominent"

        /**
         * How long a swiped-away app's call is given to say goodbye to the
         * server before the service stops and the process goes with it.
         */
        private const val LEAVE_ON_TASK_REMOVED_MS = 1500L

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

        /**
         * Told the name of a control pressed in the notification — `toggleMute`
         * or `leave`, as Dart's `CallSessionAction` knows them. Set by
         * `MainActivity`, which is what can reach Dart.
         */
        var onAction: ((String) -> Unit)? = null

        /** Starts the ongoing-call notification, or brings it up to date. */
        fun start(context: Context, call: CallDescription) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, call.title)
                putExtra(EXTRA_BODY, call.body)
                putExtra(EXTRA_CONNECTED_AT, call.connectedAt)
                putExtra(EXTRA_MIC_ON, call.micOn)
                putExtra(EXTRA_DEAFENED, call.deafened)
                putExtra(EXTRA_RECONNECTING, call.reconnecting)
                putExtra(EXTRA_PROMINENT, call.prominent)
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

    private var call = CallDescription()
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
                call = CallDescription(
                    title = intent.getStringExtra(EXTRA_TITLE)
                        ?.takeIf { it.isNotEmpty() }
                        ?: getString(R.string.call_ongoing),
                    body = intent.getStringExtra(EXTRA_BODY).orEmpty(),
                    connectedAt = intent.getLongExtra(EXTRA_CONNECTED_AT, 0L),
                    micOn = intent.getBooleanExtra(EXTRA_MIC_ON, true),
                    deafened = intent.getBooleanExtra(EXTRA_DEAFENED, false),
                    reconnecting = intent.getBooleanExtra(EXTRA_RECONNECTING, false),
                    prominent = intent.getBooleanExtra(EXTRA_PROMINENT, true),
                )
                startInForeground()
            }

            // Pressed in the notification: Dart's to do, as from the call bar.
            // The notification follows when Dart describes the call again.
            ACTION_TOGGLE_MUTE -> onAction?.invoke("toggleMute")
            ACTION_LEAVE -> onAction?.invoke("leave")

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

    /**
     * The app was swiped away from Recents. That ends its call, as it does on
     * an iPhone: Dart is asked to leave while it still can, and the service
     * stops shortly after whether or not it did — the activity, and the Flutter
     * engine with it, are going, so nothing would be left to end it later, and
     * the notification would be announcing a microphone nobody is using.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        onAction?.invoke("leave")
        main.postDelayed({
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }, LEAVE_ON_TASK_REMOVED_MS)
        super.onTaskRemoved(rootIntent)
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
            .setContentTitle(call.title)
            .setContentText(statusLine())
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            // The call ends from inside the app or with Leave, not by swiping
            // this away.
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pending)
            // A Live Update is never colorized, so neither is this.
            .setColorized(false)

        // The call's own time, which the system keeps running — the chip in
        // the status bar shows it too.
        if (call.connectedAt > 0L) {
            builder.setWhen(call.connectedAt).setShowWhen(true).setUsesChronometer(true)
        } else {
            builder.setShowWhen(false)
        }

        val leave = serviceIntent(ACTION_LEAVE, 3)
        if (call.prominent) {
            val caller = Person.Builder()
                .setName(call.title)
                .setImportant(true)
                .build()
            builder
                .setStyle(NotificationCompat.CallStyle.forOngoingCall(caller, leave))
                // Android 16's Live Updates: the status bar chip, the lock
                // screen, and whatever a maker builds on them. Android shows
                // it only where the person has not turned it off.
                .setRequestPromotedOngoing(true)
        } else {
            builder.addAction(0, getString(R.string.call_leave), leave)
        }
        builder.addAction(
            0,
            getString(if (call.micOn) R.string.call_mute else R.string.call_unmute),
            serviceIntent(ACTION_TOGGLE_MUTE, 2),
        )

        if (capturing) {
            // Said first, because it is the part somebody would want to know
            // from a glance at the shade — and stoppable from there, since
            // the whole point of sharing is being in some other app.
            builder
                .setContentText(getString(R.string.call_sharing_screen))
                .setSubText(call.title)
                .addAction(
                    0,
                    getString(R.string.call_stop_sharing),
                    serviceIntent(ACTION_STOP_CAPTURE, 1),
                )
        }

        return builder.build()
    }

    /** The server, and whether this member can be heard. */
    private fun statusLine(): String {
        if (call.reconnecting) return getString(R.string.call_reconnecting)
        val state = when {
            call.deafened -> getString(R.string.call_deafened)
            !call.micOn -> getString(R.string.call_muted)
            else -> null
        }
        return listOfNotNull(call.body.takeIf { it.isNotEmpty() }, state).joinToString(" · ")
    }

    /** One of the notification's own actions, delivered back to this service. */
    private fun serviceIntent(action: String, requestCode: Int): PendingIntent =
        PendingIntent.getService(
            this,
            requestCode,
            Intent(this, CallForegroundService::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

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

/**
 * The call as Dart describes it (`CallSessionDescription.toMap()`), less what
 * the notification does not show.
 */
data class CallDescription(
    val title: String = "",
    val body: String = "",
    /** When the call first connected, in epoch milliseconds; 0 before then. */
    val connectedAt: Long = 0L,
    val micOn: Boolean = true,
    val deafened: Boolean = false,
    val reconnecting: Boolean = false,
    /** Shown as a call — the status bar chip, a Live Update — not only in the shade. */
    val prominent: Boolean = true,
)
