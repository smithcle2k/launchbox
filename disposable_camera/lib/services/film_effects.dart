import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Input for [applyFilmEffect]; kept as a single object so it can be sent to
/// a background isolate via `compute`.
class FilmEffectRequest {
  const FilmEffectRequest({
    required this.bytes,
    required this.takenAt,
    required this.seed,
  });

  final Uint8List bytes;
  final DateTime takenAt;
  final int seed;
}

/// Gives a captured JPEG the look of a cheap disposable film camera:
/// muted warm colors, grain, vignette, an occasional light leak, and the
/// classic orange date stamp in the corner.
Uint8List applyFilmEffect(FilmEffectRequest request) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(request.bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) return request.bytes;
  var image = img.bakeOrientation(decoded);

  // Disposable cameras were never sharp; cap resolution to keep the lo-fi
  // feel and make processing fast.
  const maxEdge = 1600;
  if (max(image.width, image.height) > maxEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxEdge)
        : img.copyResize(image, height: maxEdge);
  }

  final random = Random(request.seed);

  image = img.adjustColor(image, contrast: 1.08, saturation: 0.8, gamma: 0.97);
  image = img.colorOffset(image, red: 12, green: 3, blue: -10);
  image = img.noise(image, 16, type: img.NoiseType.gaussian, random: random);
  image = img.vignette(image, start: 0.55, end: 1.35, amount: 0.65);

  if (random.nextDouble() < 0.25) {
    _addLightLeak(image, random);
  }
  _stampDate(image, request.takenAt);

  return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}

/// A warm orange glow bleeding in from the left or right edge, as if the
/// camera back let in a sliver of light.
void _addLightLeak(img.Image image, Random random) {
  final cx = random.nextBool()
      ? image.width * (0.02 + random.nextDouble() * 0.12)
      : image.width * (0.86 + random.nextDouble() * 0.12);
  final cy = image.height * random.nextDouble();
  final radius = image.height * (0.35 + random.nextDouble() * 0.3);

  final minX = max(0, (cx - radius).floor());
  final maxX = min(image.width - 1, (cx + radius).ceil());
  final minY = max(0, (cy - radius).floor());
  final maxY = min(image.height - 1, (cy + radius).ceil());

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance >= radius) continue;
      final strength = pow(1 - distance / radius, 2) * 0.6;
      final pixel = image.getPixel(x, y);
      pixel.r = min(255, pixel.r + 210 * strength).toInt();
      pixel.g = min(255, pixel.g + 70 * strength).toInt();
      pixel.b = min(255, pixel.b + 25 * strength).toInt();
    }
  }
}

void _stampDate(img.Image image, DateTime takenAt) {
  final font = img.arial24;
  final text =
      "${takenAt.month} ${takenAt.day} '${(takenAt.year % 100).toString().padLeft(2, '0')}";
  final textWidth = _stringWidth(font, text);
  img.drawString(
    image,
    text,
    font: font,
    x: image.width - textWidth - 28,
    y: image.height - font.lineHeight - 22,
    color: img.ColorRgb8(255, 140, 40),
  );
}

int _stringWidth(img.BitmapFont font, String text) {
  var width = 0;
  for (final code in text.codeUnits) {
    final character = font.characters[code];
    width += character?.xAdvance ?? font.base ~/ 2;
  }
  return width;
}
