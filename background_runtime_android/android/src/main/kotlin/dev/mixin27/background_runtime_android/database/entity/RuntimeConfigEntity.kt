package dev.mixin27.background_runtime_android.database.entity

data class RuntimeConfigEntity(
    val id: Int = 1,
    val enableDownloads: Boolean = true,
    val enableAudio: Boolean = true,
    val enableNotifications: Boolean = true,
    val keepAlive: Boolean = true,
    val autoResume: Boolean = false
)
