import 'package:drift/drift.dart';

@DataClassName('Playlist')
class Playlists extends Table {
  @override
  String get tableName => 'playlists';

  TextColumn get id => text()(); // uuid
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverArtPath => text().nullable()();
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateModified => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
