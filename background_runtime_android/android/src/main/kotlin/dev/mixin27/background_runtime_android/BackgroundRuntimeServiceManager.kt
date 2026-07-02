package dev.mixin27.background_runtime_android

import android.content.Context
import android.content.Intent
import android.os.Build
import dev.mixin27.background_runtime_android.database.DatabaseProvider

internal object BackgroundRuntimeServiceManager {

    private var isInitialized = false

    suspend fun initialize(context: Context, config: Map<String, Any?>?) {
        if (isInitialized) return

        DatabaseProvider.getDatabase(context)

        config?.let { storeConfig(context, it) }

        DownloadManager.restoreState(context)

        val intent = Intent(context, BackgroundRuntimeService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
        isInitialized = true
    }

    fun shutdown(context: Context) {
        if (!isInitialized) return

        val intent = Intent(context, BackgroundRuntimeService::class.java)
        context.stopService(intent)
        isInitialized = false
    }

    private suspend fun storeConfig(context: Context, config: Map<String, Any?>) {
        val entity = dev.mixin27.background_runtime_android.database.entity.RuntimeConfigEntity(
            enableDownloads = config["enableDownloads"] as? Boolean ?: true,
            enableAudio = config["enableAudio"] as? Boolean ?: true,
            enableNotifications = config["enableNotifications"] as? Boolean ?: true,
            keepAlive = config["keepAlive"] as? Boolean ?: true,
            autoResume = config["autoResume"] as? Boolean ?: false
        )
        val db = dev.mixin27.background_runtime_android.database.DatabaseProvider.getDatabase(context)
        db.runtimeConfigDao.upsertConfig(entity)
    }
}
