package com.raindrop.raindrop_client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
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
 * The service holds no call state of its own. Dart owns the call (see
 * `core/voice/call_session_host.dart`); this only keeps the process alive and
 * shows what is going on, so a call that ends while the app is backgrounded
 * still takes the notification with it.
 */
class CallForegroundService : Service() {

    companion object {
        // There is no separate "update": starting an already-started
        // foreground service just re-issues its notification, so describing a
        // call again and starting one are the same request.
        const val ACTION_START = "com.raindrop.raindrop_client.CALL_START"
        const val ACTION_STOP = "com.raindrop.raindrop_client.CALL_STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        /**
         * Low importance: an ongoing call is worth a visible entry, not a
         * sound or a heads-up banner every time its text changes.
         */
        private const val CHANNEL_ID = "raindrop.call"
        private const val NOTIFICATION_ID = 1

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
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: getString(R.string.call_ongoing)
                val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
                startInForeground(title, body)
            }

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

    private fun startInForeground(title: String, body: String) {
        ensureChannel()
        val notification = buildNotification(title, body)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(title: String, body: String): Notification {
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

        return NotificationCompat.Builder(this, CHANNEL_ID)
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
            .build()
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
