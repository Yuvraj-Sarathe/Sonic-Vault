import 'package:drift/drift.dart';

@DataClassName('Song')
class Songs extends Table {
  @override
  String get tableName => 'songs';

  TextColumn get id => text()(); // uuid
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get durationMs => integer()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get fileFormat => text()();
  BoolColumn get hasCoverArt => boolean().withDefault(const Constant(false))();
  TextColumn get coverArtPath => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
