import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/song_dao.dart';
import '../core/database/daos/playlist_dao.dart';

/// Riverpod providers for AppDatabase, SongDao, and PlaylistDao.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final songDaoProvider = Provider<SongDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SongDao(db);
});

final playlistDaoProvider = Provider<PlaylistDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlaylistDao(db);
});