import 'package:flutter/services.dart' show rootBundle;

class VisemeHelper {
  /// Liest "('viseme_PP', 0.03, 0.07)"-Zeilen und erzeugt:
  /// [{'id':'viseme_PP','startSec':0.03,'endSec':0.07,'weight':0.9}, ...]
  Future<List<Map<String, dynamic>>> loadVisemesFromAsset(
    String assetPath, {
    double defaultWeight = 0.5,
  }) async {
    final content = await rootBundle.loadString(assetPath);

    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();

    // Match: ('viseme_XXX', 0.03, 0.07)
    final regex =
        RegExp(r"""\('([^']+)',\s*([0-9]*\.?[0-9]+),\s*([0-9]*\.?[0-9]+)\)""");

    final List<Map<String, dynamic>> result = [];
    for (final line in lines) {
      final m = regex.firstMatch(line);
      if (m == null) {
        // Optional: ignore or throw
        // debugPrint('Skipping unparsable viseme line: $line');
        continue;
      }
      final id = m.group(1)!;
      final start = double.parse(m.group(2)!);
      final end = double.parse(m.group(3)!);

      if (end <= start) {
        // debugPrint('Skipping invalid window [$start,$end) for $line');
        continue;
      }

      result.add({
        'id': id,
        'startSec': start,
        'endSec': end,
        'weight': defaultWeight,
      });
    }
    return result;
  }
}
