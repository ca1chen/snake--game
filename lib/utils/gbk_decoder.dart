import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;

/// GBK→Unicode decoder for TJU course file parsing.
///
/// The lookup table (~54 KB base64) is loaded from assets on first use
/// instead of being compiled inline, keeping the source file compact.
class GbkDecoder {
  static Uint16List? _table;

  /// Load the GBK lookup table from assets. Call once before [decode].
  /// Subsequent calls are no-ops.
  static Future<void> ensureInitialized() async {
    if (_table != null) return;
    final b64 = await rootBundle.loadString('assets/gbk_table.txt');
    final bytes = base64Decode(b64.trim());
    final decompressed = Uint8List.fromList(ZLibDecoder().decodeBytes(bytes));
    _table = decompressed.buffer.asUint16List();
  }

  /// Decode GBK bytes to a Dart [String].
  /// Must call [ensureInitialized] first.
  static String decode(List<int> gbkBytes) {
    final table = _table!; // caller guarantees initialization
    final buf = StringBuffer();
    int i = 0;
    while (i < gbkBytes.length) {
      final b1 = gbkBytes[i];
      if (b1 < 0x80) {
        buf.writeCharCode(b1);
        i++;
      } else if (b1 >= 0x81 && b1 <= 0xFE && i + 1 < gbkBytes.length) {
        final b2 = gbkBytes[i + 1];
        if ((b2 >= 0x40 && b2 <= 0x7E) || (b2 >= 0x80 && b2 <= 0xFE)) {
          final idx = (b1 - 0x81) * 190 + (b2 - 0x40) - (b2 > 0x7E ? 1 : 0);
          final uni = table[idx];
          buf.writeCharCode(uni > 0 ? uni : 0xFFFD);
          i += 2;
        } else {
          buf.writeCharCode(0xFFFD);
          i++;
        }
      } else {
        buf.writeCharCode(0xFFFD);
        i++;
      }
    }
    return buf.toString();
  }
}
