import 'package:disposable_camera/services/develop_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('developsAtFor', () {
    final takenAt = DateTime(2026, 6, 10, 14, 30);

    test('instant develops immediately', () {
      expect(developsAtFor(DevelopSpeed.instant, takenAt), takenAt);
    });

    test('oneHour develops an hour later', () {
      expect(
        developsAtFor(DevelopSpeed.oneHour, takenAt),
        DateTime(2026, 6, 10, 15, 30),
      );
    });

    test('nextMorning develops at 9 AM the next day', () {
      expect(
        developsAtFor(DevelopSpeed.nextMorning, takenAt),
        DateTime(2026, 6, 11, 9),
      );
    });

    test('nextMorning from an early-morning shot is still the next day', () {
      expect(
        developsAtFor(DevelopSpeed.nextMorning, DateTime(2026, 6, 10, 2, 15)),
        DateTime(2026, 6, 11, 9),
      );
    });

    test('nextMorning rolls over month boundaries', () {
      expect(
        developsAtFor(DevelopSpeed.nextMorning, DateTime(2026, 6, 30, 23, 59)),
        DateTime(2026, 7, 1, 9),
      );
    });
  });
}
