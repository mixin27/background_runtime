package dev.mixin27.background_runtime_android.database

import android.content.Context

internal object DatabaseProvider {
    @Volatile
    private var database: AppDatabase? = null

    fun getDatabase(context: Context): AppDatabase {
        return database ?: synchronized(this) {
            database ?: AppDatabase(context).also { database = it }
        }
    }
}
