package dev.mixin27.background_runtime_android

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import dev.mixin27.background_runtime_android.database.DatabaseProvider
import dev.mixin27.background_runtime_android.database.entity.AudioTrackEntity

internal object AudioPlayerManager {

    private var player: ExoPlayer? = null

    suspend fun play(context: Context, track: Map<String, Any?>) {
        val source = track["source"] as? String
            ?: throw IllegalArgumentException("Source URL is required")
        val trackId = track["id"] as? String
        val title = track["title"] as? String
        val artist = track["artist"] as? String?
        val album = track["album"] as? String?
        val durationMillis = track["durationMillis"] as? Long?

        stop(context)

        val newPlayer = ExoPlayer.Builder(context).build()
        val mediaItem = MediaItem.Builder()
            .setUri(source)
            .build()
        newPlayer.setMediaItem(mediaItem)
        newPlayer.prepare()
        newPlayer.playWhenReady = true
        player = newPlayer

        val entity = AudioTrackEntity(
            trackId = trackId,
            title = title,
            artist = artist,
            album = album,
            source = source,
            durationMillis = durationMillis,
            state = "PLAYING"
        )
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.upsertTrack(entity)
    }

    suspend fun pause(context: Context) {
        player?.pause()
        val db = DatabaseProvider.getDatabase(context)
        player?.currentPosition?.let { position ->
            db.audioTrackDao.updatePosition(position)
        }
        db.audioTrackDao.updateState("PAUSED")
    }

    suspend fun resume(context: Context) {
        player?.playWhenReady = true
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.updateState("PLAYING")
    }

    suspend fun stop(context: Context) {
        player?.let {
            it.stop()
            it.release()
        }
        player = null
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.deleteCurrentTrack()
    }

    fun seek(positionMillis: Long) {
        player?.seekTo(positionMillis)
    }

    suspend fun restoreState(context: Context): AudioTrackEntity? {
        val db = DatabaseProvider.getDatabase(context)
        return db.audioTrackDao.getCurrentTrack()
    }
}
