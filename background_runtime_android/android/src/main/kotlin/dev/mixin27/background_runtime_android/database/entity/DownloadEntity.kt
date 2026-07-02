package dev.mixin27.background_runtime_android.database.entity

data class DownloadEntity(
    val taskId: String,
    val url: String,
    val destinationPath: String,
    val headersJson: String? = null,
    val state: String,
    val progress: Long = 0L,
    val totalBytes: Long = 0L,
    val contentType: String? = null,
    val saveToPublic: Boolean = false,
    val createdAt: Long,
    val updatedAt: Long
)
