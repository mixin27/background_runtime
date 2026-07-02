package dev.mixin27.background_runtime_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BackgroundRuntimeService : Service() {

    companion object {
        const val CHANNEL_ID = "background_runtime_channel"
        const val NOTIFICATION_ID = 1
        const val AUDIO_NOTIFICATION_ID = 2

        @Volatile
        private var instance: BackgroundRuntimeService? = null

        fun updateDownloadNotification(taskId: String, bytesReceived: Long, totalBytes: Long) {
            val service = instance ?: return
            val progress = if (totalBytes > 0) (bytesReceived * 100 / totalBytes).toInt() else 0
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Downloading")
                .setContentText("$progress% - $bytesReceived / $totalBytes bytes")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setProgress(100, progress, false)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }

        fun updateDownloadCompleteNotification(taskId: String) {
            val service = instance ?: return
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Download complete")
                .setContentText("Download finished successfully")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setProgress(0, 0, false)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }

        fun updateDownloadPausedNotification(taskId: String) {
            val service = instance ?: return
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Download paused")
                .setContentText("Download is paused")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }

        fun updateDownloadFailedNotification(taskId: String) {
            val service = instance ?: return
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Download failed")
                .setContentText("Download encountered an error")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }

        fun resetNotification() {
            val service = instance ?: return
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle("Background Runtime")
                .setContentText("Running in background")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }

        fun updateAudioNotification(title: String, artist: String, isPlaying: Boolean) {
            val service = instance ?: return
            val notification = NotificationCompat.Builder(service, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(artist)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.notify(AUDIO_NOTIFICATION_ID, notification)
        }

        fun removeAudioNotification() {
            val service = instance ?: return
            val manager = service.getSystemService(NotificationManager::class.java)
            manager.cancel(AUDIO_NOTIFICATION_ID)
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createDefaultNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
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
