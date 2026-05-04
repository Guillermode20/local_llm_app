// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ModelEntriesTable extends ModelEntries
    with TableInfo<$ModelEntriesTable, ModelEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalNameMeta =
      const VerificationMeta('originalName');
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
      'original_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _internalPathMeta =
      const VerificationMeta('internalPath');
  @override
  late final GeneratedColumn<String> internalPath = GeneratedColumn<String>(
      'internal_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profileJsonMeta =
      const VerificationMeta('profileJson');
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
      'profile_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        originalName,
        internalPath,
        sizeBytes,
        sha256,
        importedAt,
        metadataJson,
        profileJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ModelEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
          _originalNameMeta,
          originalName.isAcceptableOrUnknown(
              data['original_name']!, _originalNameMeta));
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('internal_path')) {
      context.handle(
          _internalPathMeta,
          internalPath.isAcceptableOrUnknown(
              data['internal_path']!, _internalPathMeta));
    } else if (isInserting) {
      context.missing(_internalPathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('profile_json')) {
      context.handle(
          _profileJsonMeta,
          profileJson.isAcceptableOrUnknown(
              data['profile_json']!, _profileJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      originalName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_name'])!,
      internalPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}internal_path'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256']),
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}imported_at'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json']),
      profileJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_json']),
    );
  }

  @override
  $ModelEntriesTable createAlias(String alias) {
    return $ModelEntriesTable(attachedDatabase, alias);
  }
}

class ModelEntry extends DataClass implements Insertable<ModelEntry> {
  final String id;
  final String originalName;
  final String internalPath;
  final int sizeBytes;
  final String? sha256;
  final DateTime importedAt;
  final String? metadataJson;
  final String? profileJson;
  const ModelEntry(
      {required this.id,
      required this.originalName,
      required this.internalPath,
      required this.sizeBytes,
      this.sha256,
      required this.importedAt,
      this.metadataJson,
      this.profileJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original_name'] = Variable<String>(originalName);
    map['internal_path'] = Variable<String>(internalPath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || profileJson != null) {
      map['profile_json'] = Variable<String>(profileJson);
    }
    return map;
  }

  ModelEntriesCompanion toCompanion(bool nullToAbsent) {
    return ModelEntriesCompanion(
      id: Value(id),
      originalName: Value(originalName),
      internalPath: Value(internalPath),
      sizeBytes: Value(sizeBytes),
      sha256:
          sha256 == null && nullToAbsent ? const Value.absent() : Value(sha256),
      importedAt: Value(importedAt),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      profileJson: profileJson == null && nullToAbsent
          ? const Value.absent()
          : Value(profileJson),
    );
  }

  factory ModelEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelEntry(
      id: serializer.fromJson<String>(json['id']),
      originalName: serializer.fromJson<String>(json['originalName']),
      internalPath: serializer.fromJson<String>(json['internalPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      profileJson: serializer.fromJson<String?>(json['profileJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'originalName': serializer.toJson<String>(originalName),
      'internalPath': serializer.toJson<String>(internalPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String?>(sha256),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'profileJson': serializer.toJson<String?>(profileJson),
    };
  }

  ModelEntry copyWith(
          {String? id,
          String? originalName,
          String? internalPath,
          int? sizeBytes,
          Value<String?> sha256 = const Value.absent(),
          DateTime? importedAt,
          Value<String?> metadataJson = const Value.absent(),
          Value<String?> profileJson = const Value.absent()}) =>
      ModelEntry(
        id: id ?? this.id,
        originalName: originalName ?? this.originalName,
        internalPath: internalPath ?? this.internalPath,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        sha256: sha256.present ? sha256.value : this.sha256,
        importedAt: importedAt ?? this.importedAt,
        metadataJson:
            metadataJson.present ? metadataJson.value : this.metadataJson,
        profileJson: profileJson.present ? profileJson.value : this.profileJson,
      );
  ModelEntry copyWithCompanion(ModelEntriesCompanion data) {
    return ModelEntry(
      id: data.id.present ? data.id.value : this.id,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      internalPath: data.internalPath.present
          ? data.internalPath.value
          : this.internalPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      profileJson:
          data.profileJson.present ? data.profileJson.value : this.profileJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelEntry(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('internalPath: $internalPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('importedAt: $importedAt, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('profileJson: $profileJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, originalName, internalPath, sizeBytes,
      sha256, importedAt, metadataJson, profileJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelEntry &&
          other.id == this.id &&
          other.originalName == this.originalName &&
          other.internalPath == this.internalPath &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.importedAt == this.importedAt &&
          other.metadataJson == this.metadataJson &&
          other.profileJson == this.profileJson);
}

class ModelEntriesCompanion extends UpdateCompanion<ModelEntry> {
  final Value<String> id;
  final Value<String> originalName;
  final Value<String> internalPath;
  final Value<int> sizeBytes;
  final Value<String?> sha256;
  final Value<DateTime> importedAt;
  final Value<String?> metadataJson;
  final Value<String?> profileJson;
  final Value<int> rowid;
  const ModelEntriesCompanion({
    this.id = const Value.absent(),
    this.originalName = const Value.absent(),
    this.internalPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelEntriesCompanion.insert({
    required String id,
    required String originalName,
    required String internalPath,
    required int sizeBytes,
    this.sha256 = const Value.absent(),
    required DateTime importedAt,
    this.metadataJson = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        originalName = Value(originalName),
        internalPath = Value(internalPath),
        sizeBytes = Value(sizeBytes),
        importedAt = Value(importedAt);
  static Insertable<ModelEntry> custom({
    Expression<String>? id,
    Expression<String>? originalName,
    Expression<String>? internalPath,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<DateTime>? importedAt,
    Expression<String>? metadataJson,
    Expression<String>? profileJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalName != null) 'original_name': originalName,
      if (internalPath != null) 'internal_path': internalPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (importedAt != null) 'imported_at': importedAt,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (profileJson != null) 'profile_json': profileJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? originalName,
      Value<String>? internalPath,
      Value<int>? sizeBytes,
      Value<String?>? sha256,
      Value<DateTime>? importedAt,
      Value<String?>? metadataJson,
      Value<String?>? profileJson,
      Value<int>? rowid}) {
    return ModelEntriesCompanion(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      internalPath: internalPath ?? this.internalPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      importedAt: importedAt ?? this.importedAt,
      metadataJson: metadataJson ?? this.metadataJson,
      profileJson: profileJson ?? this.profileJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (internalPath.present) {
      map['internal_path'] = Variable<String>(internalPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelEntriesCompanion(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('internalPath: $internalPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('importedAt: $importedAt, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('profileJson: $profileJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _systemPromptMeta =
      const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
      'system_prompt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, modelId, systemPrompt, createdAt, updatedAt, archived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
          _systemPromptMeta,
          systemPrompt.isAcceptableOrUnknown(
              data['system_prompt']!, _systemPromptMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      systemPrompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_prompt']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final int id;
  final String title;
  final String modelId;
  final String? systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  const Conversation(
      {required this.id,
      required this.title,
      required this.modelId,
      this.systemPrompt,
      required this.createdAt,
      required this.updatedAt,
      required this.archived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['model_id'] = Variable<String>(modelId);
    if (!nullToAbsent || systemPrompt != null) {
      map['system_prompt'] = Variable<String>(systemPrompt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      modelId: Value(modelId),
      systemPrompt: systemPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPrompt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archived: Value(archived),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      modelId: serializer.fromJson<String>(json['modelId']),
      systemPrompt: serializer.fromJson<String?>(json['systemPrompt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'modelId': serializer.toJson<String>(modelId),
      'systemPrompt': serializer.toJson<String?>(systemPrompt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Conversation copyWith(
          {int? id,
          String? title,
          String? modelId,
          Value<String?> systemPrompt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? archived}) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        modelId: modelId ?? this.modelId,
        systemPrompt:
            systemPrompt.present ? systemPrompt.value : this.systemPrompt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archived: archived ?? this.archived,
      );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, modelId, systemPrompt, createdAt, updatedAt, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.modelId == this.modelId &&
          other.systemPrompt == this.systemPrompt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archived == this.archived);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> modelId;
  final Value<String?> systemPrompt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> archived;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.modelId = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archived = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String modelId,
    this.systemPrompt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archived = const Value.absent(),
  })  : title = Value(title),
        modelId = Value(modelId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? modelId,
    Expression<String>? systemPrompt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (modelId != null) 'model_id': modelId,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archived != null) 'archived': archived,
    });
  }

  ConversationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? modelId,
      Value<String?>? systemPrompt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? archived}) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _generationMetricsJsonMeta =
      const VerificationMeta('generationMetricsJson');
  @override
  late final GeneratedColumn<String> generationMetricsJson =
      GeneratedColumn<String>('generation_metrics_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentMessageIdMeta =
      const VerificationMeta('parentMessageId');
  @override
  late final GeneratedColumn<int> parentMessageId = GeneratedColumn<int>(
      'parent_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        conversationId,
        role,
        content,
        createdAt,
        generationMetricsJson,
        parentMessageId,
        archived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('generation_metrics_json')) {
      context.handle(
          _generationMetricsJsonMeta,
          generationMetricsJson.isAcceptableOrUnknown(
              data['generation_metrics_json']!, _generationMetricsJsonMeta));
    }
    if (data.containsKey('parent_message_id')) {
      context.handle(
          _parentMessageIdMeta,
          parentMessageId.isAcceptableOrUnknown(
              data['parent_message_id']!, _parentMessageIdMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}conversation_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      generationMetricsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}generation_metrics_json']),
      parentMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_message_id']),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? generationMetricsJson;
  final int? parentMessageId;
  final bool archived;
  const Message(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      required this.createdAt,
      this.generationMetricsJson,
      this.parentMessageId,
      required this.archived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || generationMetricsJson != null) {
      map['generation_metrics_json'] = Variable<String>(generationMetricsJson);
    }
    if (!nullToAbsent || parentMessageId != null) {
      map['parent_message_id'] = Variable<int>(parentMessageId);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
      generationMetricsJson: generationMetricsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(generationMetricsJson),
      parentMessageId: parentMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentMessageId),
      archived: Value(archived),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      generationMetricsJson:
          serializer.fromJson<String?>(json['generationMetricsJson']),
      parentMessageId: serializer.fromJson<int?>(json['parentMessageId']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'generationMetricsJson':
          serializer.toJson<String?>(generationMetricsJson),
      'parentMessageId': serializer.toJson<int?>(parentMessageId),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Message copyWith(
          {int? id,
          int? conversationId,
          String? role,
          String? content,
          DateTime? createdAt,
          Value<String?> generationMetricsJson = const Value.absent(),
          Value<int?> parentMessageId = const Value.absent(),
          bool? archived}) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        generationMetricsJson: generationMetricsJson.present
            ? generationMetricsJson.value
            : this.generationMetricsJson,
        parentMessageId: parentMessageId.present
            ? parentMessageId.value
            : this.parentMessageId,
        archived: archived ?? this.archived,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      generationMetricsJson: data.generationMetricsJson.present
          ? data.generationMetricsJson.value
          : this.generationMetricsJson,
      parentMessageId: data.parentMessageId.present
          ? data.parentMessageId.value
          : this.parentMessageId,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('generationMetricsJson: $generationMetricsJson, ')
          ..write('parentMessageId: $parentMessageId, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, role, content, createdAt,
      generationMetricsJson, parentMessageId, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.generationMetricsJson == this.generationMetricsJson &&
          other.parentMessageId == this.parentMessageId &&
          other.archived == this.archived);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<String?> generationMetricsJson;
  final Value<int?> parentMessageId;
  final Value<bool> archived;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.generationMetricsJson = const Value.absent(),
    this.parentMessageId = const Value.absent(),
    this.archived = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required String role,
    required String content,
    required DateTime createdAt,
    this.generationMetricsJson = const Value.absent(),
    this.parentMessageId = const Value.absent(),
    this.archived = const Value.absent(),
  })  : conversationId = Value(conversationId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<String>? generationMetricsJson,
    Expression<int>? parentMessageId,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (generationMetricsJson != null)
        'generation_metrics_json': generationMetricsJson,
      if (parentMessageId != null) 'parent_message_id': parentMessageId,
      if (archived != null) 'archived': archived,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<int>? conversationId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<String?>? generationMetricsJson,
      Value<int?>? parentMessageId,
      Value<bool>? archived}) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      generationMetricsJson:
          generationMetricsJson ?? this.generationMetricsJson,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (generationMetricsJson.present) {
      map['generation_metrics_json'] =
          Variable<String>(generationMetricsJson.value);
    }
    if (parentMessageId.present) {
      map['parent_message_id'] = Variable<int>(parentMessageId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('generationMetricsJson: $generationMetricsJson, ')
          ..write('parentMessageId: $parentMessageId, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $BenchmarksTable extends Benchmarks
    with TableInfo<$BenchmarksTable, Benchmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BenchmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backendMeta =
      const VerificationMeta('backend');
  @override
  late final GeneratedColumn<String> backend = GeneratedColumn<String>(
      'backend', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ppTokPerSecMeta =
      const VerificationMeta('ppTokPerSec');
  @override
  late final GeneratedColumn<double> ppTokPerSec = GeneratedColumn<double>(
      'pp_tok_per_sec', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tgTokPerSecMeta =
      const VerificationMeta('tgTokPerSec');
  @override
  late final GeneratedColumn<double> tgTokPerSec = GeneratedColumn<double>(
      'tg_tok_per_sec', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, modelId, backend, ppTokPerSec, tgTokPerSec, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'benchmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Benchmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('backend')) {
      context.handle(_backendMeta,
          backend.isAcceptableOrUnknown(data['backend']!, _backendMeta));
    } else if (isInserting) {
      context.missing(_backendMeta);
    }
    if (data.containsKey('pp_tok_per_sec')) {
      context.handle(
          _ppTokPerSecMeta,
          ppTokPerSec.isAcceptableOrUnknown(
              data['pp_tok_per_sec']!, _ppTokPerSecMeta));
    } else if (isInserting) {
      context.missing(_ppTokPerSecMeta);
    }
    if (data.containsKey('tg_tok_per_sec')) {
      context.handle(
          _tgTokPerSecMeta,
          tgTokPerSec.isAcceptableOrUnknown(
              data['tg_tok_per_sec']!, _tgTokPerSecMeta));
    } else if (isInserting) {
      context.missing(_tgTokPerSecMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Benchmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Benchmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      backend: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backend'])!,
      ppTokPerSec: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pp_tok_per_sec'])!,
      tgTokPerSec: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tg_tok_per_sec'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BenchmarksTable createAlias(String alias) {
    return $BenchmarksTable(attachedDatabase, alias);
  }
}

class Benchmark extends DataClass implements Insertable<Benchmark> {
  final int id;
  final String modelId;
  final String backend;
  final double ppTokPerSec;
  final double tgTokPerSec;
  final DateTime createdAt;
  const Benchmark(
      {required this.id,
      required this.modelId,
      required this.backend,
      required this.ppTokPerSec,
      required this.tgTokPerSec,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model_id'] = Variable<String>(modelId);
    map['backend'] = Variable<String>(backend);
    map['pp_tok_per_sec'] = Variable<double>(ppTokPerSec);
    map['tg_tok_per_sec'] = Variable<double>(tgTokPerSec);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BenchmarksCompanion toCompanion(bool nullToAbsent) {
    return BenchmarksCompanion(
      id: Value(id),
      modelId: Value(modelId),
      backend: Value(backend),
      ppTokPerSec: Value(ppTokPerSec),
      tgTokPerSec: Value(tgTokPerSec),
      createdAt: Value(createdAt),
    );
  }

  factory Benchmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Benchmark(
      id: serializer.fromJson<int>(json['id']),
      modelId: serializer.fromJson<String>(json['modelId']),
      backend: serializer.fromJson<String>(json['backend']),
      ppTokPerSec: serializer.fromJson<double>(json['ppTokPerSec']),
      tgTokPerSec: serializer.fromJson<double>(json['tgTokPerSec']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'modelId': serializer.toJson<String>(modelId),
      'backend': serializer.toJson<String>(backend),
      'ppTokPerSec': serializer.toJson<double>(ppTokPerSec),
      'tgTokPerSec': serializer.toJson<double>(tgTokPerSec),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Benchmark copyWith(
          {int? id,
          String? modelId,
          String? backend,
          double? ppTokPerSec,
          double? tgTokPerSec,
          DateTime? createdAt}) =>
      Benchmark(
        id: id ?? this.id,
        modelId: modelId ?? this.modelId,
        backend: backend ?? this.backend,
        ppTokPerSec: ppTokPerSec ?? this.ppTokPerSec,
        tgTokPerSec: tgTokPerSec ?? this.tgTokPerSec,
        createdAt: createdAt ?? this.createdAt,
      );
  Benchmark copyWithCompanion(BenchmarksCompanion data) {
    return Benchmark(
      id: data.id.present ? data.id.value : this.id,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      backend: data.backend.present ? data.backend.value : this.backend,
      ppTokPerSec:
          data.ppTokPerSec.present ? data.ppTokPerSec.value : this.ppTokPerSec,
      tgTokPerSec:
          data.tgTokPerSec.present ? data.tgTokPerSec.value : this.tgTokPerSec,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Benchmark(')
          ..write('id: $id, ')
          ..write('modelId: $modelId, ')
          ..write('backend: $backend, ')
          ..write('ppTokPerSec: $ppTokPerSec, ')
          ..write('tgTokPerSec: $tgTokPerSec, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, modelId, backend, ppTokPerSec, tgTokPerSec, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Benchmark &&
          other.id == this.id &&
          other.modelId == this.modelId &&
          other.backend == this.backend &&
          other.ppTokPerSec == this.ppTokPerSec &&
          other.tgTokPerSec == this.tgTokPerSec &&
          other.createdAt == this.createdAt);
}

class BenchmarksCompanion extends UpdateCompanion<Benchmark> {
  final Value<int> id;
  final Value<String> modelId;
  final Value<String> backend;
  final Value<double> ppTokPerSec;
  final Value<double> tgTokPerSec;
  final Value<DateTime> createdAt;
  const BenchmarksCompanion({
    this.id = const Value.absent(),
    this.modelId = const Value.absent(),
    this.backend = const Value.absent(),
    this.ppTokPerSec = const Value.absent(),
    this.tgTokPerSec = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BenchmarksCompanion.insert({
    this.id = const Value.absent(),
    required String modelId,
    required String backend,
    required double ppTokPerSec,
    required double tgTokPerSec,
    required DateTime createdAt,
  })  : modelId = Value(modelId),
        backend = Value(backend),
        ppTokPerSec = Value(ppTokPerSec),
        tgTokPerSec = Value(tgTokPerSec),
        createdAt = Value(createdAt);
  static Insertable<Benchmark> custom({
    Expression<int>? id,
    Expression<String>? modelId,
    Expression<String>? backend,
    Expression<double>? ppTokPerSec,
    Expression<double>? tgTokPerSec,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modelId != null) 'model_id': modelId,
      if (backend != null) 'backend': backend,
      if (ppTokPerSec != null) 'pp_tok_per_sec': ppTokPerSec,
      if (tgTokPerSec != null) 'tg_tok_per_sec': tgTokPerSec,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BenchmarksCompanion copyWith(
      {Value<int>? id,
      Value<String>? modelId,
      Value<String>? backend,
      Value<double>? ppTokPerSec,
      Value<double>? tgTokPerSec,
      Value<DateTime>? createdAt}) {
    return BenchmarksCompanion(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      backend: backend ?? this.backend,
      ppTokPerSec: ppTokPerSec ?? this.ppTokPerSec,
      tgTokPerSec: tgTokPerSec ?? this.tgTokPerSec,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (backend.present) {
      map['backend'] = Variable<String>(backend.value);
    }
    if (ppTokPerSec.present) {
      map['pp_tok_per_sec'] = Variable<double>(ppTokPerSec.value);
    }
    if (tgTokPerSec.present) {
      map['tg_tok_per_sec'] = Variable<double>(tgTokPerSec.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BenchmarksCompanion(')
          ..write('id: $id, ')
          ..write('modelId: $modelId, ')
          ..write('backend: $backend, ')
          ..write('ppTokPerSec: $ppTokPerSec, ')
          ..write('tgTokPerSec: $tgTokPerSec, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $ModelEntriesTable modelEntries = $ModelEntriesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $BenchmarksTable benchmarks = $BenchmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [modelEntries, conversations, messages, benchmarks];
}

typedef $$ModelEntriesTableCreateCompanionBuilder = ModelEntriesCompanion
    Function({
  required String id,
  required String originalName,
  required String internalPath,
  required int sizeBytes,
  Value<String?> sha256,
  required DateTime importedAt,
  Value<String?> metadataJson,
  Value<String?> profileJson,
  Value<int> rowid,
});
typedef $$ModelEntriesTableUpdateCompanionBuilder = ModelEntriesCompanion
    Function({
  Value<String> id,
  Value<String> originalName,
  Value<String> internalPath,
  Value<int> sizeBytes,
  Value<String?> sha256,
  Value<DateTime> importedAt,
  Value<String?> metadataJson,
  Value<String?> profileJson,
  Value<int> rowid,
});

class $$ModelEntriesTableFilterComposer
    extends Composer<_$LocalDatabase, $ModelEntriesTable> {
  $$ModelEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get internalPath => $composableBuilder(
      column: $table.internalPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileJson => $composableBuilder(
      column: $table.profileJson, builder: (column) => ColumnFilters(column));
}

class $$ModelEntriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $ModelEntriesTable> {
  $$ModelEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalName => $composableBuilder(
      column: $table.originalName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get internalPath => $composableBuilder(
      column: $table.internalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileJson => $composableBuilder(
      column: $table.profileJson, builder: (column) => ColumnOrderings(column));
}

class $$ModelEntriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ModelEntriesTable> {
  $$ModelEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => column);

  GeneratedColumn<String> get internalPath => $composableBuilder(
      column: $table.internalPath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
      column: $table.profileJson, builder: (column) => column);
}

class $$ModelEntriesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $ModelEntriesTable,
    ModelEntry,
    $$ModelEntriesTableFilterComposer,
    $$ModelEntriesTableOrderingComposer,
    $$ModelEntriesTableAnnotationComposer,
    $$ModelEntriesTableCreateCompanionBuilder,
    $$ModelEntriesTableUpdateCompanionBuilder,
    (
      ModelEntry,
      BaseReferences<_$LocalDatabase, $ModelEntriesTable, ModelEntry>
    ),
    ModelEntry,
    PrefetchHooks Function()> {
  $$ModelEntriesTableTableManager(_$LocalDatabase db, $ModelEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> originalName = const Value.absent(),
            Value<String> internalPath = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String?> sha256 = const Value.absent(),
            Value<DateTime> importedAt = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            Value<String?> profileJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelEntriesCompanion(
            id: id,
            originalName: originalName,
            internalPath: internalPath,
            sizeBytes: sizeBytes,
            sha256: sha256,
            importedAt: importedAt,
            metadataJson: metadataJson,
            profileJson: profileJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String originalName,
            required String internalPath,
            required int sizeBytes,
            Value<String?> sha256 = const Value.absent(),
            required DateTime importedAt,
            Value<String?> metadataJson = const Value.absent(),
            Value<String?> profileJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelEntriesCompanion.insert(
            id: id,
            originalName: originalName,
            internalPath: internalPath,
            sizeBytes: sizeBytes,
            sha256: sha256,
            importedAt: importedAt,
            metadataJson: metadataJson,
            profileJson: profileJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ModelEntriesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $ModelEntriesTable,
    ModelEntry,
    $$ModelEntriesTableFilterComposer,
    $$ModelEntriesTableOrderingComposer,
    $$ModelEntriesTableAnnotationComposer,
    $$ModelEntriesTableCreateCompanionBuilder,
    $$ModelEntriesTableUpdateCompanionBuilder,
    (
      ModelEntry,
      BaseReferences<_$LocalDatabase, $ModelEntriesTable, ModelEntry>
    ),
    ModelEntry,
    PrefetchHooks Function()>;
typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  Value<int> id,
  required String title,
  required String modelId,
  Value<String?> systemPrompt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> archived,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String> modelId,
  Value<String?> systemPrompt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> archived,
});

class $$ConversationsTableFilterComposer
    extends Composer<_$LocalDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$ConversationsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      Conversation,
      BaseReferences<_$LocalDatabase, $ConversationsTable, Conversation>
    ),
    Conversation,
    PrefetchHooks Function()> {
  $$ConversationsTableTableManager(
      _$LocalDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              ConversationsCompanion(
            id: id,
            title: title,
            modelId: modelId,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archived: archived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String modelId,
            Value<String?> systemPrompt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> archived = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            id: id,
            title: title,
            modelId: modelId,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archived: archived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConversationsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      Conversation,
      BaseReferences<_$LocalDatabase, $ConversationsTable, Conversation>
    ),
    Conversation,
    PrefetchHooks Function()>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  required int conversationId,
  required String role,
  required String content,
  required DateTime createdAt,
  Value<String?> generationMetricsJson,
  Value<int?> parentMessageId,
  Value<bool> archived,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<int> conversationId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<String?> generationMetricsJson,
  Value<int?> parentMessageId,
  Value<bool> archived,
});

class $$MessagesTableFilterComposer
    extends Composer<_$LocalDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generationMetricsJson => $composableBuilder(
      column: $table.generationMetricsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentMessageId => $composableBuilder(
      column: $table.parentMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$LocalDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generationMetricsJson => $composableBuilder(
      column: $table.generationMetricsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentMessageId => $composableBuilder(
      column: $table.parentMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get conversationId => $composableBuilder(
      column: $table.conversationId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get generationMetricsJson => $composableBuilder(
      column: $table.generationMetricsJson, builder: (column) => column);

  GeneratedColumn<int> get parentMessageId => $composableBuilder(
      column: $table.parentMessageId, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$LocalDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$LocalDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> conversationId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> generationMetricsJson = const Value.absent(),
            Value<int?> parentMessageId = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
            generationMetricsJson: generationMetricsJson,
            parentMessageId: parentMessageId,
            archived: archived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int conversationId,
            required String role,
            required String content,
            required DateTime createdAt,
            Value<String?> generationMetricsJson = const Value.absent(),
            Value<int?> parentMessageId = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
            generationMetricsJson: generationMetricsJson,
            parentMessageId: parentMessageId,
            archived: archived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$LocalDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;
typedef $$BenchmarksTableCreateCompanionBuilder = BenchmarksCompanion Function({
  Value<int> id,
  required String modelId,
  required String backend,
  required double ppTokPerSec,
  required double tgTokPerSec,
  required DateTime createdAt,
});
typedef $$BenchmarksTableUpdateCompanionBuilder = BenchmarksCompanion Function({
  Value<int> id,
  Value<String> modelId,
  Value<String> backend,
  Value<double> ppTokPerSec,
  Value<double> tgTokPerSec,
  Value<DateTime> createdAt,
});

class $$BenchmarksTableFilterComposer
    extends Composer<_$LocalDatabase, $BenchmarksTable> {
  $$BenchmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backend => $composableBuilder(
      column: $table.backend, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ppTokPerSec => $composableBuilder(
      column: $table.ppTokPerSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tgTokPerSec => $composableBuilder(
      column: $table.tgTokPerSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BenchmarksTableOrderingComposer
    extends Composer<_$LocalDatabase, $BenchmarksTable> {
  $$BenchmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backend => $composableBuilder(
      column: $table.backend, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ppTokPerSec => $composableBuilder(
      column: $table.ppTokPerSec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tgTokPerSec => $composableBuilder(
      column: $table.tgTokPerSec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BenchmarksTableAnnotationComposer
    extends Composer<_$LocalDatabase, $BenchmarksTable> {
  $$BenchmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get backend =>
      $composableBuilder(column: $table.backend, builder: (column) => column);

  GeneratedColumn<double> get ppTokPerSec => $composableBuilder(
      column: $table.ppTokPerSec, builder: (column) => column);

  GeneratedColumn<double> get tgTokPerSec => $composableBuilder(
      column: $table.tgTokPerSec, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BenchmarksTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $BenchmarksTable,
    Benchmark,
    $$BenchmarksTableFilterComposer,
    $$BenchmarksTableOrderingComposer,
    $$BenchmarksTableAnnotationComposer,
    $$BenchmarksTableCreateCompanionBuilder,
    $$BenchmarksTableUpdateCompanionBuilder,
    (Benchmark, BaseReferences<_$LocalDatabase, $BenchmarksTable, Benchmark>),
    Benchmark,
    PrefetchHooks Function()> {
  $$BenchmarksTableTableManager(_$LocalDatabase db, $BenchmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BenchmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BenchmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BenchmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<String> backend = const Value.absent(),
            Value<double> ppTokPerSec = const Value.absent(),
            Value<double> tgTokPerSec = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BenchmarksCompanion(
            id: id,
            modelId: modelId,
            backend: backend,
            ppTokPerSec: ppTokPerSec,
            tgTokPerSec: tgTokPerSec,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String modelId,
            required String backend,
            required double ppTokPerSec,
            required double tgTokPerSec,
            required DateTime createdAt,
          }) =>
              BenchmarksCompanion.insert(
            id: id,
            modelId: modelId,
            backend: backend,
            ppTokPerSec: ppTokPerSec,
            tgTokPerSec: tgTokPerSec,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BenchmarksTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $BenchmarksTable,
    Benchmark,
    $$BenchmarksTableFilterComposer,
    $$BenchmarksTableOrderingComposer,
    $$BenchmarksTableAnnotationComposer,
    $$BenchmarksTableCreateCompanionBuilder,
    $$BenchmarksTableUpdateCompanionBuilder,
    (Benchmark, BaseReferences<_$LocalDatabase, $BenchmarksTable, Benchmark>),
    Benchmark,
    PrefetchHooks Function()>;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$ModelEntriesTableTableManager get modelEntries =>
      $$ModelEntriesTableTableManager(_db, _db.modelEntries);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$BenchmarksTableTableManager get benchmarks =>
      $$BenchmarksTableTableManager(_db, _db.benchmarks);
}
