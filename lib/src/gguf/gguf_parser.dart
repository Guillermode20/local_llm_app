import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Pure-Dart GGUF v3 reader.
///
/// Reads only the header and metadata KV pairs — tensor data is skipped.
/// Throws [GgufFormatException] on invalid or unsupported files.
class GgufParser {
  GgufParser._();

  /// Parse a GGUF file from [path] and return all metadata KV pairs.
  static Future<GgufReaderResult> parseFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw GgufFormatException('File not found: $path');
    }
    final raf = await GgufFileReader.open(file);
    try {
      return await _parse(raf);
    } finally {
      await raf.close();
    }
  }

  /// Parse a GGUF file from an in-memory [data] buffer.
  static GgufReaderResult parseBytes(Uint8List data) {
    final view = ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
    return _parseFromView(view);
  }

  static Future<GgufReaderResult> _parse(GgufFileReader reader) async {
    final header = ByteData(24);
    await reader.readInto(header.buffer.asUint8List());

    final magic = header.getUint32(0, Endian.little);
    if (magic != _ggufMagic) {
      final magicBe = header.getUint32(0, Endian.big);
      if (magicBe == _ggufMagic) {
        throw GgufFormatException(
          'GGUF file is big-endian — only little-endian is supported',
        );
      }
      throw GgufFormatException(
        'Not a valid GGUF file (magic: 0x${magic.toRadixString(16)})',
      );
    }

    final version = header.getUint32(4, Endian.little);
    if (version < 3) {
      throw GgufFormatException(
        'GGUF version $version is not supported (v3+ required)',
      );
    }

    final tensorCount = header.getUint64(8, Endian.little);
    final kvCount = header.getUint64(16, Endian.little);

    final kvs = <GgufKvPair>[];
    var offset = 24;

    for (var i = 0; i < kvCount; i++) {
      final key = await _readString(reader, offset);
      offset += key.byteLength;

      final typeBytes = ByteData(4);
      await reader.readInto(typeBytes.buffer.asUint8List(), offset);
      final type = GgufValueType.fromValue(typeBytes.getUint32(0, Endian.little));
      offset += 4;

      final value = await _readValue(reader, type, offset);
      offset += value.byteLength;

      kvs.add(GgufKvPair(key: key.value, value: value));
    }

    return GgufReaderResult(
      version: version,
      tensorCount: tensorCount,
      kvCount: kvCount,
      pairs: kvs,
      headerSize: offset,
    );
  }

  static GgufReaderResult _parseFromView(ByteData view) {
    var offset = 0;

    final magic = view.getUint32(0, Endian.little);
    if (magic != _ggufMagic) {
      final magicBe = view.getUint32(0, Endian.big);
      if (magicBe == _ggufMagic) {
        throw GgufFormatException(
          'GGUF file is big-endian — only little-endian is supported',
        );
      }
      throw GgufFormatException(
        'Not a valid GGUF file (magic: 0x${magic.toRadixString(16)})',
      );
    }
    offset += 4;

    final version = view.getUint32(offset, Endian.little);
    offset += 4;
    if (version < 3) {
      throw GgufFormatException(
        'GGUF version $version is not supported (v3+ required)',
      );
    }

    final tensorCount = view.getUint64(offset, Endian.little);
    offset += 8;
    final kvCount = view.getUint64(offset, Endian.little);
    offset += 8;

    final kvs = <GgufKvPair>[];
    for (var i = 0; i < kvCount; i++) {
      final keyLen = view.getUint64(offset, Endian.little);
      offset += 8;
      final keyStr = utf8.decode(
        view.buffer.asUint8List(view.offsetInBytes + offset, keyLen),
      );
      offset += keyLen;

      final type = GgufValueType.fromValue(view.getUint32(offset, Endian.little));
      offset += 4;

      final value = _readValueFromView(view, type, offset);
      offset += value.byteLength;

      kvs.add(GgufKvPair(key: keyStr, value: value));
    }

    return GgufReaderResult(
      version: version,
      tensorCount: tensorCount,
      kvCount: kvCount,
      pairs: kvs,
      headerSize: offset,
    );
  }

  static Future<GgufStringValue> _readString(GgufFileReader reader, int offset) async {
    final lenBytes = ByteData(8);
    await reader.readInto(lenBytes.buffer.asUint8List(), offset);
    final length = lenBytes.getUint64(0, Endian.little);
    if (length > 1024 * 1024) {
      throw GgufFormatException('GGUF string length $length exceeds sanity limit');
    }
    final strBytes = Uint8List(length);
    await reader.readInto(strBytes, offset + 8);
    return GgufStringValue(utf8.decode(strBytes), byteLength: 8 + length);
  }

  static Future<GgufValue> _readValue(
    GgufFileReader reader,
    GgufValueType type,
    int offset,
  ) async {
    switch (type) {
      case GgufValueType.uint8:
        final b = ByteData(1);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getUint8(0), byteLength: 1);
      case GgufValueType.int8:
        final b = ByteData(1);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getInt8(0), byteLength: 1);
      case GgufValueType.uint16:
        final b = ByteData(2);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getUint16(0, Endian.little), byteLength: 2);
      case GgufValueType.int16:
        final b = ByteData(2);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getInt16(0, Endian.little), byteLength: 2);
      case GgufValueType.uint32:
        final b = ByteData(4);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getUint32(0, Endian.little), byteLength: 4);
      case GgufValueType.int32:
        final b = ByteData(4);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getInt32(0, Endian.little), byteLength: 4);
      case GgufValueType.float32:
        final b = ByteData(4);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getFloat32(0, Endian.little), byteLength: 4);
      case GgufValueType.bool_:
        final b = ByteData(1);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getUint8(0) != 0, byteLength: 1);
      case GgufValueType.string:
        return _readString(reader, offset);
      case GgufValueType.array: {
        final meta = ByteData(12);
        await reader.readInto(meta.buffer.asUint8List(), offset);
        final elemType = GgufValueType.fromValue(meta.getUint32(0, Endian.little));
        final count = meta.getUint64(4, Endian.little);
        var arrOffset = offset + 12;
        final items = <GgufValue>[];
        for (var i = 0; i < count; i++) {
          final item = await _readValue(reader, elemType, arrOffset);
          arrOffset += item.byteLength;
          items.add(item);
        }
        return GgufArrayValue(items, byteLength: arrOffset - offset);
      }
      case GgufValueType.uint64:
        final b = ByteData(8);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getUint64(0, Endian.little), byteLength: 8);
      case GgufValueType.int64:
        final b = ByteData(8);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getInt64(0, Endian.little), byteLength: 8);
      case GgufValueType.float64:
        final b = ByteData(8);
        await reader.readInto(b.buffer.asUint8List(), offset);
        return GgufNumericValue(b.getFloat64(0, Endian.little), byteLength: 8);
    }
  }

  static GgufValue _readValueFromView(ByteData view, GgufValueType type, int offset) {
    switch (type) {
      case GgufValueType.uint8:
        return GgufNumericValue(view.getUint8(offset), byteLength: 1);
      case GgufValueType.int8:
        return GgufNumericValue(view.getInt8(offset), byteLength: 1);
      case GgufValueType.uint16:
        return GgufNumericValue(view.getUint16(offset, Endian.little), byteLength: 2);
      case GgufValueType.int16:
        return GgufNumericValue(view.getInt16(offset, Endian.little), byteLength: 2);
      case GgufValueType.uint32:
        return GgufNumericValue(view.getUint32(offset, Endian.little), byteLength: 4);
      case GgufValueType.int32:
        return GgufNumericValue(view.getInt32(offset, Endian.little), byteLength: 4);
      case GgufValueType.float32:
        return GgufNumericValue(view.getFloat32(offset, Endian.little), byteLength: 4);
      case GgufValueType.bool_:
        return GgufNumericValue(view.getUint8(offset) != 0, byteLength: 1);
      case GgufValueType.string: {
        final len = view.getUint64(offset, Endian.little);
        final str = utf8.decode(
          view.buffer.asUint8List(view.offsetInBytes + offset + 8, len),
        );
        return GgufStringValue(str, byteLength: 8 + len);
      }
      case GgufValueType.array: {
        final elemType = GgufValueType.fromValue(view.getUint32(offset, Endian.little));
        final count = view.getUint64(offset + 4, Endian.little);
        var arrOffset = offset + 12;
        final items = <GgufValue>[];
        for (var i = 0; i < count; i++) {
          final item = _readValueFromView(view, elemType, arrOffset);
          arrOffset += item.byteLength;
          items.add(item);
        }
        return GgufArrayValue(items, byteLength: arrOffset - offset);
      }
      case GgufValueType.uint64:
        return GgufNumericValue(view.getUint64(offset, Endian.little), byteLength: 8);
      case GgufValueType.int64:
        return GgufNumericValue(view.getInt64(offset, Endian.little), byteLength: 8);
      case GgufValueType.float64:
        return GgufNumericValue(view.getFloat64(offset, Endian.little), byteLength: 8);
    }
  }

  static const _ggufMagic = 0x46475547;
}

/// Result of a GGUF file parse.
class GgufReaderResult {
  const GgufReaderResult({
    required this.version,
    required this.tensorCount,
    required this.kvCount,
    required this.pairs,
    required this.headerSize,
  });

  final int version;
  final int tensorCount;
  final int kvCount;
  final List<GgufKvPair> pairs;
  final int headerSize;

  GgufValue? operator [](String key) {
    for (final pair in pairs) {
      if (pair.key == key) return pair.value;
    }
    return null;
  }
}

/// A single GGUF metadata KV pair.
class GgufKvPair {
  const GgufKvPair({required this.key, required this.value});
  final String key;
  final GgufValue value;
}

/// GGUF value type enum (GGUF_TYPE_*).
enum GgufValueType {
  uint8(0),
  int8(1),
  uint16(2),
  int16(3),
  uint32(4),
  int32(5),
  float32(6),
  bool_(7),
  string(8),
  array(9),
  uint64(10),
  int64(11),
  float64(12);

  const GgufValueType(this.value);
  final int value;

  static GgufValueType fromValue(int v) {
    for (final t in values) {
      if (t.value == v) return t;
    }
    throw GgufFormatException('Unknown GGUF value type: $v');
  }
}

/// A parsed GGUF value.
sealed class GgufValue {
  const GgufValue({required this.byteLength});
  final int byteLength;
}

/// Numeric or boolean value.
class GgufNumericValue extends GgufValue {
  const GgufNumericValue(this.value, {required super.byteLength});
  final Object value;

  int get asInt => (value as num).toInt();
  double get asDouble => (value as num).toDouble();
  bool get asBool => value is bool ? (value as bool) : (value as num) != 0;
  String get asString => value.toString();

  @override
  String toString() => '$value';
}

/// String value.
class GgufStringValue extends GgufValue {
  const GgufStringValue(this.value, {required super.byteLength});
  final String value;

  @override
  String toString() => '"$value"';
}

/// Array value.
class GgufArrayValue extends GgufValue {
  const GgufArrayValue(this.items, {required super.byteLength});
  final List<GgufValue> items;

  @override
  String toString() => '[${items.join(', ')}]';
}

/// Exception thrown on GGUF parse errors.
class GgufFormatException implements Exception {
  GgufFormatException(this.message);
  final String message;

  @override
  String toString() => 'GgufFormatException: $message';
}

/// File reader that tracks absolute offset for [RandomAccessFile].
class GgufFileReader {
  GgufFileReader._(this._file, this._path);
  final RandomAccessFile _file;
  final String _path;
  int _position = 0;

  static Future<GgufFileReader> open(File file) async {
    final raf = await file.open(mode: FileMode.read);
    return GgufFileReader._(raf, file.path);
  }

  Future<void> readInto(Uint8List buffer, [int? offset]) async {
    if (offset != null && offset != _position) {
      _position = offset;
      await _file.setPosition(offset);
    }
    final bytesRead = await _file.readInto(buffer);
    _position += bytesRead;
    if (bytesRead < buffer.length) {
      throw GgufFormatException(
        'Unexpected end of file at $_path (offset $_position)',
      );
    }
  }

  Future<void> close() => _file.close();
}
