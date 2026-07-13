import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import 'file_utils.dart';
import 'cover_art_helper.dart';

class MetadataReader {
  /// Extract metadata from an audio file. If [songId] is provided and the file
  /// has embedded cover art, it is saved to the app's covers directory and the
  /// path is returned in `coverArtPath`.
  static Future<Map<String, dynamic>> extractMetadata(
    String filePath, {
    String? songId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return {'error': 'File not found'};
    }

    final stat = await file.stat();
    final fileName = FileUtils.getFileName(filePath);
    final ext = FileUtils.getFileExtension(filePath);

    try {
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

      // Save embedded cover art to the app's covers directory if songId provided
      String? coverArtPath;
      if (hasCoverArt && songId != null) {
        final picture = metadata.pictures.first;
        coverArtPath = await CoverArtHelper.saveCoverImage(songId, picture.bytes);
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
        'fileSize': stat.size,
        'fileFormat': ext.replaceAll('.', ''),
        'coverArtPath': null,
      };
    }
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
