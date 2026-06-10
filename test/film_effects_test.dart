import 'dart:typed_data';

import 'package:disposable_camera/services/film_effects.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  Uint8List makeTestJpeg(int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(120, 140, 160));
    return Uint8List.fromList(img.encodeJpg(image));
  }

  test('produces a decodable JPEG capped at 1600px on the long edge', () {
    final output = applyFilmEffect(FilmEffectRequest(
      bytes: makeTestJpeg(3200, 2400),
      takenAt: DateTime(2026, 6, 10, 14, 30),
      seed: 42,
    ));
    final decoded = img.decodeImage(output);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1600);
    expect(decoded.height, 1200);
  });

  test('keeps small images at their original size', () {
    final output = applyFilmEffect(FilmEffectRequest(
      bytes: makeTestJpeg(400, 300),
      takenAt: DateTime(2026, 6, 10, 14, 30),
      seed: 7,
    ));
    final decoded = img.decodeImage(output);
    expect(decoded!.width, 400);
    expect(decoded.height, 300);
  });

  test('is deterministic for the same seed', () {
    final request = FilmEffectRequest(
      bytes: makeTestJpeg(200, 150),
      takenAt: DateTime(2026, 6, 10),
      seed: 99,
    );
    expect(applyFilmEffect(request), applyFilmEffect(request));
  });

  test('returns input unchanged when bytes are not an image', () {
    final junk = Uint8List.fromList([1, 2, 3, 4]);
    expect(
      applyFilmEffect(
          FilmEffectRequest(bytes: junk, takenAt: DateTime(2026), seed: 1)),
      junk,
    );
  });
}
