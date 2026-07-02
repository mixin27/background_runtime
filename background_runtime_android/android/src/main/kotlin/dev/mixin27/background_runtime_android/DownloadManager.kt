package dev.mixin27.background_runtime_android

import android.content.Context
import dev.mixin27.background_runtime_android.database.DatabaseProvider
import dev.mixin27.background_runtime_android.database.entity.DownloadEntity
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

internal object DownloadManager : EventChannel.StreamHandler {

    private val client = OkHttpClient.Builder()
        .followRedirects(true)
        .build()

    private val activeDownloads = ConcurrentHashMap<String, DownloadState>()
    private val pausedDownloads = ConcurrentHashMap<String, Long>()
    private val publicDownloads = ConcurrentHashMap<String, Boolean>()

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private suspend fun emitProgress(taskId: String, bytesReceived: Long, totalBytes: Long) {
        withContext(Dispatchers.Main) {
            eventSink?.success(
                mapOf(
                    "taskId" to taskId,
                    "state" to "DOWNLOADING",
                    "bytesReceived" to bytesReceived,
                    "totalBytes" to totalBytes
                )
            )
        }
    }

    private suspend fun emitCompleted(taskId: String, bytesReceived: Long, totalBytes: Long) {
        withContext(Dispatchers.Main) {
            eventSink?.success(
                mapOf(
                    "taskId" to taskId,
                    "state" to "COMPLETED",
                    "bytesReceived" to bytesReceived,
                    "totalBytes" to totalBytes
                )
            )
        }
    }

    private suspend fun emitPaused(taskId: String, bytesReceived: Long, totalBytes: Long) {
        withContext(Dispatchers.Main) {
            eventSink?.success(
                mapOf(
                    "taskId" to taskId,
                    "state" to "PAUSED",
                    "bytesReceived" to bytesReceived,
                    "totalBytes" to totalBytes
                )
            )
        }
    }

    private suspend fun emitFailed(taskId: String, error: String) {
        withContext(Dispatchers.Main) {
            eventSink?.success(
                mapOf(
                    "taskId" to taskId,
                    "state" to "FAILED",
                    "error" to error
                )
            )
        }
    }

    suspend fun startDownload(context: Context, request: Map<String, Any?>?): String {
        val url = request?.get("url") as? String
            ?: throw IllegalArgumentException("URL is required")
        val destinationPath = request["destinationPath"] as? String
            ?: throw IllegalArgumentException("Destination path is required")

        val rawHeaders = request["headers"] as? Map<*, *>
        val headersJson = rawHeaders?.let { JSONObject(it as Map<String, Any>).toString() }
        val saveToPublic = request["saveToPublic"] as? Boolean ?: false

        val taskId = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()

        val entity = DownloadEntity(
            taskId = taskId,
            url = url,
            destinationPath = destinationPath,
            headersJson = headersJson,
            state = DownloadState.DOWNLOADING.name,
            saveToPublic = saveToPublic,
            createdAt = now,
            updatedAt = now
        )

        activeDownloads[taskId] = DownloadState.DOWNLOADING
        publicDownloads[taskId] = saveToPublic

        val db = DatabaseProvider.getDatabase(context)
        db.downloadDao.insertDownload(entity)

        withContext(Dispatchers.IO) {
            performDownload(context, taskId, url, destinationPath, saveToPublic)
        }

        return taskId
    }

    private fun resolveOutputStream(
        context: Context,
        destinationPath: String,
        saveToPublic: Boolean
    ): OutputStream {
        return if (saveToPublic) {
            val fileName = destinationPath.substringAfterLast('/')
                .ifEmpty { destinationPath }
            PublicStorageResolver.resolveOutputStream(context, fileName)
                ?: throw RuntimeException("Failed to open public storage output stream")
        } else {
            val file = File(destinationPath)
            file.parentFile?.mkdirs()
            FileOutputStream(file)
        }
    }

    private fun resolveFileForCleanup(
        destinationPath: String,
        saveToPublic: Boolean
    ): File? {
        if (saveToPublic) return null
        return File(destinationPath)
    }

    private suspend fun performDownload(
        context: Context,
        taskId: String,
        url: String,
        destinationPath: String,
        saveToPublic: Boolean
    ) {
        val request = Request.Builder().url(url).build()
        val db = DatabaseProvider.getDatabase(context)

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            val errorMsg = "Download failed with HTTP ${response.code}"
            activeDownloads[taskId] = DownloadState.FAILED
            db.downloadDao.updateState(taskId, DownloadState.FAILED.name, System.currentTimeMillis())
            emitFailed(taskId, errorMsg)
            throw RuntimeException(errorMsg)
        }

        val body = response.body ?: run {
            val errorMsg = "Response body is null"
            activeDownloads[taskId] = DownloadState.FAILED
            db.downloadDao.updateState(taskId, DownloadState.FAILED.name, System.currentTimeMillis())
            emitFailed(taskId, errorMsg)
            throw RuntimeException(errorMsg)
        }

        val contentLength = body.contentLength()

        val outputStream = resolveOutputStream(context, destinationPath, saveToPublic)
        val inputStream = body.byteStream()
        val buffer = ByteArray(8192)
        var bytesRead: Int
        var totalBytesRead = 0L

        try {
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                if (pausedDownloads.containsKey(taskId)) {
                    pausedDownloads[taskId] = totalBytesRead
                    activeDownloads[taskId] = DownloadState.PAUSED
                    db.downloadDao.updateState(taskId, DownloadState.PAUSED.name, System.currentTimeMillis())
                    db.downloadDao.updateProgress(taskId, totalBytesRead, contentLength, System.currentTimeMillis())
                    emitPaused(taskId, totalBytesRead, contentLength)
                    return
                }

                if (activeDownloads[taskId] == DownloadState.CANCELLED) {
                    cleanup(context, destinationPath, saveToPublic)
                    db.downloadDao.deleteDownload(taskId)
                    return
                }

                outputStream.write(buffer, 0, bytesRead)
                totalBytesRead += bytesRead
                emitProgress(taskId, totalBytesRead, contentLength)
            }
        } catch (e: Exception) {
            outputStream.close()
            inputStream.close()
            cleanup(context, destinationPath, saveToPublic)
            activeDownloads[taskId] = DownloadState.FAILED
            db.downloadDao.updateState(taskId, DownloadState.FAILED.name, System.currentTimeMillis())
            emitFailed(taskId, e.message ?: "Download failed")
            throw e
        }

        outputStream.close()
        inputStream.close()
        activeDownloads[taskId] = DownloadState.COMPLETED
        db.downloadDao.updateState(taskId, DownloadState.COMPLETED.name, System.currentTimeMillis())
        db.downloadDao.updateProgress(taskId, totalBytesRead, contentLength, System.currentTimeMillis())
        emitCompleted(taskId, totalBytesRead, contentLength)
    }

    private fun cleanup(context: Context, destinationPath: String, saveToPublic: Boolean) {
        if (saveToPublic) {
            val fileName = destinationPath.substringAfterLast('/')
                .ifEmpty { destinationPath }
            PublicStorageResolver.deletePending(context, fileName)
        } else {
            resolveFileForCleanup(destinationPath, false)?.delete()
        }
    }

    suspend fun pauseDownload(context: Context, taskId: String) {
        val state = activeDownloads[taskId]
        if (state == DownloadState.DOWNLOADING) {
            pausedDownloads[taskId] = 0L
        }
    }

    suspend fun resumeDownload(context: Context, taskId: String) {
        val state = activeDownloads[taskId]
        if (state == DownloadState.PAUSED) {
            pausedDownloads.remove(taskId)
            activeDownloads[taskId] = DownloadState.DOWNLOADING
            val db = DatabaseProvider.getDatabase(context)
            db.downloadDao.updateState(taskId, DownloadState.DOWNLOADING.name, System.currentTimeMillis())
        }
    }

    suspend fun cancelDownload(context: Context, taskId: String) {
        val saveToPublic = publicDownloads[taskId] ?: false
        activeDownloads[taskId] = DownloadState.CANCELLED
        pausedDownloads.remove(taskId)
        val db = DatabaseProvider.getDatabase(context)
        val download = db.downloadDao.getDownload(taskId)
        if (download != null) {
            cleanup(context, download.destinationPath, saveToPublic)
        }
        db.downloadDao.deleteDownload(taskId)
    }

    suspend fun restoreState(context: Context) {
        val db = DatabaseProvider.getDatabase(context)
        val active = db.downloadDao.getActiveDownloads()
        for (download in active) {
            publicDownloads[download.taskId] = download.saveToPublic
            activeDownloads[download.taskId] = when (download.state) {
                "DOWNLOADING" -> DownloadState.DOWNLOADING
                "PAUSED" -> {
                    pausedDownloads[download.taskId] = download.progress
                    DownloadState.PAUSED
                }
                else -> null
            } ?: continue
        }
    }

    fun getDownloadState(taskId: String): DownloadState? = activeDownloads[taskId]
}

internal enum class DownloadState {
    PENDING,
    DOWNLOADING,
    PAUSED,
    COMPLETED,
    FAILED,
    CANCELLED
}
