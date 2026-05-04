import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

/// A model entry — a GGUF file imported into app-private storage.
class ModelEntries extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get originalName => text()();
  TextColumn get internalPath => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();
  TextColumn get profileJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A conversation with an LLM.
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get modelId => text()();
  TextColumn get systemPrompt => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// A message within a conversation.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get generationMetricsJson => text().nullable()();
  IntColumn get parentMessageId => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// A benchmark result.
class Benchmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get modelId => text()();
  TextColumn get backend => text()();
  RealColumn get ppTokPerSec => real()();
  RealColumn get tgTokPerSec => real()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The app's local database.
@DriftDatabase(
  tables: [ModelEntries, Conversations, Messages, Benchmarks],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts '
          'USING fts5(content, content=messages, content_rowid=id)',
        );
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages '
          'BEGIN INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content); END',
        );
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages '
          'BEGIN INSERT INTO messages_fts(messages_fts, rowid, content) '
          'VALUES(\'delete\', old.id, old.content); END',
        );
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages '
          'BEGIN INSERT INTO messages_fts(messages_fts, rowid, content) '
          'VALUES(\'delete\', old.id, old.content); '
          'INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content); END',
        );
      },
    );
  }

  String get messagesFtsTable => 'messages_fts';
}

/// Create the database connection with platform-specific initialisation.
Future<LocalDatabase> createDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  await _ensureSqlite3Initialised();
  final file = File('${dir.path}/local_llm_app.db');
  final nativeDb = NativeDatabase(file);
  return LocalDatabase(nativeDb);
}

Future<void> _ensureSqlite3Initialised() async {
  try {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  } catch (_) {}
}

/// A helper to open an in-memory database for testing.
Future<LocalDatabase> createInMemoryDatabase() async {
  await _ensureSqlite3Initialised();
  return LocalDatabase(NativeDatabase.memory());
}
