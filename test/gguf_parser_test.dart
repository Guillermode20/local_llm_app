import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm_app/src/gguf/gguf_parser.dart';

void main() {
  group('GgufParser', () {
    test('parseBytes handles minimal GGUF v3 with known KVs', () {
      final data = _buildMinimalGguf();
      final result = GgufParser.parseBytes(data);

      expect(result.version, equals(3));
      expect(result.tensorCount, equals(0));
      expect(result.kvCount, equals(6));

      // General.architecture
      final arch = result['general.architecture'];
      expect(arch, isA<GgufStringValue>());
      expect((arch as GgufStringValue).value, equals('gemma3n'));

      // General.file_type = 15 (Q4_K_M)
      final fileType = result['general.file_type'];
      expect(fileType, isA<GgufNumericValue>());
      expect((fileType as GgufNumericValue).asInt, equals(15));

      // General.parameter_count
      final paramCount = result['general.parameter_count'];
      expect(paramCount, isA<GgufNumericValue>());
      expect((paramCount as GgufNumericValue).asInt, equals(4000000000));

      // gemma3n.context_length
      final ctxLen = result['gemma3n.context_length'];
      expect(ctxLen, isA<GgufNumericValue>());
      expect((ctxLen as GgufNumericValue).asInt, equals(4096));

      // gemma3n.block_count
      final blockCount = result['gemma3n.block_count'];
      expect(blockCount, isA<GgufNumericValue>());
      expect((blockCount as GgufNumericValue).asInt, equals(26));

      // tokenizer.chat_template
      final template = result['tokenizer.chat_template'];
      expect(template, isA<GgufStringValue>());
      expect(
        (template as GgufStringValue).value,
        contains('<start_of_turn>user'),
      );
    });

    test('throws on invalid magic bytes', () {
      final bogus = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
      expect(
        () => GgufParser.parseBytes(bogus),
        throwsA(isA<GgufFormatException>()),
      );
    });

    test('throws on truncated data', () {
      // Only header, no KV pairs when kv_count says there are
      final data = ByteData(24);
      data.setUint32(0, 0x46475547, Endian.little); // GGUF magic
      data.setUint32(4, 3, Endian.little); // version
      data.setUint64(8, 0, Endian.little); // tensor_count
      data.setUint64(16, 1, Endian.little); // kv_count = 1 but no data follows

      expect(
        () => GgufParser.parseBytes(data.buffer.asUint8List(0, 24)),
        throwsA(anything), // RangeError or GgufFormatException
      );
    });

    test('handles empty KV set', () {
      final data = ByteData(24);
      data.setUint32(0, 0x46475547, Endian.little);
      data.setUint32(4, 3, Endian.little);
      data.setUint64(8, 0, Endian.little);
      data.setUint64(16, 0, Endian.little);

      final result = GgufParser.parseBytes(data.buffer.asUint8List());
      expect(result.kvCount, equals(0));
      expect(result.pairs, isEmpty);
    });

    test('handles array values', () {
      // Build GGUF with a single array KV: test.array = [1, 2, 3] (uint32 array)
      // Header: 24 bytes
      // Key "test.array" (10 chars): 8 + 10 = 18 bytes
      // Value type: 4 bytes
      // Array: 4 (elem type) + 8 (count) + 3*4 (values) = 24 bytes
      // Total: 24 + 18 + 4 + 24 = 70
      final buffer = ByteData(70);
      var offset = 0;

      // Header
      buffer.setUint32(offset, 0x46475547, Endian.little);
      offset += 4;
      buffer.setUint32(offset, 3, Endian.little);
      offset += 4;
      buffer.setUint64(offset, 0, Endian.little); // tensor_count
      offset += 8;
      buffer.setUint64(offset, 1, Endian.little); // kv_count
      offset += 8;

      // Key: "test.array"
      const key = 'test.array';
      buffer.setUint64(offset, key.length, Endian.little);
      offset += 8;
      for (var i = 0; i < key.length; i++) {
        buffer.setUint8(offset + i, key.codeUnitAt(i));
      }
      offset += key.length;

      // Value type: array (9)
      buffer.setUint32(offset, 9, Endian.little);
      offset += 4;

      // Array: uint32 elements, count=3, values=[1, 2, 3]
      buffer.setUint32(offset, 4, Endian.little); // element type = uint32
      offset += 4;
      buffer.setUint64(offset, 3, Endian.little); // count
      offset += 8;
      buffer.setUint32(offset, 1, Endian.little);
      offset += 4;
      buffer.setUint32(offset, 2, Endian.little);
      offset += 4;
      buffer.setUint32(offset, 3, Endian.little);
      offset += 4;

      final result =
          GgufParser.parseBytes(buffer.buffer.asUint8List(0, offset));
      expect(result.kvCount, equals(1));

      final val = result['test.array'];
      expect(val, isA<GgufArrayValue>());
      final arr = val as GgufArrayValue;
      expect(arr.items.length, equals(3));
      expect((arr.items[0] as GgufNumericValue).asInt, equals(1));
      expect((arr.items[2] as GgufNumericValue).asInt, equals(3));
    });

    test('bool value parsing', () {
      // Build GGUF with a bool KV: test.flag = true
      // Header: 24 + Key "test.flag": 8+9=17 + Type: 4 + Value: 1 = 46
      const total = 24 + 8 + 9 + 4 + 1;
      final buffer = ByteData(total);
      var offset = 0;

      buffer.setUint32(offset, 0x46475547, Endian.little);
      offset += 4;
      buffer.setUint32(offset, 3, Endian.little);
      offset += 4;
      buffer.setUint64(offset, 0, Endian.little);
      offset += 8;
      buffer.setUint64(offset, 1, Endian.little);
      offset += 8;

      // Key: "test.flag"
      const key = 'test.flag';
      buffer.setUint64(offset, key.length, Endian.little);
      offset += 8;
      for (var i = 0; i < key.length; i++) {
        buffer.setUint8(offset + i, key.codeUnitAt(i));
      }
      offset += key.length;

      // Type: bool (7)
      buffer.setUint32(offset, 7, Endian.little);
      offset += 4;
      // Value: true (1)
      buffer.setUint8(offset, 1);
      offset += 1;

      final result =
          GgufParser.parseBytes(buffer.buffer.asUint8List(0, offset));
      final val = result['test.flag'];
      expect(val, isA<GgufNumericValue>());
      expect((val as GgufNumericValue).asBool, isTrue);
    });
  });
}

/// Builds a minimal GGUF v3 binary with known KVs matching Gemma 3n metadata.
Uint8List _buildMinimalGguf() {
  // Count up all bytes we need
  final kvs = <_GgufTestKv>[
    _GgufTestKv.string('general.architecture', 'gemma3n'),
    _GgufTestKv.uint32('general.file_type', 15),
    _GgufTestKv.uint64('general.parameter_count', 4000000000),
    _GgufTestKv.uint32('gemma3n.context_length', 4096),
    _GgufTestKv.uint32('gemma3n.block_count', 26),
    _GgufTestKv.string(
      'tokenizer.chat_template',
      '<bos><start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model\n',
    ),
  ];

  var totalSize = 24; // header
  for (final kv in kvs) {
    totalSize += 8 + kv.key.length; // key string
    totalSize += 4; // value type
    totalSize += kv.valueBytes.length; // value data
  }

  final buffer = ByteData(totalSize);
  var offset = 0;

  // Header
  buffer.setUint32(offset, 0x46475547, Endian.little);
  offset += 4;
  buffer.setUint32(offset, 3, Endian.little);
  offset += 4;
  buffer.setUint64(offset, 0, Endian.little); // tensor_count
  offset += 8;
  buffer.setUint64(offset, kvs.length, Endian.little); // kv_count
  offset += 8;

  // KV pairs
  for (final kv in kvs) {
    // Key
    buffer.setUint64(offset, kv.key.length, Endian.little);
    offset += 8;
    for (var i = 0; i < kv.key.length; i++) {
      buffer.setUint8(offset + i, kv.key.codeUnitAt(i));
    }
    offset += kv.key.length;

    // Value type
    buffer.setUint32(offset, kv.typeCode, Endian.little);
    offset += 4;

    // Value data
    buffer.buffer.asUint8List().setRange(
          offset,
          offset + kv.valueBytes.length,
          kv.valueBytes,
        );
    offset += kv.valueBytes.length;
  }

  return buffer.buffer.asUint8List(0, offset);
}

class _GgufTestKv {
  _GgufTestKv(this.key, this.typeCode, this.valueBytes);

  factory _GgufTestKv.string(String key, String value) {
    final encoded = _encodeString(value);
    return _GgufTestKv(key, 8, encoded); // 8 = GGUF_TYPE_STRING
  }

  factory _GgufTestKv.uint32(String key, int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return _GgufTestKv(key, 4, data.buffer.asUint8List()); // 4 = GGUF_TYPE_UINT32
  }

  factory _GgufTestKv.uint64(String key, int value) {
    final data = ByteData(8);
    data.setUint64(0, value, Endian.little);
    return _GgufTestKv(key, 10, data.buffer.asUint8List()); // 10 = GGUF_TYPE_UINT64
  }

  final String key;
  final int typeCode;
  final Uint8List valueBytes;

  static Uint8List _encodeString(String value) {
    final encoded = Uint8List.fromList(value.codeUnits);
    final buffer = ByteData(8 + encoded.length);
    buffer.setUint64(0, encoded.length, Endian.little);
    buffer.buffer.asUint8List().setRange(8, 8 + encoded.length, encoded);
    return buffer.buffer.asUint8List(0, 8 + encoded.length);
  }
}
