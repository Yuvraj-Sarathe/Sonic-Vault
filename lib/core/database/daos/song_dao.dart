import 'package:drift/drift.dart';
import '../app_database.dart';

class SongDao {
  final AppDatabase db;
  SongDao(this.db);

  Future<List<Song>> getAllSongs() => db.select(db.songs).get();

  Future<List<Song>> getSongsByArtist(String artist) =>
      (db.select(db.songs)..where((s) => s.artist.equals(artist))).get();

  Future<List<Song>> getSongsByAlbum(String album) =>
      (db.select(db.songs)..where((s) => s.album.equals(album))).get();

  Future<List<Song>> getFavoriteSongs() =>
      (db.select(db.songs)..where((s) => s.isFavorite.equals(true))).get();

  Future<List<Song>> searchSongs(String query) {
    final pattern = '%$query%';
    return (db.select(db.songs)
          ..where((s) =>
              s.title.like(pattern) |
              s.artist.like(pattern) |
              s.album.like(pattern)))
        .get();
  }

  Future<List<String>> getAllArtists() async {
    final rows = await (db.select(db.songs)
          ..orderBy([(s) => OrderingTerm.asc(s.artist)]))
        .get();
    return rows
        .map((s) => s.artist ?? 'Unknown Artist')
        .toSet()
        .toList();
  }

  Future<List<Song>> getRecentSongs({int limit = 20}) =>
      (db.select(db.songs)
            ..orderBy([(s) => OrderingTerm.desc(s.dateAdded)])
            ..limit(limit))
          .get();

  Future<List<Song>> getMostPlayedSongs({int limit = 20}) =>
      (db.select(db.songs)
            ..orderBy([(s) => OrderingTerm.desc(s.playCount)])
            ..limit(limit))
          .get();

  Future<Song?> getSongById(String id) =>
      (db.select(db.songs)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> insertSong(SongsCompanion song) =>
      db.into(db.songs).insert(song);

  Future<void> batchInsertSongs(List<SongsCompanion> songs) =>
      db.batch((batch) => batch.insertAll(db.songs, songs));

  Future<int> updateSong(SongsCompanion song) =>
      (db.update(db.songs)..where((s) => s.id.equals(song.id.value)))
          .write(song);

  Future<int> deleteSong(String id) =>
      (db.delete(db.songs)..where((s) => s.id.equals(id))).go();

  Future<void> incrementPlayCount(String id) async {
    await db.customUpdate(
      'UPDATE songs SET play_count = play_count + 1, last_played = ? WHERE id = ?',
      variables: [Variable(DateTime.now()), Variable(id)],
      updates: {db.songs},
    );
  }

  Future<void> toggleFavorite(String id) async {
    await db.customUpdate(
      'UPDATE songs SET is_favorite = NOT is_favorite WHERE id = ?',
      variables: [Variable(id)],
      updates: {db.songs},
    );
  }

  Future<int> getSongCount() =>
      db.customSelect('SELECT COUNT(*) as count FROM songs')
          .getSingle()
          .then((r) => r.read<int>('count'));

  Future<int> clearAllSongs() => db.delete(db.songs).go();
}
