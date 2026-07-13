import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/core/database/app_database.dart';
import 'package:sonicvault/core/database/daos/playlist_dao.dart';
import 'package:sonicvault/core/database/daos/song_dao.dart';

void main() {
  late AppDatabase db;
  late PlaylistDao playlistDao;
  late SongDao songDao;

  setUp(() {
    db = AppDatabase.testing(NativeDatabase.memory());
    playlistDao = PlaylistDao(db);
    songDao = SongDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  final testSong1 = SongsCompanion.insert(
    id: 'song-1',
    title: 'Song One',
    artist: Value('Artist'),
    album: Value('Album'),
    durationMs: 180000,
    filePath: '/music/one.mp3',
    fileName: 'one.mp3',
    fileSize: 5000000,
    fileFormat: 'mp3',
    dateAdded: DateTime(2026, 1, 1),
    dateModified: DateTime(2026, 1, 1),
  );

  final testSong2 = SongsCompanion.insert(
    id: 'song-2',
    title: 'Song Two',
    artist: Value('Artist'),
    durationMs: 240000,
    filePath: '/music/two.flac',
    fileName: 'two.flac',
    fileSize: 20000000,
    fileFormat: 'flac',
    dateAdded: DateTime(2026, 1, 1),
    dateModified: DateTime(2026, 1, 1),
  );

  Future<void> seedSongs() => songDao.batchInsertSongs([testSong1, testSong2]);

  group('playlist CRUD', () {
    test('insert and retrieve playlist', () async {
      final id = await playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(
          id: 'pl-1',
          name: 'My Favorites',
          dateCreated: DateTime(2026, 7, 1),
          dateModified: DateTime(2026, 7, 1),
        ),
      );
      expect(id, greaterThan(0));

      final playlists = await playlistDao.getAllPlaylists();
      expect(playlists, hasLength(1));
      expect(playlists.first.name, 'My Favorites');
    });

    test('getPlaylistById returns null for missing id', () async {
      final pl = await playlistDao.getPlaylistById('nonexistent');
      expect(pl, isNull);
    });

    test('updatePlaylist changes fields', () async {
      await playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(
          id: 'pl-1',
          name: 'Old Name',
          dateCreated: DateTime(2026, 7, 1),
          dateModified: DateTime(2026, 7, 1),
        ),
      );

      await playlistDao.updatePlaylist(
        PlaylistsCompanion(
          id: Value('pl-1'),
          name: Value('New Name'),
          dateCreated: Value(DateTime(2026, 7, 1)),
          dateModified: Value(DateTime(2026, 7, 5)),
        ),
      );

      final pl = await playlistDao.getPlaylistById('pl-1');
      expect(pl!.name, 'New Name');
    });

    test('deletePlaylist removes playlist and its entries', () async {
      await seedSongs();
      await playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(
          id: 'pl-1',
          name: 'To Delete',
          dateCreated: DateTime(2026, 7, 1),
          dateModified: DateTime(2026, 7, 1),
        ),
      );
      await playlistDao.addSongToPlaylist(
        PlaylistEntriesCompanion.insert(
          id: 'entry-1',
          playlistId: 'pl-1',
          songId: 'song-1',
          sortOrder: 0,
          dateAdded: DateTime(2026, 7, 1),
        ),
      );

      await playlistDao.deletePlaylist('pl-1');

      expect(await playlistDao.getPlaylistById('pl-1'), isNull);
      expect(await playlistDao.getEntryCount('pl-1'), 0);
    });
  });

  group('playlist entries', () {
    setUp(() async {
      await seedSongs();
      await playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(
          id: 'pl-1',
          name: 'Test PL',
          dateCreated: DateTime(2026, 7, 1),
          dateModified: DateTime(2026, 7, 1),
        ),
      );
      await playlistDao.addSongToPlaylist(
        PlaylistEntriesCompanion.insert(
          id: 'entry-1',
          playlistId: 'pl-1',
          songId: 'song-1',
          sortOrder: 1,
          dateAdded: DateTime(2026, 7, 1),
        ),
      );
      await playlistDao.addSongToPlaylist(
        PlaylistEntriesCompanion.insert(
          id: 'entry-2',
          playlistId: 'pl-1',
          songId: 'song-2',
          sortOrder: 0,
          dateAdded: DateTime(2026, 7, 2),
        ),
      );
    });

    test('getPlaylistEntries returns entries in sort order', () async {
      final entries = await playlistDao.getPlaylistEntries('pl-1');
      expect(entries, hasLength(2));
      expect(entries.first.id, 'entry-2'); // sortOrder 0
      expect(entries.last.id, 'entry-1');  // sortOrder 1
    });

    test('getPlaylistSongs joins and returns songs in order', () async {
      final songs = await playlistDao.getPlaylistSongs('pl-1');
      expect(songs, hasLength(2));
      expect(songs.first.id, 'song-2'); // sortOrder 0 first
      expect(songs.last.id, 'song-1');
    });

    test('removeSongFromPlaylist removes entry', () async {
      await playlistDao.removeSongFromPlaylist('entry-1');
      final entries = await playlistDao.getPlaylistEntries('pl-1');
      expect(entries, hasLength(1));
    });

    test('reorderEntry changes sort order', () async {
      await playlistDao.reorderEntry('entry-1', 99);
      final entries = await playlistDao.getPlaylistEntries('pl-1');
      final entry1 = entries.firstWhere((e) => e.id == 'entry-1');
      expect(entry1.sortOrder, 99);
    });
  });

  group('counts', () {
    test('getPlaylistCount and getEntryCount', () async {
      await seedSongs();
      expect(await playlistDao.getPlaylistCount(), 0);

      await playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(
          id: 'pl-1',
          name: 'PL',
          dateCreated: DateTime(2026, 7, 1),
          dateModified: DateTime(2026, 7, 1),
        ),
      );
      expect(await playlistDao.getPlaylistCount(), 1);
      expect(await playlistDao.getEntryCount('pl-1'), 0);

      await playlistDao.addSongToPlaylist(
        PlaylistEntriesCompanion.insert(
          id: 'entry-1',
          playlistId: 'pl-1',
          songId: 'song-1',
          sortOrder: 0,
          dateAdded: DateTime(2026, 7, 1),
        ),
      );
      expect(await playlistDao.getEntryCount('pl-1'), 1);
    });
  });
}
