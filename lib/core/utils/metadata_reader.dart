import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../core/database/app_database.dart';
import 'file_utils.dart';
import 'cover_art_helper.dart';

class MetadataReader {
  static const _channel = MethodChannel('com.sonicvault/scanner');

  /// Extract metadata from an audio file or content URI.
  ///
  /// For Android content:// URIs, delegates to Kotlin's
  /// [MediaMetadataRetriever] via method channel — this avoids dart:io
  /// restrictions on scoped storage.
  ///
  /// For regular file paths (desktop), uses [audio_metadata_reader].
  ///
  /// If [songId] is provided and the file has embedded cover art, it is saved
  /// to the app's covers directory and the path is returned in `coverArtPath`.
  static Future<Map<String, dynamic>> extractMetadata(
    String filePath, {
    String? songId,
  }) async {
    final isContentUri = filePath.startsWith('content://');

    final fileName = isContentUri
        ? _getFileNameFromUri(filePath)
        : FileUtils.getFileName(filePath);
    final ext = isContentUri
        ? _getExtensionFromUri(filePath)
        : FileUtils.getFileExtension(filePath);

    if (isContentUri) {
      return _extractMetadataFromContentUri(
        filePath,
        fileName: fileName,
        ext: ext,
        songId: songId,
      );
    }

    // Desktop / regular file path: use audio_metadata_reader
    try {
      final file = File(filePath);
      final exists = await file.exists();
      if (!exists) {
        return _basicMetadata(filePath, fileName, ext, 0);
      }

      final stat = await file.stat();
      final metadata = readMetadata(file);

      final title =
          metadata.title ?? FileUtils.getFileNameWithoutExtension(filePath);
      final artist = metadata.artist;
      final album = metadata.album;
      final albumArtist = metadata.artist;
      final duration = metadata.duration?.inMilliseconds ?? 0;
      final trackNumber = metadata.trackNumber;
      final discNumber = metadata.discNumber;
      final year = metadata.year?.year;
      final genres =
          metadata.genres.isNotEmpty ? metadata.genres.join(', ') : null;
      final bitrate = metadata.bitrate;
      final sampleRate = metadata.sampleRate;
      final hasCoverArt = metadata.pictures.isNotEmpty;

      // Save embedded cover art
      String? coverArtPath;
      if (hasCoverArt && songId != null) {
        final picture = metadata.pictures.first;
        coverArtPath =
            await CoverArtHelper.saveCoverImage(songId, picture.bytes);
      }

      return {
        'title': title,
        'artist': artist,
        'album': album,
        'albumArtist': albumArtist,
        'durationMs': duration > 0 ? duration : 0,
        'trackNumber': trackNumber,
        'discNumber': discNumber,
        'year': year,
        'genre': genres,
        'bitrate': bitrate,
        'sampleRate': sampleRate,
        'hasCoverArt': hasCoverArt,
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': stat.size,
        'fileFormat': ext.replaceAll('.', ''),
        'coverArtPath': coverArtPath,
      };
    } catch (e) {
      return _basicMetadata(filePath, fileName, ext, 0);
    }
  }

  /// Extract metadata from a content:// URI via Kotlin's MediaMetadataRetriever.
  static Future<Map<String, dynamic>> _extractMetadataFromContentUri(
    String filePath, {
    required String fileName,
    required String ext,
    String? songId,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'extractMetadata',
        {'uri': filePath, 'songId': songId},
      );

      if (result == null) {
        return _basicMetadata(filePath, fileName, ext, 0);
      }

      final map = Map<String, dynamic>.from(result);

      // Save cover art from raw bytes (MethodChannel delivers byte[] as Uint8List)
      String? coverArtPath;
      if (map['hasCoverArt'] == true &&
          map['coverBytes'] is Uint8List &&
          (map['coverBytes'] as Uint8List).isNotEmpty) {
        try {
          final bytes = map['coverBytes'] as Uint8List;
          if (songId != null) {
            coverArtPath =
                await CoverArtHelper.saveCoverImage(songId, bytes);
          }
        } catch (_) {
          // Cover art save failure is non-fatal
        }
      }

      return {
        'title': map['title'] as String? ?? fileName,
        'artist': map['artist'] as String?,
        'album': map['album'] as String?,
        'albumArtist': map['albumArtist'] as String?,
        'durationMs': (map['durationMs'] as num?)?.toInt() ?? 0,
        'trackNumber': map['trackNumber'] as int?,
        'discNumber': map['discNumber'] as int?,
        'year': map['year'] as int?,
        'genre': map['genre'] as String?,
        'bitrate': map['bitrate'] as int?,
        'sampleRate': map['sampleRate'] as int?,
        'hasCoverArt': map['hasCoverArt'] == true,
        'filePath': filePath,
        'fileName': map['fileName'] as String? ?? fileName,
        'fileSize': 0,
        'fileFormat': map['fileFormat'] as String? ?? ext.replaceAll('.', ''),
        'coverArtPath': coverArtPath,
      };
    } catch (e) {
      return _basicMetadata(filePath, fileName, ext, 0);
    }
  }

  /// Returns a minimal metadata map for files that could not be fully read.
  /// This ensures scoped-storage files are not silently dropped from scans.
  static Map<String, dynamic> _basicMetadata(
      String filePath, String fileName, String ext, int fileSize) {
    return {
      'title': FileUtils.getFileNameWithoutExtension(filePath),
      'artist': null,
      'album': null,
      'albumArtist': null,
      'durationMs': 0,
      'trackNumber': null,
      'discNumber': null,
      'year': null,
      'genre': null,
      'bitrate': null,
      'sampleRate': null,
      'hasCoverArt': false,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileFormat': ext.replaceAll('.', ''),
      'coverArtPath': null,
    };
  }

  /// Extract filename from a content:// URI last path segment.
  static String _getFileNameFromUri(String uri) {
    final decoded = Uri.decodeComponent(Uri.parse(uri).pathSegments.last);
    return decoded.split('/').last;
  }

  /// Extract file extension from a content:// URI filename.
  static String _getExtensionFromUri(String uri) {
    final name = _getFileNameFromUri(uri);
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot).toLowerCase() : '';
  }

  static SongsCompanion metadataToSong(
      Map<String, dynamic> metadata, String id) {
    return SongsCompanion(
      id: Value(id),
      title: Value(metadata['title'] as String),
      artist: Value(metadata['artist'] as String?),
      album: Value(metadata['album'] as String?),
      albumArtist: Value(metadata['albumArtist'] as String?),
      trackNumber: Value(metadata['trackNumber'] as int?),
      discNumber: Value(metadata['discNumber'] as int?),
      year: Value(metadata['year'] as int?),
      genre: Value(metadata['genre'] as String?),
      durationMs: Value(metadata['durationMs'] as int),
      bitrate: Value(metadata['bitrate'] as int?),
      sampleRate: Value(metadata['sampleRate'] as int?),
      filePath: Value(metadata['filePath'] as String),
      fileName: Value(metadata['fileName'] as String),
      fileSize: Value(metadata['fileSize'] as int),
      fileFormat: Value(metadata['fileFormat'] as String),
      hasCoverArt: Value(metadata['hasCoverArt'] as bool),
      coverArtPath: Value(metadata['coverArtPath'] as String?),
      dateAdded: Value(DateTime.now()),
      dateModified: Value(DateTime.now()),
      playCount: const Value(0),
      lastPlayed: const Value(null),
      isFavorite: const Value(false),
    );
  }
}
