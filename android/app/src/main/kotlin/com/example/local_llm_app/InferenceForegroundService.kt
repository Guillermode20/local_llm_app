package com.example.local_llm_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps the app process alive during LLM inference.
 *
 * The service does NOT run inference itself — the Dart isolate does.
 * It exists only to keep the process alive and surface a notification
 * so Android doesn't kill the app during long generation turns.
 */
class InferenceForegroundService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val notification = buildNotification("Generating reply…", 0)
                startForeground(NOTIFICATION_ID, notification)
                acquireWakeLock()
            }
            ACTION_UPDATE_PROGRESS -> {
                val tokens = intent.getIntExtra(EXTRA_TOKENS, 0)
                val notification = buildNotification(
                    "Generating reply…",
                    tokens
                )
                val manager = getSystemService(NotificationManager::class.java)
                manager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_STOP -> {
                releaseWakeLock()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "LLM Inference",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shown while the model is generating a response"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String, tokensGenerated: Int): Notification {
        val contentText = if (tokensGenerated > 0) {
            "$text ($tokensGenerated tokens)"
        } else {
            text
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Local LLM")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun acquireWakeLock() {
        if (wakeLock == null || wakeLock?.isHeld == false) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                WAKE_LOCK_TAG
            ).apply {
                acquire(WAKE_LOCK_TIMEOUT_MS)
            }
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    companion object {
        const val CHANNEL_ID = "llm_inference"
        const val NOTIFICATION_ID = 1001
        const val WAKE_LOCK_TAG = "app:llm-inference"
        const val WAKE_LOCK_TIMEOUT_MS = 120_000L // 2 minutes max

        const val ACTION_START = "com.example.local_llm_app.START"
        const val ACTION_UPDATE_PROGRESS = "com.example.local_llm_app.UPDATE_PROGRESS"
        const val ACTION_STOP = "com.example.local_llm_app.STOP"
        const val EXTRA_TOKENS = "tokens"

        fun start(context: Context) {
            val intent = Intent(context, InferenceForegroundService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun updateProgress(context: Context, tokens: Int) {
            val intent = Intent(context, InferenceForegroundService::class.java).apply {
                action = ACTION_UPDATE_PROGRESS
                putExtra(EXTRA_TOKENS, tokens)
            }
            context.startService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, InferenceForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}
