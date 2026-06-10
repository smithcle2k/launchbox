/// A single exposure on a film roll.
///
/// A photo is captured immediately but only becomes viewable once it has
/// "developed" (after [developsAt]).
class Photo {
  Photo({
    required this.id,
    required this.fileName,
    required this.takenAt,
    required this.developsAt,
  });

  final String id;
  final String fileName;
  final DateTime takenAt;
  final DateTime developsAt;

  bool get isDeveloped => !DateTime.now().isBefore(developsAt);

  Duration get timeUntilDeveloped {
    final remaining = developsAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        takenAt: DateTime.parse(json['takenAt'] as String),
        developsAt: DateTime.parse(json['developsAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'takenAt': takenAt.toIso8601String(),
        'developsAt': developsAt.toIso8601String(),
      };
}
