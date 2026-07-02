package dev.mixin27.background_runtime_android.database.dao

import android.database.Cursor
import dev.mixin27.background_runtime_android.database.entity.RuntimeConfigEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal class RuntimeConfigDao(private val db: android.database.sqlite.SQLiteDatabase) {

    suspend fun getConfig(): RuntimeConfigEntity? = withContext(Dispatchers.IO) {
        val cursor = db.query("runtime_config", null, "id = 1", null, null, null, null)
        cursor.use { parseConfigs(it).firstOrNull() }
    }

    suspend fun upsertConfig(config: RuntimeConfigEntity) = withContext(Dispatchers.IO) {
        val values = toContentValues(config)
        db.insertWithOnConflict("runtime_config", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
    }

    suspend fun deleteConfig() = withContext(Dispatchers.IO) {
        db.delete("runtime_config", "id = 1", null)
    }

    private fun parseConfigs(cursor: Cursor): List<RuntimeConfigEntity> {
        val result = mutableListOf<RuntimeConfigEntity>()
        while (cursor.moveToNext()) {
            result.add(
                RuntimeConfigEntity(
                    id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                    enableDownloads = cursor.getInt(cursor.getColumnIndexOrThrow("enable_downloads")) == 1,
                    enableAudio = cursor.getInt(cursor.getColumnIndexOrThrow("enable_audio")) == 1,
                    enableNotifications = cursor.getInt(cursor.getColumnIndexOrThrow("enable_notifications")) == 1,
                    keepAlive = cursor.getInt(cursor.getColumnIndexOrThrow("keep_alive")) == 1,
                    autoResume = cursor.getInt(cursor.getColumnIndexOrThrow("auto_resume")) == 1
                )
            )
        }
        return result
    }

    private fun toContentValues(entity: RuntimeConfigEntity): android.content.ContentValues {
        return android.content.ContentValues().apply {
            put("id", entity.id)
            put("enable_downloads", if (entity.enableDownloads) 1 else 0)
            put("enable_audio", if (entity.enableAudio) 1 else 0)
            put("enable_notifications", if (entity.enableNotifications) 1 else 0)
            put("keep_alive", if (entity.keepAlive) 1 else 0)
            put("auto_resume", if (entity.autoResume) 1 else 0)
        }
    }
}
