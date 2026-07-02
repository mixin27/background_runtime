package dev.mixin27.background_runtime_android

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer

internal object AudioPlayerManager {

    private var player: ExoPlayer? = null

    fun play(context: Context, track: Map<String, Any?>) {
        val source = track["source"] as? String
            ?: throw IllegalArgumentException("Source URL is required")

        stop()

        val newPlayer = ExoPlayer.Builder(context).build()
        val mediaItem = MediaItem.Builder()
            .setUri(source)
            .build()
        newPlayer.setMediaItem(mediaItem)
        newPlayer.prepare()
        newPlayer.playWhenReady = true
        player = newPlayer
    }

    fun pause() {
        player?.pause()
    }

    fun resume() {
        player?.playWhenReady = true
    }

    fun stop() {
        player?.let {
            it.stop()
            it.release()
        }
        player = null
    }

    fun seek(positionMillis: Long) {
        player?.seekTo(positionMillis)
    }
}
