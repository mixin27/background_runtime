package dev.mixin27.background_runtime_android.database.dao

import android.database.Cursor
import dev.mixin27.background_runtime_android.database.entity.AudioTrackEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal class AudioTrackDao(private val db: android.database.sqlite.SQLiteDatabase) {

    suspend fun getCurrentTrack(): AudioTrackEntity? = withContext(Dispatchers.IO) {
        val cursor = db.query("audio_track", null, "id = 'current'", null, null, null, null)
        cursor.use { parseTracks(it).firstOrNull() }
    }

    suspend fun upsertTrack(track: AudioTrackEntity) = withContext(Dispatchers.IO) {
        val values = toContentValues(track)
        db.insertWithOnConflict("audio_track", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
    }

    suspend fun updatePosition(positionMillis: Long) = withContext(Dispatchers.IO) {
        val values = android.content.ContentValues().apply {
            put("position_millis", positionMillis)
        }
        db.update("audio_track", values, "id = 'current'", null)
    }

    suspend fun updateState(state: String) = withContext(Dispatchers.IO) {
        val values = android.content.ContentValues().apply {
            put("state", state)
        }
        db.update("audio_track", values, "id = 'current'", null)
    }

    suspend fun deleteCurrentTrack() = withContext(Dispatchers.IO) {
        db.delete("audio_track", "id = 'current'", null)
    }

    private fun parseTracks(cursor: Cursor): List<AudioTrackEntity> {
        val result = mutableListOf<AudioTrackEntity>()
        while (cursor.moveToNext()) {
            result.add(
                AudioTrackEntity(
                    id = cursor.getString(cursor.getColumnIndexOrThrow("id")),
                    trackId = cursor.getString(cursor.getColumnIndexOrThrow("track_id")),
                    title = cursor.getString(cursor.getColumnIndexOrThrow("title")),
                    artist = cursor.getString(cursor.getColumnIndexOrThrow("artist")),
                    album = cursor.getString(cursor.getColumnIndexOrThrow("album")),
                    source = cursor.getString(cursor.getColumnIndexOrThrow("source")),
                    durationMillis = if (cursor.isNull(cursor.getColumnIndexOrThrow("duration_millis"))) null else cursor.getLong(cursor.getColumnIndexOrThrow("duration_millis")),
                    positionMillis = cursor.getLong(cursor.getColumnIndexOrThrow("position_millis")),
                    state = cursor.getString(cursor.getColumnIndexOrThrow("state"))
                )
            )
        }
        return result
    }

    private fun toContentValues(entity: AudioTrackEntity): android.content.ContentValues {
        return android.content.ContentValues().apply {
            put("id", entity.id)
            put("track_id", entity.trackId)
            put("title", entity.title)
            put("artist", entity.artist)
            put("album", entity.album)
            put("source", entity.source)
            put("duration_millis", entity.durationMillis)
            put("position_millis", entity.positionMillis)
            put("state", entity.state)
        }
    }
}
