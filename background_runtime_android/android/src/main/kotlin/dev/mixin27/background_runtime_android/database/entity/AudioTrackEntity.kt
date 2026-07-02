package dev.mixin27.background_runtime_android.database.entity

data class AudioTrackEntity(
    val id: String = "current",
    val trackId: String? = null,
    val title: String? = null,
    val artist: String? = null,
    val album: String? = null,
    val source: String? = null,
    val durationMillis: Long? = null,
    val positionMillis: Long = 0L,
    val state: String = "STOPPED"
)
