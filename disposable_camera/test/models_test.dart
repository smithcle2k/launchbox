import 'package:disposable_camera/models/film_roll.dart';
import 'package:disposable_camera/models/photo.dart';
import 'package:flutter_test/flutter_test.dart';

Photo _photo({String id = 'p1', DateTime? developsAt}) => Photo(
      id: id,
      fileName: '$id.jpg',
      takenAt: DateTime(2026, 6, 10, 12),
      developsAt: developsAt ?? DateTime(2026, 6, 11, 9),
    );

void main() {
  group('Photo', () {
    test('is developed once developsAt has passed', () {
      expect(
        _photo(developsAt: DateTime.now().subtract(const Duration(minutes: 1)))
            .isDeveloped,
        isTrue,
      );
      expect(
        _photo(developsAt: DateTime.now().add(const Duration(hours: 1)))
            .isDeveloped,
        isFalse,
      );
    });

    test('timeUntilDeveloped never goes negative', () {
      final developed = _photo(
          developsAt: DateTime.now().subtract(const Duration(hours: 5)));
      expect(developed.timeUntilDeveloped, Duration.zero);
    });

    test('round-trips through JSON', () {
      final original = _photo();
      final copy = Photo.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.fileName, original.fileName);
      expect(copy.takenAt, original.takenAt);
      expect(copy.developsAt, original.developsAt);
    });
  });

  group('FilmRoll', () {
    test('counts shots and reports full', () {
      final roll = FilmRoll(id: 'r1', startedAt: DateTime(2026, 6, 10), capacity: 3);
      expect(roll.shotsLeft, 3);
      expect(roll.isFull, isFalse);

      roll.photos.addAll([_photo(id: 'a'), _photo(id: 'b'), _photo(id: 'c')]);
      expect(roll.shotsTaken, 3);
      expect(roll.shotsLeft, 0);
      expect(roll.isFull, isTrue);
    });

    test('splits developed vs developing counts', () {
      final roll = FilmRoll(id: 'r1', startedAt: DateTime(2026, 6, 10))
        ..photos.addAll([
          _photo(
              id: 'done',
              developsAt: DateTime.now().subtract(const Duration(days: 1))),
          _photo(
              id: 'pending',
              developsAt: DateTime.now().add(const Duration(days: 1))),
        ]);
      expect(roll.developedCount, 1);
      expect(roll.developingCount, 1);
    });

    test('round-trips through JSON', () {
      final original = FilmRoll(
        id: 'r1',
        startedAt: DateTime(2026, 6, 10, 8),
        capacity: 27,
      )..photos.add(_photo());
      final copy = FilmRoll.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.startedAt, original.startedAt);
      expect(copy.capacity, 27);
      expect(copy.photos, hasLength(1));
      expect(copy.photos.single.id, 'p1');
    });
  });
}
