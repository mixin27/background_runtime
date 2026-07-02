package dev.mixin27.background_runtime_android

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import dev.mixin27.background_runtime_android.database.DatabaseProvider
import dev.mixin27.background_runtime_android.database.entity.AudioTrackEntity
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch


internal object AudioPlayerManager : EventChannel.StreamHandler {

    private var player: ExoPlayer? = null
    private var currentTrack: Map<String, Any?>? = null

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var notificationJob: Job? = null

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

    private fun startProgressUpdates(context: Context) {
        notificationJob?.cancel()
        notificationJob = scope.launch {
            while (isActive) {
                val p = player
                val track = currentTrack
                if (p != null && track != null) {
                    val title = track["title"] as? String ?: (track["source"] as? String ?: "Audio")
                    val artist = track["artist"] as? String ?: "Unknown Artist"
                    BackgroundRuntimeService.updateAudioNotification(
                        title = title,
                        artist = artist,
                        isPlaying = true,
                        positionMillis = p.currentPosition,
                        durationMillis = p.duration.coerceAtLeast(0)
                    )
                }
                delay(1000L)
            }
        }
    }

    private fun stopProgressUpdates() {
        notificationJob?.cancel()
        notificationJob = null
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
        BackgroundRuntimeService.updateAudioNotification(
            title = title ?: source,
            artist = artist ?: "Unknown Artist",
            isPlaying = true
        )
        startProgressUpdates(context)
    }

    suspend fun pause(context: Context) {
        if (player == null && currentTrack == null) return
        player?.pause()
        val db = DatabaseProvider.getDatabase(context)
        player?.currentPosition?.let { position ->
            db.audioTrackDao.updatePosition(position)
        }
        db.audioTrackDao.updateState("PAUSED")
        emitState("PAUSED")
        stopProgressUpdates()
        val track = currentTrack
        if (track != null) {
            val p = player
            BackgroundRuntimeService.updateAudioNotification(
                title = track["title"] as? String ?: (track["source"] as? String ?: "Audio"),
                artist = track["artist"] as? String ?: "Unknown Artist",
                isPlaying = false,
                positionMillis = p?.currentPosition ?: 0,
                durationMillis = p?.duration?.coerceAtLeast(0) ?: 0
            )
        }
    }

    suspend fun resume(context: Context) {
        if (player == null) return
        player?.playWhenReady = true
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.updateState("PLAYING")
        emitState("PLAYING")
        val track = currentTrack
        if (track != null) {
            val title = track["title"] as? String ?: (track["source"] as? String ?: "Audio")
            val artist = track["artist"] as? String ?: "Unknown Artist"
            BackgroundRuntimeService.updateAudioNotification(title, artist, isPlaying = true)
        }
        startProgressUpdates(context)
    }

    suspend fun stop(context: Context) {
        if (player == null && currentTrack == null) return
        player?.let {
            it.stop()
            it.release()
        }
        player = null
        currentTrack = null
        val db = DatabaseProvider.getDatabase(context)
        db.audioTrackDao.deleteCurrentTrack()
        emitState("STOPPED")
        stopProgressUpdates()
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
