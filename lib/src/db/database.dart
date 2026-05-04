import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

/// A conversation.
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
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
  IntColumn get parentMessageId => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// The app's local database.
///
/// Schema history:
///   v1 (initial):  Conversations (with model_id), Messages (with
///                  generation_metrics_json), ModelEntries, Benchmarks, FTS5.
///   v2 (previous): Dropped ModelEntries table.
///   v3 (current):  Dropped Benchmarks, FTS5, model_id, generation_metrics_json.
@DriftDatabase(
  tables: [Conversations, Messages],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // ── v1 → v2: Drop ModelEntries (still needed if jumping v1→v3) ──
        if (from < 2) {
          await m.deleteTable('model_entries');
        }

        // ── v2 → v3: Strip all model/inference artifacts ──
        if (from < 3) {
          // Benchmarks table no longer exists in the schema.
          await m.deleteTable('benchmarks');

          // Remove FTS5 virtual table and its triggers (old v2 migration).
          await customStatement('DROP TABLE IF EXISTS messages_fts');
          await customStatement('DROP TRIGGER IF EXISTS messages_ai');
          await customStatement('DROP TRIGGER IF EXISTS messages_ad');
          await customStatement('DROP TRIGGER IF EXISTS messages_au');

          // Drop columns that are no longer in the table definitions.
          await customStatement(
            'ALTER TABLE conversations DROP COLUMN model_id',
          );
          await customStatement(
            'ALTER TABLE messages DROP COLUMN generation_metrics_json',
          );
        }
      },
    );
  }
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
