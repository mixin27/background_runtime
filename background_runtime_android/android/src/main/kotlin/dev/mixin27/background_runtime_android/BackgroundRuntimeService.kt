package dev.mixin27.background_runtime_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class BackgroundRuntimeService : Service() {

    companion object {
        const val CHANNEL_ID = "background_runtime_channel"
        const val NOTIFICATION_ID = 1
        const val DOWNLOAD_NOTIFICATION_ID = 1001
        const val AUDIO_NOTIFICATION_ID = 2

        const val ACTION_PLAY = "dev.mixin27.background_runtime.action.PLAY"
        const val ACTION_PAUSE = "dev.mixin27.background_runtime.action.PAUSE"
        const val ACTION_STOP = "dev.mixin27.background_runtime.action.STOP"

        @Volatile
        private var instance: BackgroundRuntimeService? = null

        // --- Download Notifications ---

        fun updateDownloadNotification(taskId: String, bytesReceived: Long, totalBytes: Long) {
            val service = instance ?: return
            val builder = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Downloading")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
            if (totalBytes > 0) {
                val progress = (bytesReceived * 100 / totalBytes).toInt()
                val sizeText = formatFileSize(bytesReceived) + " / " + formatFileSize(totalBytes)
                builder.setContentText("$progress% - $sizeText")
                    .setProgress(100, progress, false)
            } else {
                builder.setContentText(formatFileSize(bytesReceived) + " downloaded")
                    .setProgress(0, 0, true)
            }
            val notification = builder.build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(DOWNLOAD_NOTIFICATION_ID, notification)
        }

        private fun replaceDownloadNotification(
            title: String,
            text: String
        ) {
            val service = instance ?: return
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.cancel(DOWNLOAD_NOTIFICATION_ID)
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            manager.notify(DOWNLOAD_NOTIFICATION_ID, notification)
        }

        fun updateDownloadCompleteNotification(taskId: String) {
            replaceDownloadNotification("Download complete", "Download finished successfully")
        }

        fun updateDownloadPausedNotification(taskId: String) {
            replaceDownloadNotification("Download paused", "Download is paused")
        }

        fun updateDownloadFailedNotification(taskId: String) {
            replaceDownloadNotification("Download failed", "Download encountered an error")
        }

        fun resetNotification() {
            val service = instance ?: return
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.cancel(DOWNLOAD_NOTIFICATION_ID)
        }

        // --- Audio Notifications ---

        fun updateAudioNotification(
            title: String,
            artist: String,
            isPlaying: Boolean,
            positionMillis: Long = 0,
            durationMillis: Long = 0
        ) {
            val service = instance ?: return
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pauseIntent = PendingIntent.getService(
                service,
                1001,
                Intent(service, BackgroundRuntimeService::class.java).setAction(ACTION_PAUSE),
                pendingIntentFlags
            )
            val playIntent = PendingIntent.getService(
                service,
                1002,
                Intent(service, BackgroundRuntimeService::class.java).setAction(ACTION_PLAY),
                pendingIntentFlags
            )
            val stopIntent = PendingIntent.getService(
                service,
                1003,
                Intent(service, BackgroundRuntimeService::class.java).setAction(ACTION_STOP),
                pendingIntentFlags
            )

            val builder = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(artist)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(isPlaying)

            if (durationMillis > 0 && positionMillis >= 0) {
                builder.setProgress(durationMillis.toInt(), positionMillis.toInt(), false)
            } else {
                builder.setProgress(0, 0, true)
            }

            if (isPlaying) {
                builder.addAction(android.R.drawable.ic_media_pause, "Pause", pauseIntent)
            } else {
                builder.addAction(android.R.drawable.ic_media_play, "Play", playIntent)
            }
            builder.addAction(android.R.drawable.ic_media_ff, "Stop", stopIntent)

            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(AUDIO_NOTIFICATION_ID, builder.build())
        }

        fun removeAudioNotification() {
            val service = instance ?: return
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.cancel(AUDIO_NOTIFICATION_ID)
        }

        // --- Helpers ---

        private fun formatFileSize(bytes: Long): String {
            if (bytes <= 0) return "0 B"
            return when {
                bytes < 1024 -> "$bytes B"
                bytes < 1024 * 1024 -> String.format("%.1f KB", bytes / 1024.0)
                bytes < 1024 * 1024 * 1024 -> String.format("%.1f MB", bytes / (1024.0 * 1024.0))
                else -> String.format("%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0))
            }
        }
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createDefaultNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> serviceScope.launch {
                AudioPlayerManager.resume(applicationContext)
            }
            ACTION_PAUSE -> serviceScope.launch {
                AudioPlayerManager.pause(applicationContext)
            }
            ACTION_STOP -> serviceScope.launch {
                AudioPlayerManager.stop(applicationContext)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
        serviceScope.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Background Runtime",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background runtime service notification"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createDefaultNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Background Runtime")
            .setContentText("Running in background")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
