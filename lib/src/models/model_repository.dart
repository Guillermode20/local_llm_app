import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'gguf_metadata.dart';
import 'model_importer.dart';
import 'model_profile.dart';

// ---------------------------------------------------------------------------
// Database provider
// ---------------------------------------------------------------------------

/// Singleton provider for the local database.
final databaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError('Database must be initialised before use');
});

/// Initialise the database and override the provider.
Future<LocalDatabase> initDatabase() async {
  final db = await createDatabase();
  return db;
}

// ---------------------------------------------------------------------------
// Model entry data class (used in the UI layer)
// ---------------------------------------------------------------------------

/// A model entry displayed in the model manager UI.
class ModelEntry {
  const ModelEntry({
    required this.id,
    required this.originalName,
    required this.internalPath,
    required this.sizeBytes,
    required this.sha256,
    required this.importedAt,
    this.metadata,
    this.profile,
  });

  final String id;
  final String originalName;
  final String internalPath;
  final int sizeBytes;
  final String sha256;
  final DateTime importedAt;
  final GgufMetadata? metadata;
  final ModelProfile? profile;

  ModelEntry copyWith({ModelProfile? profile}) {
    return ModelEntry(
      id: id,
      originalName: originalName,
      internalPath: internalPath,
      sizeBytes: sizeBytes,
      sha256: sha256,
      importedAt: importedAt,
      metadata: metadata,
      profile: profile ?? this.profile,
    );
  }

  /// Human-readable file size.
  String get prettySize {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '$sizeBytes B';
  }

  /// Display name (original name without path).
  String get displayName {
    if (metadata?.name != null && metadata!.name!.isNotEmpty) {
      return metadata!.name!;
    }
    // Strip .gguf extension
    final name = originalName.endsWith('.gguf')
        ? originalName.substring(0, originalName.length - 5)
        : originalName;
    return name;
  }

  /// Short description for list view.
  String get subtitle {
    final parts = <String>[];
    if (metadata?.prettyQuant != null &&
        metadata!.prettyQuant != 'Unknown') {
      parts.add(metadata!.prettyQuant);
    }
    if (metadata?.prettyParamCount != null) {
      parts.add(metadata!.prettyParamCount);
    }
    parts.add(prettySize);
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Key for persisting the active model ID
// ---------------------------------------------------------------------------

const _activeModelIdKey = 'active_model_id';

// ---------------------------------------------------------------------------
// Model repository
// ---------------------------------------------------------------------------

/// Manages the list of imported models and the currently active model.
class ModelRepository {
  ModelRepository({required this.db, required this.sharedPrefs});

  final LocalDatabase db;
  final SharedPreferences sharedPrefs;

  List<ModelEntry> _models = [];
  String? _activeModelId;

  /// The current list of models.
  List<ModelEntry> get models => List.unmodifiable(_models);

  /// The currently active model ID, or null.
  String? get activeModelId => _activeModelId;

  /// Import a model and add it to the repository.
  Future<ModelImportResult> addModel(ModelImportResult result) async {
    await db.into(db.modelEntries).insert(ModelEntriesCompanion(
          id: Value(result.id),
          originalName: Value(result.originalName),
          internalPath: Value(result.internalPath),
          sizeBytes: Value(result.sizeBytes),
          sha256: Value(result.sha256),
          importedAt: Value(result.importedAt),
        ));

    final entry = _resultToEntry(result);
    _models.insert(0, entry);
    return result;
  }

  /// Remove a model and delete its files.
  Future<void> removeModel(String id) async {
    await ModelImporter.deleteModel(id);

    // Remove from Drift
    await (db.delete(db.modelEntries)..where((t) => t.id.equals(id))).go();

    _models.removeWhere((m) => m.id == id);

    if (_activeModelId == id) {
      _activeModelId = null;
      await sharedPrefs.remove(_activeModelIdKey);
    }
  }

  /// Set the active model.
  Future<void> setActiveModel(String? id) async {
    _activeModelId = id;
    if (id != null) {
      await sharedPrefs.setString(_activeModelIdKey, id);
    } else {
      await sharedPrefs.remove(_activeModelIdKey);
    }
  }

  /// Reload the model list from disk and sync Drift to match.
  Future<void> refresh() async {
    final imported = await ModelImporter.scanImportedModels();
    _models = imported.map(_resultToEntry).toList();

    // Sync Drift rows to match sidecar files (sidecar is source of truth).
    await _syncToDrift(imported);

    // Restore persisted active model
    _activeModelId = sharedPrefs.getString(_activeModelIdKey);
    if (_activeModelId != null &&
        !_models.any((m) => m.id == _activeModelId)) {
      _activeModelId = null;
      await sharedPrefs.remove(_activeModelIdKey);
    }
  }

  /// Sync Drift model_entries table to match sidecar files.
  Future<void> _syncToDrift(List<ModelImportResult> imported) async {
    // Get all current Drift IDs.
    final driftRows = await (db.select(db.modelEntries)).get();
    final driftIds = driftRows.map((r) => r.id).toSet();
    final sidecarIds = imported.map((r) => r.id).toSet();

    // Remove Drift rows for models that no longer have sidecar files.
    for (final row in driftRows) {
      if (!sidecarIds.contains(row.id)) {
        await (db.delete(db.modelEntries)..where((t) => t.id.equals(row.id))).go();
      }
    }

    // Add/update Drift rows for models from sidecar.
    for (final result in imported) {
      if (driftIds.contains(result.id)) {
        // Update existing row.
        await (db.update(db.modelEntries)..where((t) => t.id.equals(result.id)))
            .write(ModelEntriesCompanion(
              originalName: Value(result.originalName),
              sizeBytes: Value(result.sizeBytes),
              sha256: Value(result.sha256),
              metadataJson: Value(jsonEncode({
                      if (result.metadata.architecture != null) 'architecture': result.metadata.architecture,
                      if (result.metadata.name != null) 'name': result.metadata.name,
                      if (result.metadata.fileType != null) 'file_type': result.metadata.fileType,
                      if (result.metadata.parameterCount != null) 'parameter_count': result.metadata.parameterCount,
                      if (result.metadata.contextLength != null) 'context_length': result.metadata.contextLength,
                    })),
            ));
      } else {
        // Insert new row.
        await db.into(db.modelEntries).insert(ModelEntriesCompanion(
              id: Value(result.id),
              originalName: Value(result.originalName),
              internalPath: Value(result.internalPath),
              sizeBytes: Value(result.sizeBytes),
              sha256: Value(result.sha256),
              importedAt: Value(result.importedAt),
            ));
      }

      // Sync profile data from sidecar into Drift.
      final profile = await ModelImporter.readProfile(result.id);
      if (profile != null) {
        await (db.update(db.modelEntries)..where((t) => t.id.equals(result.id)))
            .write(ModelEntriesCompanion(
              profileJson: Value(jsonEncode(profile.toJson())),
            ));
      }
    }
  }

  /// Get the active model entry, or null.
  ModelEntry? get activeModel {
    if (_activeModelId == null) return null;
    try {
      return _models.firstWhere((m) => m.id == _activeModelId);
    } catch (_) {
      return null;
    }
  }

  static ModelEntry _resultToEntry(ModelImportResult result) {
    return ModelEntry(
      id: result.id,
      originalName: result.originalName,
      internalPath: result.internalPath,
      sizeBytes: result.sizeBytes,
      sha256: result.sha256,
      importedAt: result.importedAt,
      metadata: result.metadata,
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// The model repository singleton.
final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  throw UnimplementedError('ModelRepository must be initialised before use');
});

/// Watch the list of models.
final modelListProvider = NotifierProvider<ModelListNotifier, List<ModelEntry>>(
  ModelListNotifier.new,
);

class ModelListNotifier extends Notifier<List<ModelEntry>> {
  @override
  List<ModelEntry> build() {
    final repo = ref.read(modelRepositoryProvider);
    return repo.models;
  }

  /// Refresh the list from disk.
  Future<void> refresh() async {
    final repo = ref.read(modelRepositoryProvider);
    await repo.refresh();
    state = [...repo.models];
  }
}

/// The currently active model.
final activeModelProvider = NotifierProvider<ActiveModelNotifier, ModelEntry?>(
  ActiveModelNotifier.new,
);

class ActiveModelNotifier extends Notifier<ModelEntry?> {
  @override
  ModelEntry? build() {
    final repo = ref.read(modelRepositoryProvider);
    return repo.activeModel;
  }

  /// Set the active model by ID.
  Future<void> setActive(String? id) async {
    final repo = ref.read(modelRepositoryProvider);
    await repo.setActiveModel(id);
    state = repo.activeModel;
  }
}

/// Import state provider — tracks the current model import flow.
final modelImportStateProvider =
    StateProvider<ModelImportState>((ref) => const ModelImportIdle());
