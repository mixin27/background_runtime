package dev.mixin27.background_runtime_android

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

internal object DownloadManager {

    private val client = OkHttpClient.Builder()
        .followRedirects(true)
        .build()

    private val activeDownloads = ConcurrentHashMap<String, DownloadState>()
    private val pausedDownloads = ConcurrentHashMap<String, Long>()
    private val downloadProgress = ConcurrentHashMap<String, DownloadProgressListener>()

    fun interface DownloadProgressListener {
        fun onProgress(bytesRead: Long, totalBytes: Long)
    }

    suspend fun startDownload(context: Context, request: Map<String, Any?>?): String {
        val url = request?.get("url") as? String
            ?: throw IllegalArgumentException("URL is required")
        val destinationPath = request["destinationPath"] as? String
            ?: throw IllegalArgumentException("Destination path is required")

        val taskId = UUID.randomUUID().toString()
        activeDownloads[taskId] = DownloadState.DOWNLOADING

        withContext(Dispatchers.IO) {
            performDownload(taskId, url, destinationPath)
        }

        return taskId
    }

    private suspend fun performDownload(taskId: String, url: String, destinationPath: String) {
        val file = File(destinationPath)
        val request = Request.Builder().url(url).build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            activeDownloads[taskId] = DownloadState.FAILED
            throw RuntimeException("Download failed with HTTP ${response.code}")
        }

        val body = response.body ?: throw RuntimeException("Response body is null")
        val contentLength = body.contentLength()

        val outputStream = FileOutputStream(file)
        val inputStream = body.byteStream()
        val buffer = ByteArray(8192)
        var bytesRead: Int
        var totalBytesRead = 0L

        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            if (pausedDownloads.containsKey(taskId)) {
                pausedDownloads[taskId] = totalBytesRead
                activeDownloads[taskId] = DownloadState.PAUSED
                outputStream.close()
                return
            }

            if (activeDownloads[taskId] == DownloadState.CANCELLED) {
                outputStream.close()
                file.delete()
                return
            }

            outputStream.write(buffer, 0, bytesRead)
            totalBytesRead += bytesRead
            downloadProgress[taskId]?.onProgress(totalBytesRead, contentLength)
        }

        outputStream.close()
        inputStream.close()
        activeDownloads[taskId] = DownloadState.COMPLETED
    }

    fun pauseDownload(taskId: String) {
        val state = activeDownloads[taskId]
        if (state == DownloadState.DOWNLOADING) {
            pausedDownloads[taskId] = 0L
        }
    }

    fun resumeDownload(taskId: String) {
        val state = activeDownloads[taskId]
        if (state == DownloadState.PAUSED) {
            pausedDownloads.remove(taskId)
            activeDownloads[taskId] = DownloadState.DOWNLOADING
        }
    }

    fun cancelDownload(taskId: String) {
        activeDownloads[taskId] = DownloadState.CANCELLED
        pausedDownloads.remove(taskId)
    }

    fun setProgressListener(taskId: String, listener: DownloadProgressListener) {
        downloadProgress[taskId] = listener
    }

    fun removeProgressListener(taskId: String) {
        downloadProgress.remove(taskId)
    }
}

internal enum class DownloadState {
    PENDING,
    DOWNLOADING,
    PAUSED,
    COMPLETED,
    FAILED,
    CANCELLED
}
