import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../gguf/gguf_parser.dart';
import 'gguf_metadata.dart';
import 'model_profile.dart';

/// Result of a successful model import.
class ModelImportResult {
  const ModelImportResult({
    required this.id,
    required this.originalName,
    required this.internalPath,
    required this.sizeBytes,
    required this.sha256,
    required this.metadata,
    required this.importedAt,
  });

  final String id;
  final String originalName;
  final String internalPath;
  final int sizeBytes;
  final String sha256;
  final GgufMetadata metadata;
  final DateTime importedAt;
}

/// Progress update during model import.
class ModelImportProgress {
  const ModelImportProgress({
    required this.bytesCopied,
    required this.totalBytes,
    required this.phase,
  });

  final int bytesCopied;
  final int totalBytes;
  final String phase;

  double get fraction => totalBytes > 0 ? bytesCopied / totalBytes : 0.0;
}

/// State of the model import process.
sealed class ModelImportState {
  const ModelImportState();
}

class ModelImportIdle extends ModelImportState {
  const ModelImportIdle();
}

class ModelImportInProgress extends ModelImportState {
  const ModelImportInProgress(this.progress);
  final ModelImportProgress progress;
}

class ModelImportComplete extends ModelImportState {
  const ModelImportComplete(this.result);
  final ModelImportResult result;
}

class ModelImportFailed extends ModelImportState {
  const ModelImportFailed(this.error);
  final String error;
}

/// Handles the model import flow.
class ModelImporter {
  ModelImporter._();

  static const _chunkSize = 4 * 1024 * 1024; // 4 MB
  static const _allowedExtensions = ['gguf'];
  static const _maxImportSize = 50 * 1024 * 1024 * 1024; // 50 GB

  /// Pick a GGUF file and import it into app-private storage.
  static Stream<ModelImportState> importModel() async* {
    yield const ModelImportInProgress(
      ModelImportProgress(bytesCopied: 0, totalBytes: 0, phase: 'Picking file...'),
    );

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      yield const ModelImportFailed('No file selected');
      return;
    }

    final file = result.files.first;
    final originalName = file.name;
    final pickPath = file.path;

    if (pickPath == null) {
      yield const ModelImportFailed('Could not access selected file');
      return;
    }

    final sourceFile = File(pickPath);
    final totalBytes = await sourceFile.length();
    if (totalBytes > _maxImportSize) {
      yield ModelImportFailed(
        'File too large (${_formatSize(totalBytes)}). Maximum: ${_formatSize(_maxImportSize)}',
      );
      return;
    }
    if (totalBytes < 100) {
      yield const ModelImportFailed('File is too small to be a valid GGUF model');
      return;
    }

    // Validate GGUF header before copying
    GgufReaderResult parseResult;
    try {
      final headerBytes = await _readRange(sourceFile, 0, min(100 * 1024, totalBytes));
      parseResult = GgufParser.parseBytes(headerBytes);
    } catch (e) {
      yield ModelImportFailed('Invalid GGUF file: $e');
      return;
    }

    final metadata = _extractMetadata(parseResult);

    final uuid = const Uuid().v4();
    final modelsDir = await _ensureModelsDir();
    final internalPath = '${modelsDir.path}/$uuid.gguf';

    yield ModelImportInProgress(
      ModelImportProgress(
        bytesCopied: 0,
        totalBytes: totalBytes,
        phase: 'Importing $originalName...',
      ),
    );

    String sha256Hash;
    try {
      await _copyFile(sourceFile, File(internalPath), totalBytes);
      sha256Hash = await _computeSha256(internalPath);
    } catch (e) {
      try {
        await File(internalPath).delete();
      } catch (_) {}
      yield ModelImportFailed('Copy failed: $e');
      return;
    }

    final importResult = ModelImportResult(
      id: uuid,
      originalName: originalName,
      internalPath: internalPath,
      sizeBytes: totalBytes,
      sha256: sha256Hash,
      metadata: metadata,
      importedAt: DateTime.now(),
    );

    await _writeSidecar(modelsDir, uuid, importResult);

    yield ModelImportComplete(importResult);
  }

  /// Delete an imported model.
  static Future<void> deleteModel(String uuid) async {
    final modelsDir = await _ensureModelsDir();
    try {
      await File('${modelsDir.path}/$uuid.gguf').delete();
    } catch (_) {}
    try {
      await File('${modelsDir.path}/$uuid.json').delete();
    } catch (_) {}
  }

  /// Scan the models directory for sidecar JSONs and return the imported models.
  static Future<List<ModelImportResult>> scanImportedModels() async {
    final modelsDir = await _ensureModelsDir();
    final results = <ModelImportResult>[];
    final entities = await modelsDir.list().toList();

    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final content = await entity.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final id = json['id'] as String;
        final ggufPath = '${modelsDir.path}/$id.gguf';
        if (!await File(ggufPath).exists()) continue;

        results.add(ModelImportResult(
          id: id,
          originalName: json['original_name'] as String,
          internalPath: ggufPath,
          sizeBytes: json['size_bytes'] as int,
          sha256: json['sha256'] as String,
          metadata: _metadataFromJson(json['metadata'] as Map<String, dynamic>?),
          importedAt: DateTime.parse(json['imported_at'] as String),
        ));
      } catch (_) {
        continue;
      }
    }

    results.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return results;
  }

  /// Read the sidecar profile for a model.
  static Future<ModelProfile?> readProfile(String uuid) async {
    final modelsDir = await _ensureModelsDir();
    final file = File('${modelsDir.path}/$uuid.json');
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['profile'] != null) {
        return ModelProfile.fromJson(json['profile'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Write the profile for a model.
  static Future<void> writeProfile(String uuid, ModelProfile profile) async {
    final modelsDir = await _ensureModelsDir();
    final file = File('${modelsDir.path}/$uuid.json');
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      json['profile'] = profile.toJson();
      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  // --- Private helpers ---

  static Future<Directory> _ensureModelsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  static Future<Uint8List> _readRange(File file, int start, int length) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(start);
      final buffer = Uint8List(length);
      final bytesRead = await raf.readInto(buffer);
      if (bytesRead < length) {
        return buffer.sublist(0, bytesRead);
      }
      return buffer;
    } finally {
      await raf.close();
    }
  }

  static Future<void> _copyFile(File source, File destination, int totalBytes) async {
    final src = await source.open(mode: FileMode.read);
    final dst = await destination.open(mode: FileMode.write);

    try {
      var copied = 0;
      final buffer = Uint8List(_chunkSize);

      while (copied < totalBytes) {
        final bytesRead = await src.readInto(buffer);
        if (bytesRead == 0) break;

        await dst.writeFrom(buffer, 0, bytesRead);
        copied += bytesRead;
      }
    } finally {
      await src.close();
      await dst.close();
    }
  }

  static Future<String> _computeSha256(String path) async {
    final file = File(path);
    final len = await file.length();
    final raf = await file.open(mode: FileMode.read);

    String? result;
    final outSink = ChunkedConversionSink<Digest>.withCallback((digests) {
      result = digests.single.toString();
    });
    final inSink = sha256.startChunkedConversion(outSink);

    try {
      final buffer = Uint8List(_chunkSize);
      var offset = 0;
      while (offset < len) {
        final bytesRead = await raf.readInto(buffer);
        if (bytesRead == 0) break;
        inSink.add(buffer.sublist(0, bytesRead));
        offset += bytesRead;
      }
    } finally {
      inSink.close();
      await raf.close();
    }

    return result!;
  }

  static GgufMetadata _extractMetadata(GgufReaderResult parsed) {
    String? getStr(String key) {
      final v = parsed[key];
      if (v is GgufStringValue) return v.value;
      return null;
    }

    int? getInt(String key) {
      final v = parsed[key];
      if (v is GgufNumericValue) return v.asInt;
      return null;
    }

    final arch = getStr('general.architecture') ?? 'unknown';

    return GgufMetadata(
      architecture: arch,
      name: getStr('general.name'),
      sizeLabel: getStr('general.size_label'),
      quantizationVersion: getInt('general.quantization_version'),
      fileType: getInt('general.file_type'),
      parameterCount: getInt('general.parameter_count'),
      contextLength: getInt('$arch.context_length'),
      embeddingLength: getInt('$arch.embedding_length'),
      blockCount: getInt('$arch.block_count'),
      chatTemplate: getStr('tokenizer.chat_template'),
    );
  }

  static GgufMetadata _metadataFromJson(Map<String, dynamic>? json) {
    if (json == null) return const GgufMetadata();
    return GgufMetadata(
      architecture: json['architecture'] as String?,
      name: json['name'] as String?,
      sizeLabel: json['size_label'] as String?,
      quantizationVersion: json['quantization_version'] as int?,
      fileType: json['file_type'] as int?,
      parameterCount: json['parameter_count'] as int?,
      contextLength: json['context_length'] as int?,
      embeddingLength: json['embedding_length'] as int?,
      blockCount: json['block_count'] as int?,
      chatTemplate: json['chat_template'] as String?,
    );
  }

  static Future<void> _writeSidecar(
    Directory modelsDir,
    String uuid,
    ModelImportResult result,
  ) async {
    final file = File('${modelsDir.path}/$uuid.json');
    final metadataMap = <String, dynamic>{};
    if (result.metadata.architecture != null) {
      metadataMap['architecture'] = result.metadata.architecture;
    }
    if (result.metadata.name != null) {
      metadataMap['name'] = result.metadata.name;
    }
    if (result.metadata.sizeLabel != null) {
      metadataMap['size_label'] = result.metadata.sizeLabel;
    }
    if (result.metadata.quantizationVersion != null) {
      metadataMap['quantization_version'] = result.metadata.quantizationVersion;
    }
    if (result.metadata.fileType != null) {
      metadataMap['file_type'] = result.metadata.fileType;
    }
    if (result.metadata.parameterCount != null) {
      metadataMap['parameter_count'] = result.metadata.parameterCount;
    }
    if (result.metadata.contextLength != null) {
      metadataMap['context_length'] = result.metadata.contextLength;
    }
    if (result.metadata.embeddingLength != null) {
      metadataMap['embedding_length'] = result.metadata.embeddingLength;
    }
    if (result.metadata.blockCount != null) {
      metadataMap['block_count'] = result.metadata.blockCount;
    }
    if (result.metadata.chatTemplate != null) {
      metadataMap['chat_template'] = result.metadata.chatTemplate;
    }

    final data = {
      'id': uuid,
      'original_name': result.originalName,
      'size_bytes': result.sizeBytes,
      'sha256': result.sha256,
      'imported_at': result.importedAt.toIso8601String(),
      'metadata': metadataMap,
    };
    await file.writeAsString(jsonEncode(data));
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '$bytes B';
  }
}
