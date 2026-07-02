package dev.mixin27.background_runtime_android.database

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import dev.mixin27.background_runtime_android.database.dao.AudioTrackDao
import dev.mixin27.background_runtime_android.database.dao.DownloadDao
import dev.mixin27.background_runtime_android.database.dao.RuntimeConfigDao

internal class AppDatabase(context: Context) : SQLiteOpenHelper(
    context.applicationContext,
    DATABASE_NAME,
    null,
    DATABASE_VERSION
) {
    val downloadDao: DownloadDao get() = DownloadDao(writableDatabase)
    val audioTrackDao: AudioTrackDao get() = AudioTrackDao(writableDatabase)
    val runtimeConfigDao: RuntimeConfigDao get() = RuntimeConfigDao(writableDatabase)

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(CREATE_DOWNLOADS)
        db.execSQL(CREATE_AUDIO_TRACK)
        db.execSQL(CREATE_RUNTIME_CONFIG)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS downloads")
        db.execSQL("DROP TABLE IF EXISTS audio_track")
        db.execSQL("DROP TABLE IF EXISTS runtime_config")
        onCreate(db)
    }

    override fun onConfigure(db: SQLiteDatabase) {
        super.onConfigure(db)
        db.setForeignKeyConstraintsEnabled(true)
    }

    companion object {
        private const val DATABASE_NAME = "background_runtime.db"
        private const val DATABASE_VERSION = 1

        private const val CREATE_DOWNLOADS = """
            CREATE TABLE IF NOT EXISTS downloads (
                task_id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                destination_path TEXT NOT NULL,
                headers_json TEXT,
                state TEXT NOT NULL,
                progress INTEGER NOT NULL DEFAULT 0,
                total_bytes INTEGER NOT NULL DEFAULT 0,
                content_type TEXT,
                save_to_public INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
        """

        private const val CREATE_AUDIO_TRACK = """
            CREATE TABLE IF NOT EXISTS audio_track (
                id TEXT PRIMARY KEY DEFAULT 'current',
                track_id TEXT,
                title TEXT,
                artist TEXT,
                album TEXT,
                source TEXT,
                duration_millis INTEGER,
                position_millis INTEGER NOT NULL DEFAULT 0,
                state TEXT NOT NULL DEFAULT 'STOPPED'
            )
        """

        private const val CREATE_RUNTIME_CONFIG = """
            CREATE TABLE IF NOT EXISTS runtime_config (
                id INTEGER PRIMARY KEY DEFAULT 1,
                enable_downloads INTEGER NOT NULL DEFAULT 1,
                enable_audio INTEGER NOT NULL DEFAULT 1,
                enable_notifications INTEGER NOT NULL DEFAULT 1,
                keep_alive INTEGER NOT NULL DEFAULT 1,
                auto_resume INTEGER NOT NULL DEFAULT 0
            )
        """
    }
}
