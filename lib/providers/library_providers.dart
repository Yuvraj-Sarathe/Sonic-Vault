import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/utils/file_utils.dart';
import '../core/utils/media_scanner.dart';
import '../core/utils/metadata_reader.dart';
import 'database_providers.dart';
import 'song_providers.dart';

/// Represents the current state of a library scan operation.
class LibraryScanState {
  final bool isScanning;
  final String? error;
  final int scannedFiles;
  final int totalFiles;

  const LibraryScanState({
    this.isScanning = false,
    this.error,
    this.scannedFiles = 0,
    this.totalFiles = 0,
  });

  const LibraryScanState.idle() : this();

  LibraryScanState copyWith({
    bool? isScanning,
    String? error,
    int? scannedFiles,
    int? totalFiles,
  }) {
    return LibraryScanState(
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
    );
  }
}

/// StateNotifier managing the library scan flow.
/// Tracks scanning progress and handles the full pipeline:
/// pick folder → scan directory → extract metadata → batch insert → invalidate providers.
class LibraryScanNotifier extends StateNotifier<LibraryScanState> {
  final Ref _ref;

  LibraryScanNotifier(this._ref) : super(const LibraryScanState.idle());

  static const int _batchSize = 50;

  /// Scan a folder at [dirPath] for audio files.
  /// Updates state through loading/progress/error phases.
  Future<void> scanFolder(String dirPath) async {
    if (state.isScanning) return; // WR-01: guard against concurrent scans
    state = state.copyWith(isScanning: true, error: null);

    try {
      // 1. Scan directory for audio files (uses platform-specific API)
      final audioFiles = await MediaScanner.scanAudioFiles(dirPath);
      final total = audioFiles.length;

      if (total == 0) {
        state = state.copyWith(
          isScanning: false,
          error: 'No audio files found in the selected folder.',
        );
        return;
      }

      state = state.copyWith(totalFiles: total);

      // 2-4. Extract metadata and build companions
      final companions = <SongsCompanion>[];
      for (int i = 0; i < audioFiles.length; i++) {
        final file = audioFiles[i];
        try {
          final id = FileUtils.generateFileId(file.path);
          final metadata = await MetadataReader.extractMetadata(
            file.path,
            songId: id,
          );
          companions.add(MetadataReader.metadataToSong(metadata, id));
        } catch (e) {
          // Skip individual files that fail metadata extraction (T-02-02 mitigation)
          continue;
        }
        // Update progress every 10 files
        if ((i + 1) % 10 == 0 || i == audioFiles.length - 1) {
          state = state.copyWith(scannedFiles: i + 1);
        }
      }

      if (companions.isEmpty) {
        state = state.copyWith(
          isScanning: false,
          error: 'Could not read metadata from any audio files.',
        );
        return;
      }

      // 5. Batch insert in groups of 50 to avoid memory pressure (T-02-04 mitigation)
      final dao = _ref.read(songDaoProvider);
      for (int i = 0; i < companions.length; i += _batchSize) {
        final end = (i + _batchSize) < companions.length
            ? i + _batchSize
            : companions.length;
        await dao.batchInsertSongs(companions.sublist(i, end));
      }

      // 6. Invalidate providers to refresh UI
      _ref.invalidate(allSongsProvider);
      _ref.invalidate(songCountProvider);

      state = state.copyWith(isScanning: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scan failed: ${e.toString()}',
      );
    }
  }

  /// Reset the scan state back to idle.
  void reset() {
    state = const LibraryScanState.idle();
  }
}

final libraryScanProvider =
    StateNotifierProvider<LibraryScanNotifier, LibraryScanState>((ref) {
  return LibraryScanNotifier(ref);
});
