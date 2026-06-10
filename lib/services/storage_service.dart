import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/film_roll.dart';

/// Persists rolls as a JSON index plus one JPEG file per photo, all under the
/// app documents directory.
class StorageService {
  Directory? _baseDir;

  Future<Directory> _ensureBaseDir() async {
    if (_baseDir != null) return _baseDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/disposable_camera');
    await dir.create(recursive: true);
    _baseDir = dir;
    return dir;
  }

  Future<File> _indexFile() async =>
      File('${(await _ensureBaseDir()).path}/rolls.json');

  Future<Directory> _photosDir() async {
    final dir = Directory('${(await _ensureBaseDir()).path}/photos');
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<FilmRoll>> loadRolls() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded
          .map((r) => FilmRoll.fromJson(r as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> saveRolls(List<FilmRoll> rolls) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(rolls.map((r) => r.toJson()).toList()));
  }

  Future<File> savePhotoBytes(String fileName, Uint8List bytes) async {
    final file = File('${(await _photosDir()).path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> photoFile(String fileName) async =>
      File('${(await _photosDir()).path}/$fileName');

  Future<String> photosDirPath() async => (await _photosDir()).path;

  Future<void> deletePhotoFile(String fileName) async {
    final file = await photoFile(fileName);
    if (await file.exists()) await file.delete();
  }
}
