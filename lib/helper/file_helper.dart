import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  Future<String> ensureFileOnDisk(String path) async {
    final f = File(path);
    if (await f.exists()) return f.path;

    // Versuche, es als Asset zu laden
    final ByteData data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();

    final ext = _extensionOf(path); // z.B. .wav
    final dir = await getTemporaryDirectory();
    final out =
        File('${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}$ext');
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }

  String _extensionOf(String p) {
    final dot = p.lastIndexOf('.');
    return dot >= 0 ? p.substring(dot) : '';
  }
}
