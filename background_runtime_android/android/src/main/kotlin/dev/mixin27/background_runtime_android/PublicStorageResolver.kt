package dev.mixin27.background_runtime_android

import android.content.ContentValues
import android.content.Context
import android.net.Uri
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
    ): OutputStream {
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
    private fun resolveViaMediaStore(context: Context, fileName: String): OutputStream {
        val contentValues = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.IS_PENDING, 1)
            val mime = guessMimeType(fileName)
            if (mime != null) {
                put(MediaStore.Downloads.MIME_TYPE, mime)
            }
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            ?: throw RuntimeException("Failed to create MediaStore entry for $fileName")

        val stream = resolver.openOutputStream(uri)
            ?: throw RuntimeException("Failed to open output stream for $fileName")

        return MediaStoreOutputStream(context, uri, stream)
    }

    private fun resolveViaLegacyPublicDirectory(context: Context, fileName: String): OutputStream {
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

    private fun guessMimeType(fileName: String): String? {
        val ext = fileName.substringAfterLast('.', "").lowercase()
        return when (ext) {
            "mp4" -> "video/mp4"
            "mp3" -> "audio/mpeg"
            "zip" -> "application/zip"
            "pdf" -> "application/pdf"
            "png" -> "image/png"
            "jpg", "jpeg" -> "image/jpeg"
            "gif" -> "image/gif"
            "txt" -> "text/plain"
            "html", "htm" -> "text/html"
            "json" -> "application/json"
            "xml" -> "application/xml"
            "apk" -> "application/vnd.android.package-archive"
            else -> null
        }
    }

    @Suppress("NewApi")
    private class MediaStoreOutputStream(
        private val context: Context,
        private val uri: Uri,
        private val delegate: OutputStream
    ) : OutputStream() {

        override fun write(b: Int) = delegate.write(b)

        override fun write(b: ByteArray) = delegate.write(b)

        override fun write(b: ByteArray, off: Int, len: Int) = delegate.write(b, off, len)

        override fun flush() = delegate.flush()

        override fun close() {
            try {
                delegate.close()
            } finally {
                clearPendingFlag()
            }
        }

        private fun clearPendingFlag() {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            context.contentResolver.update(uri, values, null, null)
        }
    }
}