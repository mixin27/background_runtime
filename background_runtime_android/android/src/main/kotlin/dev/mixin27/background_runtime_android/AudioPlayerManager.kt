package dev.mixin27.background_runtime_android

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import dev.mixin27.background_runtime_android.database.DatabaseProvider
import dev.mixin27.background_runtime_android.database.entity.AudioTrackEntity
import io.flutter.plugin.common.EventChannel


internal object AudioPlayerManager : EventChannel.StreamHandler {

    private var player: ExoPlayer? = null
    private var currentTrack: Map<String, Any?>? = null

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
        currentTrack?.let { emitState("PLAYING") }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun emitState(state: String) {
        val track = currentTrack ?: run {
            eventSink?.success(mapOf("state" to state))
            return
        }
        val map = mutableMapOf<String, Any>("state" to state)
        track["id"]?.let { map["trackId"] = it }
        track["title"]?.let { map["title"] = it }
        track["artist"]?.let { map["artist"] = it }
        track["album"]?.let { map["album"] = it }
        track["source"]?.let { map["source"] = it }
        track["durationMillis"]?.let { map["durationMillis"] = it }
        player?.currentPosition?.let { map["positionMillis"] = it }
        eventSink?.success(map)
    }

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
        currentTrack = track

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

        emitState("PLAYING")
        BackgroundRuntimeService.updateAudioNotification(title ?: source, artist ?: "Unknown Artist", true)
    }

    suspend fun pause(context: Context) {
        player?.pause()
        val db = DatabaseProvider.getDatabase(context)
        player?.currentPosition?.let { position ->
            db.audioTrackDao.updatePosition(position)
        }
        db.audioTrackDao.updateState("PAUSED")
        emitState("PAUSED")
        BackgroundRuntimeService.removeAudioNotification()
    }

    suspend fun resume(context: Context) {
        player?.playWhenReady = true
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.updateState("PLAYING")
        emitState("PLAYING")
        val track = currentTrack
        if (track != null) {
            val title = track["title"] as? String ?: (track["source"] as? String ?: "Audio")
            val artist = track["artist"] as? String ?: "Unknown Artist"
            BackgroundRuntimeService.updateAudioNotification(title, artist, true)
        }
    }

    suspend fun stop(context: Context) {
        player?.let {
            it.stop()
            it.release()
        }
        player = null
        currentTrack = null
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.deleteCurrentTrack()
        emitState("STOPPED")
        BackgroundRuntimeService.removeAudioNotification()
    }

    fun seek(positionMillis: Long) {
        player?.seekTo(positionMillis)
    }

    suspend fun restoreState(context: Context): AudioTrackEntity? {
        val db = DatabaseProvider.getDatabase(context)
        return db.audioTrackDao.getCurrentTrack()
    }
}
