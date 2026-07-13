import 'package:drift/drift.dart';
import '../app_database.dart';

class PlaylistDao {
  final AppDatabase db;
  PlaylistDao(this.db);

  Future<List<Playlist>> getAllPlaylists() =>
      (db.select(db.playlists)
            ..orderBy([(p) => OrderingTerm.asc(p.sortOrder)]))
          .get();

  Future<Playlist?> getPlaylistById(String id) =>
      (db.select(db.playlists)..where((p) => p.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertPlaylist(PlaylistsCompanion playlist) =>
      db.into(db.playlists).insert(playlist);

  Future<int> updatePlaylist(PlaylistsCompanion playlist) =>
      (db.update(db.playlists)
            ..where((p) => p.id.equals(playlist.id.value)))
          .write(playlist);

  Future<int> deletePlaylist(String id) async {
    await (db.delete(db.playlistEntries)
          ..where((e) => e.playlistId.equals(id)))
        .go();
    return (db.delete(db.playlists)..where((p) => p.id.equals(id))).go();
  }

  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) =>
      (db.select(db.playlistEntries)
            ..where((e) => e.playlistId.equals(playlistId))
            ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
          .get();

  Future<List<Song>> getPlaylistSongs(String playlistId) {
    final query = db.select(db.playlistEntries).join([
      innerJoin(db.songs,
          db.songs.id.equalsExp(db.playlistEntries.songId)),
    ])
      ..where(db.playlistEntries.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(db.playlistEntries.sortOrder)]);
    return query.map((row) => row.readTable(db.songs)).get();
  }

  Future<int> addSongToPlaylist(PlaylistEntriesCompanion entry) =>
      db.into(db.playlistEntries).insert(entry);

  Future<int> removeSongFromPlaylist(String entryId) =>
      (db.delete(db.playlistEntries)..where((e) => e.id.equals(entryId)))
          .go();

  Future<int> reorderEntry(String entryId, int newOrder) =>
      (db.update(db.playlistEntries)..where((e) => e.id.equals(entryId)))
          .write(PlaylistEntriesCompanion(sortOrder: Value(newOrder)));

  Future<int> getPlaylistCount() =>
      db.customSelect('SELECT COUNT(*) as count FROM playlists')
          .getSingle()
          .then((r) => r.read<int>('count'));

  Future<int> getEntryCount(String playlistId) =>
      db.customSelect(
        'SELECT COUNT(*) as count FROM playlist_entries WHERE playlist_id = ?',
        variables: [Variable(playlistId)],
      ).getSingle().then((r) => r.read<int>('count'));
}
