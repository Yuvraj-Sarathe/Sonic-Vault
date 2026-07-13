import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import 'database_providers.dart';

/// Riverpod FutureProviders for song queries backed by SongDao.

final allSongsProvider = FutureProvider<List<Song>>((ref) {
  final dao = ref.watch(songDaoProvider);
  return dao.getAllSongs();
});

final recentSongsProvider = FutureProvider<List<Song>>((ref) {
  final dao = ref.watch(songDaoProvider);
  return dao.getRecentSongs(limit: 50);
});

final favoriteSongsProvider = FutureProvider<List<Song>>((ref) {
  final dao = ref.watch(songDaoProvider);
  return dao.getFavoriteSongs();
});

final songSearchProvider =
    FutureProvider.family<List<Song>, String>((ref, query) {
  final dao = ref.watch(songDaoProvider);
  return dao.searchSongs(query);
});

final songsByArtistProvider =
    FutureProvider.family<List<Song>, String>((ref, artist) {
  final dao = ref.watch(songDaoProvider);
  return dao.getSongsByArtist(artist);
});

final songsByAlbumProvider =
    FutureProvider.family<List<Song>, String>((ref, album) {
  final dao = ref.watch(songDaoProvider);
  return dao.getSongsByAlbum(album);
});

final allArtistsProvider = FutureProvider<List<String>>((ref) {
  final dao = ref.watch(songDaoProvider);
  return dao.getAllArtists();
});

final songCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(songDaoProvider);
  return dao.getSongCount();
});