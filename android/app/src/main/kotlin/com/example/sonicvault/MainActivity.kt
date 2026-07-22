package com.example.sonicvault

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val REQUEST_CODE_FOLDER_PICKER = 0x1001

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sonicvault/scanner"
    private var pendingFolderResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "pickFolder" -> {
                            // Launch native SAF folder picker
                            // Returns raw content:// tree URI (not a filesystem path)
                            pendingFolderResult = result
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                                )
                            }
                            startActivityForResult(intent, REQUEST_CODE_FOLDER_PICKER)
                        }
                        "scanMusic" -> {
                            result.success(scanMusicFiles())
                        }
                        "takePersistableUriPermission" -> {
                            val uriString = call.argument<String>("uri") ?: return@setMethodCallHandler
                            takePersistableUriPermission(uriString)
                            result.success(true)
                        }
                        "scanFolder" -> {
                            val treeUri = call.argument<String>("treeUri")
                            if (treeUri != null) {
                                result.success(scanFolderWithSAF(treeUri))
                            } else {
                                result.error("INVALID_ARGUMENTS", "treeUri is required", null)
                            }
                        }
                        "extractMetadata" -> {
                            val uri = call.argument<String>("uri")
                            val songId = call.argument<String>("songId")
                            if (uri != null) {
                                result.success(extractMetadataWithRetriever(uri, songId))
                            } else {
                                result.error("INVALID_ARGUMENTS", "uri is required", null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("PERMISSION_DENIED", e.message, null)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_FOLDER_PICKER) {
            pendingFolderResult?.let { pending ->
                pendingFolderResult = null
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val treeUri = data.data.toString()
                    // Persist permission so it survives app restarts
                    takePersistableUriPermission(treeUri)
                    pending.success(treeUri)
                } else {
                    pending.success(null) // User cancelled
                }
            }
        }
    }

    // ──────────────────────────────────────────────
    // Persistable URI permission (SAF tree picker)
    // ──────────────────────────────────────────────
    private fun takePersistableUriPermission(uriString: String) {
        val uri = Uri.parse(uriString)
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {
            // Permission may already be held or not available — not fatal
        }
    }

    // ──────────────────────────────────────────────
    // SAF DocumentFile tree walker (no androidx dependency)
    // ──────────────────────────────────────────────
    private fun scanFolderWithSAF(treeUriString: String): List<String> {
        val treeUri = Uri.parse(treeUriString)
        val audioFiles = mutableListOf<String>()
        walkDocumentTree(this, treeUri, treeUri, audioFiles)
        return audioFiles
    }

    private fun walkDocumentTree(
        context: Context,
        treeUri: Uri,
        currentUri: Uri,
        results: MutableList<String>
    ) {
        // treeUri is always the original SAF tree URI (required by
        // buildChildDocumentsUriUsingTree / buildDocumentUriUsingTree).
        // currentUri is the URI of the directory we're walking right now
        // (used to extract its document ID via getDocumentId).
        val docId: String = try {
            DocumentsContract.getTreeDocumentId(treeUri)
        } catch (_: Exception) {
            DocumentsContract.getDocumentId(currentUri)
        }
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, docId)

        var cursor: Cursor? = null
        try {
            cursor = context.contentResolver.query(
                childrenUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME
                ),
                null, null, null
            )
        } catch (_: SecurityException) {
            return  // Skip directories we can't read
        }

        cursor?.use { c ->
            val idIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val mimeIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val nameIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            if (idIdx < 0) return

            while (c.moveToNext()) {
                val docId = c.getString(idIdx) ?: continue
                val mimeType = c.getString(mimeIdx)
                val name = c.getString(nameIdx) ?: continue
                val lowerName = name.lowercase()

                if (DocumentsContract.Document.MIME_TYPE_DIR == mimeType) {
                    val childUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    walkDocumentTree(context, treeUri, childUri, results)
                } else if (mimeType?.startsWith("audio/") == true ||
                    lowerName.endsWith(".mp3") || lowerName.endsWith(".flac") ||
                    lowerName.endsWith(".wav") || lowerName.endsWith(".ogg") ||
                    lowerName.endsWith(".aac") || lowerName.endsWith(".m4a") ||
                    lowerName.endsWith(".opus") || lowerName.endsWith(".wma")
                ) {
                    val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    results.add(fileUri.toString())
                }
            }
        }
    }

    // ──────────────────────────────────────────────
    // Native metadata extraction via MediaMetadataRetriever
    // Uses openFileDescriptor for maximum content URI compatibility
    // ──────────────────────────────────────────────
    private fun extractMetadataWithRetriever(
        uriString: String,
        songId: String?
    ): Map<String, Any?> {
        val uri = Uri.parse(uriString)
        val retriever = MediaMetadataRetriever()
        try {
            // Open a file descriptor directly from the content resolver.
            // This is more reliable than setDataSource(Context, Uri) on
            // certain Android versions and content provider implementations.
            context.contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                retriever.setDataSource(pfd.fileDescriptor)
            } ?: return fallbackMetadata(uri)

            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
            val albumArtist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST)
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val trackStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER)
            val discStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DISC_NUMBER)
            val yearStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_YEAR)
            val genre = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE)
            val bitrateStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
            val sampleRateStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_SAMPLERATE)

            val fileName = uri.lastPathSegment ?: "unknown"
            val ext = fileName.substringAfterLast(".", "")

            // Embedded cover art — return raw bytes natively.
            // MethodChannel handles byte[] ↔ Uint8List automatically.
            var coverBytes: ByteArray? = null
            var hasCoverArt = false
            try {
                val pictureBytes = retriever.embeddedPicture
                if (pictureBytes != null && pictureBytes.isNotEmpty()) {
                    hasCoverArt = true
                    coverBytes = pictureBytes
                }
            } catch (_: Exception) {
                // Some files don't support embedded picture extraction
            }

            return mapOf(
                "title" to (title ?: fileName.substringBeforeLast(".")),
                "artist" to artist,
                "album" to album,
                "albumArtist" to albumArtist,
                "durationMs" to (durationStr?.toLongOrNull() ?: 0L),
                "trackNumber" to trackStr?.toIntOrNull(),
                "discNumber" to discStr?.toIntOrNull(),
                "year" to yearStr?.toIntOrNull(),
                "genre" to genre,
                "bitrate" to bitrateStr?.toIntOrNull(),
                "sampleRate" to sampleRateStr?.toIntOrNull(),
                "hasCoverArt" to hasCoverArt,
                "coverBytes" to coverBytes,  // raw ByteArray → Uint8List in Dart
                "filePath" to uriString,
                "fileName" to fileName,
                "fileFormat" to ext,
            )
        } catch (_: Exception) {
            return fallbackMetadata(uri)
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {}
        }
    }

    private fun fallbackMetadata(uri: Uri): Map<String, Any?> {
        val fileName = uri.lastPathSegment ?: "unknown"
        val ext = fileName.substringAfterLast(".", "")
        return mapOf(
            "title" to fileName.substringBeforeLast("."),
            "artist" to null,
            "album" to null,
            "albumArtist" to null,
            "durationMs" to 0L,
            "trackNumber" to null,
            "discNumber" to null,
            "year" to null,
            "genre" to null,
            "bitrate" to null,
            "sampleRate" to null,
            "hasCoverArt" to false,
            "coverBytes" to null,
            "filePath" to uri.toString(),
            "fileName" to fileName,
            "fileFormat" to ext,
        )
    }

    // ──────────────────────────────────────────────
    // Legacy MediaStore scanner (retained as fallback)
    // ──────────────────────────────────────────────
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
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, null, null, sortOrder)
            cursor?.use { c ->
                val dataIndex = c.getColumnIndex(MediaStore.Audio.Media.DATA)
                val idIndex = c.getColumnIndex(MediaStore.Audio.Media._ID)
                val nameIndex = c.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                while (c.moveToNext()) {
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
                    val lower = checkName.lowercase()
                    if (lower.endsWith(".mp3") || lower.endsWith(".flac") ||
                        lower.endsWith(".wav") || lower.endsWith(".ogg") ||
                        lower.endsWith(".aac") || lower.endsWith(".m4a") ||
                        lower.endsWith(".opus") || lower.endsWith(".wma")
                    ) {
                        paths.add(fileRef)
                    }
                }
            }
        } catch (_: SecurityException) {
            throw SecurityException("Storage permission not granted")
        } catch (_: Exception) {
            // Non-security errors → return partial results
        }

        return paths
    }
}
