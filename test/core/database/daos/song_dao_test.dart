import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/core/database/app_database.dart';
import 'package:sonicvault/core/database/daos/song_dao.dart';

void main() {
  late AppDatabase db;
  late SongDao dao;

  setUp(() {
    db = AppDatabase.testing(NativeDatabase.memory());
    dao = SongDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  final testSong1 = SongsCompanion.insert(
    id: 'song-1',
    title: 'Test Song A',
    artist: Value('Artist One'),
    album: Value('Album X'),
    durationMs: 180000,
    filePath: '/music/test_a.mp3',
    fileName: 'test_a.mp3',
    fileSize: 5000000,
    fileFormat: 'mp3',
    dateAdded: DateTime(2026, 1, 15),
    dateModified: DateTime(2026, 1, 15),
  );

  final testSong2 = SongsCompanion.insert(
    id: 'song-2',
    title: 'Test Song B',
    artist: Value('Artist Two'),
    album: Value('Album X'),
    durationMs: 240000,
    filePath: '/music/test_b.flac',
    fileName: 'test_b.flac',
    fileSize: 20000000,
    fileFormat: 'flac',
    dateAdded: DateTime(2026, 3, 20),
    dateModified: DateTime(2026, 3, 20),
  );

  final testSong3 = SongsCompanion.insert(
    id: 'song-3',
    title: 'Zebra Song',
    artist: Value('Artist One'),
    album: Value('Album Y'),
    durationMs: 120000,
    filePath: '/music/test_c.ogg',
    fileName: 'test_c.ogg',
    fileSize: 3000000,
    fileFormat: 'ogg',
    dateAdded: DateTime(2026, 6, 1),
    dateModified: DateTime(2026, 6, 1),
    isFavorite: Value(true),
  );

  Future<void> seedSongs() async {
    await dao.batchInsertSongs([testSong1, testSong2, testSong3]);
  }

  group('insert and query', () {
    test('getAllSongs returns all songs', () async {
      await seedSongs();
      final songs = await dao.getAllSongs();
      expect(songs, hasLength(3));
    });

    test('getSongById returns correct song', () async {
      await seedSongs();
      final song = await dao.getSongById('song-2');
      expect(song, isNotNull);
      expect(song!.title, 'Test Song B');
    });

    test('getSongById returns null for missing id', () async {
      final song = await dao.getSongById('nonexistent');
      expect(song, isNull);
    });

    test('insertSong adds a single song', () async {
      await dao.insertSong(testSong1);
      final songs = await dao.getAllSongs();
      expect(songs, hasLength(1));
      expect(songs.first.title, 'Test Song A');
    });
  });

  group('filters', () {
    setUp(() => seedSongs());

    test('getSongsByArtist filters correctly', () async {
      final songs = await dao.getSongsByArtist('Artist One');
      expect(songs, hasLength(2));
      expect(songs.every((s) => s.artist == 'Artist One'), isTrue);
    });

    test('getSongsByAlbum filters correctly', () async {
      final songs = await dao.getSongsByAlbum('Album X');
      expect(songs, hasLength(2));
    });

    test('getFavoriteSongs returns only favorites', () async {
      final songs = await dao.getFavoriteSongs();
      expect(songs, hasLength(1));
      expect(songs.first.id, 'song-3');
    });

    test('searchSongs matches title', () async {
      final songs = await dao.searchSongs('Zebra');
      expect(songs, hasLength(1));
    });

    test('searchSongs matches artist', () async {
      final songs = await dao.searchSongs('Artist Two');
      expect(songs, hasLength(1));
    });

    test('searchSongs matches album', () async {
      final songs = await dao.searchSongs('Album Y');
      expect(songs, hasLength(1));
    });

    test('searchSongs returns empty for no match', () async {
      final songs = await dao.searchSongs('Nonexistent');
      expect(songs, isEmpty);
    });
  });

  group('order and limit', () {
    setUp(() => seedSongs());

    test('getRecentSongs returns most recent first', () async {
      final songs = await dao.getRecentSongs();
      expect(songs.first.id, 'song-3');
      expect(songs.last.id, 'song-1');
    });

    test('getMostPlayedSongs orders by play count', () async {
      // Increment play counts
      await dao.incrementPlayCount('song-1');
      await dao.incrementPlayCount('song-1');
      await dao.incrementPlayCount('song-3');

      final songs = await dao.getMostPlayedSongs();
      expect(songs.first.id, 'song-1');
      expect(songs.first.playCount, 2);
    });

    test('getRecentSongs respects limit', () async {
      final songs = await dao.getRecentSongs(limit: 2);
      expect(songs, hasLength(2));
    });
  });

  group('getAllArtists', () {
    test('returns unique sorted artists', () async {
      await seedSongs();
      final artists = await dao.getAllArtists();
      expect(artists, containsAll(['Artist One', 'Artist Two']));
      expect(artists.indexOf('Artist One'), lessThan(artists.indexOf('Artist Two')));
    });

    test('treats null artist as Unknown Artist', () async {
      final noArtist = SongsCompanion.insert(
        id: 'song-no-artist',
        title: 'No Artist Song',
        durationMs: 100000,
        filePath: '/music/no_artist.mp3',
        fileName: 'no_artist.mp3',
        fileSize: 1000000,
        fileFormat: 'mp3',
        dateAdded: DateTime(2026, 1, 1),
        dateModified: DateTime(2026, 1, 1),
      );
      await dao.insertSong(noArtist);
      final artists = await dao.getAllArtists();
      expect(artists, contains('Unknown Artist'));
    });
  });

  group('update and delete', () {
    setUp(() => seedSongs());

    test('updateSong changes fields', () async {
      await dao.updateSong(
        SongsCompanion(
          id: Value('song-1'),
          title: Value('Updated Title'),
          filePath: Value('/music/test_a.mp3'),
          fileName: Value('test_a.mp3'),
          fileSize: Value(5000000),
          fileFormat: Value('mp3'),
          durationMs: Value(180000),
          dateAdded: Value(DateTime(2026, 1, 15)),
          dateModified: Value(DateTime(2026, 1, 15)),
        ),
      );
      final song = await dao.getSongById('song-1');
      expect(song!.title, 'Updated Title');
    });

    test('deleteSong removes song', () async {
      await dao.deleteSong('song-2');
      final songs = await dao.getAllSongs();
      expect(songs, hasLength(2));
      expect(songs.any((s) => s.id == 'song-2'), isFalse);
    });

    test('toggleFavorite flips is_favorite', () async {
      await dao.toggleFavorite('song-1');
      final song = await dao.getSongById('song-1');
      expect(song!.isFavorite, isTrue);

      await dao.toggleFavorite('song-1');
      final reloaded = await dao.getSongById('song-1');
      expect(reloaded!.isFavorite, isFalse);
    });

    test('incrementPlayCount and getSongCount', () async {
      final count = await dao.getSongCount();
      expect(count, 3);

      await dao.incrementPlayCount('song-1');
      final song = await dao.getSongById('song-1');
      expect(song!.playCount, 1);
    });
  });

  group('clear', () {
    test('clearAllSongs removes all songs', () async {
      await seedSongs();
      await dao.clearAllSongs();
      final songs = await dao.getAllSongs();
      expect(songs, isEmpty);
    });
  });
}
