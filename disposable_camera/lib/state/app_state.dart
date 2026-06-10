import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/film_roll.dart';
import '../models/photo.dart';
import '../services/develop_schedule.dart';
import '../services/film_effects.dart';
import '../services/storage_service.dart';

/// App-wide state: the list of film rolls (newest first), capture flow, and
/// the develop-speed setting.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  static const _developSpeedKey = 'develop_speed';

  final StorageService _storage;
  final List<FilmRoll> _rolls = [];
  DevelopSpeed _developSpeed = DevelopSpeed.nextMorning;
  bool _isProcessing = false;
  String _photosDirPath = '';

  List<FilmRoll> get rolls => List.unmodifiable(_rolls);
  DevelopSpeed get developSpeed => _developSpeed;

  /// True while a shot is being developed onto disk (shutter is disabled).
  bool get isProcessing => _isProcessing;

  /// The roll currently in the camera, or null if the latest roll is full.
  FilmRoll? get currentRoll =>
      _rolls.isNotEmpty && !_rolls.first.isFull ? _rolls.first : null;

  int get developingCount =>
      _rolls.fold(0, (sum, roll) => sum + roll.developingCount);

  Future<void> load() async {
    _photosDirPath = await _storage.photosDirPath();
    _rolls
      ..clear()
      ..addAll(await _storage.loadRolls());
    final prefs = await SharedPreferences.getInstance();
    final speedIndex = prefs.getInt(_developSpeedKey);
    if (speedIndex != null &&
        speedIndex >= 0 &&
        speedIndex < DevelopSpeed.values.length) {
      _developSpeed = DevelopSpeed.values[speedIndex];
    }
    if (_rolls.isEmpty) {
      await startNewRoll();
    }
    notifyListeners();
  }

  Future<void> startNewRoll() async {
    _rolls.insert(
      0,
      FilmRoll(id: _newId(), startedAt: DateTime.now()),
    );
    await _storage.saveRolls(_rolls);
    notifyListeners();
  }

  /// Processes [rawBytes] with the film effect and adds the exposure to the
  /// current roll. Returns the new photo, or null if the roll is full.
  Future<Photo?> capture(Uint8List rawBytes) async {
    final roll = currentRoll;
    if (roll == null || _isProcessing) return null;
    _isProcessing = true;
    notifyListeners();
    try {
      final takenAt = DateTime.now();
      final id = _newId();
      final processed = await compute(
        applyFilmEffect,
        FilmEffectRequest(bytes: rawBytes, takenAt: takenAt, seed: id.hashCode),
      );
      final photo = Photo(
        id: id,
        fileName: '$id.jpg',
        takenAt: takenAt,
        developsAt: developsAtFor(_developSpeed, takenAt),
      );
      await _storage.savePhotoBytes(photo.fileName, processed);
      roll.photos.add(photo);
      await _storage.saveRolls(_rolls);
      return photo;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String photoPath(Photo photo) => '$_photosDirPath/${photo.fileName}';

  Future<void> deletePhoto(Photo photo) async {
    for (final roll in _rolls) {
      roll.photos.removeWhere((p) => p.id == photo.id);
    }
    await _storage.deletePhotoFile(photo.fileName);
    await _storage.saveRolls(_rolls);
    notifyListeners();
  }

  Future<void> deleteRoll(FilmRoll roll) async {
    _rolls.removeWhere((r) => r.id == roll.id);
    for (final photo in roll.photos) {
      await _storage.deletePhotoFile(photo.fileName);
    }
    if (_rolls.isEmpty) {
      _rolls.insert(0, FilmRoll(id: _newId(), startedAt: DateTime.now()));
    }
    await _storage.saveRolls(_rolls);
    notifyListeners();
  }

  Future<void> setDevelopSpeed(DevelopSpeed speed) async {
    _developSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_developSpeedKey, speed.index);
    notifyListeners();
  }

  String _newId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(0xFFFFFF)}';
}
