package com.example.sonicvault

import android.content.ContentUris
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sonicvault/scanner"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanMusic") {
                    try {
                        val paths = scanMusicFiles()
                        result.success(paths)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Storage permission not granted", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun scanMusicFiles(): List<String> {
        val paths = mutableListOf<String>()

        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DISPLAY_NAME
        )

        // No SQL selection filter — rely on extension check in the loop.
        // The DATA column is deprecated on API 29+, so we handle null
        // by constructing content URIs from _ID.
        val selection: String? = null
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, selection, null, sortOrder)
            cursor?.use { c ->
                val dataIndex = c.getColumnIndex(MediaStore.Audio.Media.DATA)
                val idIndex = c.getColumnIndex(MediaStore.Audio.Media._ID)
                val nameIndex = c.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                while (c.moveToNext()) {
                    // Use the file path if available; otherwise construct a content URI from _ID
                    val path = c.getString(dataIndex)
                    val fileRef: String
                    val checkName: String
                    if (path != null) {
                        fileRef = path
                        checkName = path
                    } else if (idIndex >= 0) {
                        val id = c.getLong(idIndex)
                        fileRef = ContentUris.withAppendedId(uri, id).toString()
                        checkName = c.getString(nameIndex) ?: "unknown"
                    } else {
                        continue
                    }
                    // Only add standard audio extensions to filter out ringtones, notifications, etc.
                    val lower = checkName.lowercase()
                    if (lower.endsWith(".mp3") || lower.endsWith(".flac") ||
                        lower.endsWith(".wav") || lower.endsWith(".ogg") ||
                        lower.endsWith(".aac") || lower.endsWith(".m4a") ||
                        lower.endsWith(".opus") || lower.endsWith(".wma")) {
                        paths.add(fileRef)
                    }
                }
            }
        } catch (e: SecurityException) {
            throw e  // Propagate to method channel handler for proper error reporting
        } catch (e: Exception) {
            // Return whatever we have for non-security errors
        }

        return paths
    }
}
