package dev.mixin27.background_runtime_android

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

internal object PublicStorageResolver {

    fun resolveOutputStream(
        context: Context,
        fileName: String
    ): OutputStream? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return resolveViaMediaStore(context, fileName)
        }
        return resolveViaLegacyPublicDirectory(context, fileName)
    }

    fun deletePending(context: Context, fileName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            deleteFromMediaStore(context, fileName)
        } else {
            deleteLegacy(context, fileName)
        }
    }

    @Suppress("NewApi")
    private fun resolveViaMediaStore(context: Context, fileName: String): OutputStream? {
        val contentValues = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            ?: return null

        return resolver.openOutputStream(uri)
    }

    private fun resolveViaLegacyPublicDirectory(context: Context, fileName: String): OutputStream? {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }
        val file = File(downloadsDir, fileName)
        return FileOutputStream(file)
    }

    @Suppress("NewApi")
    private fun deleteFromMediaStore(context: Context, fileName: String) {
        val resolver = context.contentResolver
        val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(fileName)
        resolver.delete(MediaStore.Downloads.EXTERNAL_CONTENT_URI, selection, selectionArgs)
    }

    private fun deleteLegacy(context: Context, fileName: String) {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        val file = File(downloadsDir, fileName)
        if (file.exists()) {
            file.delete()
        }
    }
}
