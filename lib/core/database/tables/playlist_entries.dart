import 'package:drift/drift.dart';
import 'playlists.dart';
import 'songs.dart';

@DataClassName('PlaylistEntry')
class PlaylistEntries extends Table {
  @override
  String get tableName => 'playlist_entries';

  TextColumn get id => text()(); // uuid
  TextColumn get playlistId => text().references(Playlists, #id)();
  TextColumn get songId => text().references(Songs, #id)();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get dateAdded => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
