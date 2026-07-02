package dev.mixin27.background_runtime_android.database.dao

import android.database.Cursor
import dev.mixin27.background_runtime_android.database.entity.DownloadEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal class DownloadDao(private val db: android.database.sqlite.SQLiteDatabase) {

    fun getAllDownloads(): List<DownloadEntity> {
        val cursor = db.query("downloads", null, null, null, null, null, "created_at DESC")
        return cursor.use { parseDownloads(it) }
    }

    suspend fun getDownload(taskId: String): DownloadEntity? = withContext(Dispatchers.IO) {
        val cursor = db.query("downloads", null, "task_id = ?", arrayOf(taskId), null, null, null)
        cursor.use { parseDownloads(it).firstOrNull() }
    }

    suspend fun insertDownload(download: DownloadEntity) = withContext(Dispatchers.IO) {
        val values = toContentValues(download)
        db.insertWithOnConflict("downloads", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
    }

    suspend fun updateState(taskId: String, state: String, updatedAt: Long) = withContext(Dispatchers.IO) {
        val values = android.content.ContentValues().apply {
            put("state", state)
            put("updated_at", updatedAt)
        }
        db.update("downloads", values, "task_id = ?", arrayOf(taskId))
    }

    suspend fun updateProgress(taskId: String, progress: Long, totalBytes: Long, updatedAt: Long) = withContext(Dispatchers.IO) {
        val values = android.content.ContentValues().apply {
            put("progress", progress)
            put("total_bytes", totalBytes)
            put("updated_at", updatedAt)
        }
        db.update("downloads", values, "task_id = ?", arrayOf(taskId))
    }

    suspend fun deleteDownload(taskId: String) = withContext(Dispatchers.IO) {
        db.delete("downloads", "task_id = ?", arrayOf(taskId))
    }

    fun getActiveDownloads(): List<DownloadEntity> {
        val cursor = db.query("downloads", null, "state = 'DOWNLOADING' OR state = 'PAUSED'", null, null, null, null)
        return cursor.use { parseDownloads(it) }
    }

    private fun parseDownloads(cursor: Cursor): List<DownloadEntity> {
        val result = mutableListOf<DownloadEntity>()
        while (cursor.moveToNext()) {
            result.add(
                DownloadEntity(
                    taskId = cursor.getString(cursor.getColumnIndexOrThrow("task_id")),
                    url = cursor.getString(cursor.getColumnIndexOrThrow("url")),
                    destinationPath = cursor.getString(cursor.getColumnIndexOrThrow("destination_path")),
                    headersJson = cursor.getString(cursor.getColumnIndexOrThrow("headers_json")),
                    state = cursor.getString(cursor.getColumnIndexOrThrow("state")),
                    progress = cursor.getLong(cursor.getColumnIndexOrThrow("progress")),
                    totalBytes = cursor.getLong(cursor.getColumnIndexOrThrow("total_bytes")),
                    contentType = cursor.getString(cursor.getColumnIndexOrThrow("content_type")),
                    saveToPublic = cursor.getInt(cursor.getColumnIndexOrThrow("save_to_public")) == 1,
                    createdAt = cursor.getLong(cursor.getColumnIndexOrThrow("created_at")),
                    updatedAt = cursor.getLong(cursor.getColumnIndexOrThrow("updated_at"))
                )
            )
        }
        return result
    }

    private fun toContentValues(entity: DownloadEntity): android.content.ContentValues {
        return android.content.ContentValues().apply {
            put("task_id", entity.taskId)
            put("url", entity.url)
            put("destination_path", entity.destinationPath)
            put("headers_json", entity.headersJson)
            put("state", entity.state)
            put("progress", entity.progress)
            put("total_bytes", entity.totalBytes)
            put("content_type", entity.contentType)
            put("save_to_public", if (entity.saveToPublic) 1 else 0)
            put("created_at", entity.createdAt)
            put("updated_at", entity.updatedAt)
        }
    }
}
