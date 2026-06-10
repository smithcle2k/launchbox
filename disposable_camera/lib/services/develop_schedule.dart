/// How long photos take to "develop" before they can be viewed.
enum DevelopSpeed { nextMorning, oneHour, instant }

extension DevelopSpeedLabel on DevelopSpeed {
  String get label => switch (this) {
        DevelopSpeed.nextMorning => 'Next morning at 9 AM',
        DevelopSpeed.oneHour => 'One hour',
        DevelopSpeed.instant => 'Instantly',
      };
}

/// Returns the moment a photo taken at [takenAt] becomes viewable.
DateTime developsAtFor(DevelopSpeed speed, DateTime takenAt) {
  switch (speed) {
    case DevelopSpeed.instant:
      return takenAt;
    case DevelopSpeed.oneHour:
      return takenAt.add(const Duration(hours: 1));
    case DevelopSpeed.nextMorning:
      // 9 AM on the day after the photo was taken, like film dropped off at
      // a one-hour photo lab that closes overnight.
      final nextDay =
          DateTime(takenAt.year, takenAt.month, takenAt.day).add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 9);
  }
}
