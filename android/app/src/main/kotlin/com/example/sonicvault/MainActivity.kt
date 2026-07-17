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
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sonicvault/scanner"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanMusic") {
                    val paths = scanMusicFiles()
                    result.success(paths)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun scanMusicFiles(): List<String> {
        val paths = mutableListOf<String>()

        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA
        )

        // Only audio files that are actually present on disk
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} = 1 AND ${MediaStore.Audio.Media.DATA} IS NOT NULL"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, selection, null, sortOrder)
            cursor?.use { c ->
                val dataIndex = c.getColumnIndex(MediaStore.Audio.Media.DATA)
                while (c.moveToNext()) {
                    val path = c.getString(dataIndex)
                    if (path != null && File(path).exists()) {
                        // Only add standard audio extensions to filter out ringtones, notifications, etc.
                        val lower = path.lowercase()
                        if (lower.endsWith(".mp3") || lower.endsWith(".flac") ||
                            lower.endsWith(".wav") || lower.endsWith(".ogg") ||
                            lower.endsWith(".aac") || lower.endsWith(".m4a") ||
                            lower.endsWith(".opus") || lower.endsWith(".wma")) {
                            paths.add(path)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Return whatever we have
        }

        return paths
    }
}
