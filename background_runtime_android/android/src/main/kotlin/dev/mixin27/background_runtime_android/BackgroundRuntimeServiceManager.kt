package dev.mixin27.background_runtime_android

import android.content.Context
import android.content.Intent

internal object BackgroundRuntimeServiceManager {

    private var isInitialized = false

    fun initialize(context: Context, config: Map<String, Any?>?) {
        if (isInitialized) return

        val intent = Intent(context, BackgroundRuntimeService::class.java)
        context.startForegroundService(intent)
        isInitialized = true
    }

    fun shutdown(context: Context) {
        if (!isInitialized) return

        val intent = Intent(context, BackgroundRuntimeService::class.java)
        context.stopService(intent)
        isInitialized = false
    }
}
