import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import 'database_providers.dart';

/// Riverpod FutureProviders for playlist queries backed by PlaylistDao.

final allPlaylistsProvider = FutureProvider<List<Playlist>>((ref) {
  final dao = ref.watch(playlistDaoProvider);
  return dao.getAllPlaylists();
});

final playlistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, playlistId) {
  final dao = ref.watch(playlistDaoProvider);
  return dao.getPlaylistSongs(playlistId);
});

final playlistCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(playlistDaoProvider);
  return dao.getPlaylistCount();
});