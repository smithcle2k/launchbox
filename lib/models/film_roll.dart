import 'photo.dart';

/// A roll of film with a fixed number of exposures.
class FilmRoll {
  FilmRoll({
    required this.id,
    required this.startedAt,
    this.capacity = 24,
    List<Photo>? photos,
  }) : photos = photos ?? [];

  final String id;
  final DateTime startedAt;
  final int capacity;
  final List<Photo> photos;

  int get shotsTaken => photos.length;
  int get shotsLeft => capacity - photos.length;
  bool get isFull => shotsLeft <= 0;

  int get developedCount => photos.where((p) => p.isDeveloped).length;
  int get developingCount => photos.length - developedCount;

  factory FilmRoll.fromJson(Map<String, dynamic> json) => FilmRoll(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        capacity: json['capacity'] as int? ?? 24,
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((p) => Photo.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'capacity': capacity,
        'photos': photos.map((p) => p.toJson()).toList(),
      };
}
