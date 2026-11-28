import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'game_store.dart';
import 'app_preferences.dart';
import 'species.dart';

class BackupPreview {
  const BackupPreview(this.observationCount, this.photoCount, this.plantCount,
      {this.includesPreferences = false});
  final int observationCount;
  final int photoCount;
  final int plantCount;
  final bool includesPreferences;
}

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  Future<Uint8List> createBackup() async {
    final db = await GameStore.instance.database;
    final plants = await db.query('personal_plants', orderBy: 'created_at');
    final observations = await db.query('observations', orderBy: 'created_at');
    final photos = await db.query('observation_photos', orderBy: 'created_at');
    final byObservation = <String, List<Map<String, Object?>>>{};
    for (final row in photos) {
      byObservation
          .putIfAbsent(row['observation_id'] as String, () => [])
          .add(row);
    }
    final entries = <Map<String, Object?>>[];
    for (final row in observations) {
      entries.add({
        'id': row['id'],
        'plant_id': row['plant_id'] ??
            (throw StateError(
                'A journal visit has no plant. Backup was not created.')),
        'created_at': row['created_at'],
        'local_day': row['local_day'],
        'local_week': row['local_week'],
        'species_id': row['species_id'],
        'status': row['status'],
        'notes': row['notes'],
        'reward_xp': row['reward_xp'],
        'photo': await _encodePhoto(row['image_path'] as String),
        'extra_photos': [
          for (final photo in byObservation[row['id']] ?? [])
            {
              'id': photo['id'],
              'created_at': photo['created_at'],
              'photo': await _encodePhoto(photo['image_path'] as String),
            }
        ],
      });
    }
    final backup = {
      'format': 'flora-journal',
      'version': 3,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'plants': [
        for (final row in plants)
          {
            'id': row['id'],
            'created_at': row['created_at'],
            'species_id': row['species_id'],
            'custom_name': row['custom_name'],
            'nickname': row['nickname'],
            'place_label': row['place_label'],
          }
      ],
      'observations': entries,
      'discoveries': await db.query('discoveries'),
      'rewards': await db.query('rewards'),
      'achievements': await db.query('achievements'),
      'quest_claims': await db.query('quest_claims'),
      'preferences': (await AppPreferencesStore.instance.load()).toJson(),
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));
    if (bytes.length > 200 * 1024 * 1024) {
      throw StateError('This journal is too large for a single backup file.');
    }
    return bytes;
  }

  Future<Map<String, String>> _encodePhoto(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('A journal photo is missing. Backup was not created.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw StateError('A journal photo is empty.');
    return {
      'base64': base64Encode(bytes),
      'sha256': sha256.convert(bytes).toString(),
    };
  }

  BackupPreview inspect(Uint8List bytes) {
    final data = _decode(bytes);
    final isV2 = data['version'] == 2 || data['version'] == 3;
    if (data['version'] == 3) _preferences(data['preferences']);
    final plantIds = <String>{};
    if (isV2) {
      for (final entry in _list(data, 'plants')) {
        final plant = _map(entry);
        final id = _string(plant, 'id');
        if (!plantIds.add(id)) {
          throw const FormatException('Duplicate plant in backup.');
        }
        _date(plant, 'created_at');
        final speciesId = plant['species_id'];
        if (speciesId != null &&
            (speciesId is! String || speciesById(speciesId) == null)) {
          throw const FormatException('Unknown catalog plant in backup.');
        }
        if (_string(plant, 'custom_name').length > 80 ||
            _string(plant, 'nickname').length > 60 ||
            _string(plant, 'place_label').length > 80) {
          throw const FormatException('A plant label is too long.');
        }
      }
    }
    var count = 0;
    final hashes = <String>{};
    final visitIds = <String>{};
    for (final entry in _list(data, 'observations')) {
      final row = _map(entry);
      _validateObservation(row);
      if (!visitIds.add(_string(row, 'id'))) {
        throw const FormatException('Duplicate visit in backup.');
      }
      if (isV2 && !plantIds.contains(_string(row, 'plant_id'))) {
        throw const FormatException('A visit has no matching plant.');
      }
      final primary = _photoBytes(row['photo'], hashes);
      if (primary.isEmpty) throw const FormatException('Empty photo.');
      count++;
      for (final extra in _list(row, 'extra_photos')) {
        final extraRow = _map(extra);
        _string(extraRow, 'id');
        _date(extraRow, 'created_at');
        _photoBytes(extraRow['photo'], hashes);
        count++;
      }
    }
    for (final row in _list(data, 'discoveries')) {
      final item = _map(row);
      _string(item, 'species_id');
      _string(item, 'first_observation_id');
      _date(item, 'discovered_at');
    }
    for (final row in _list(data, 'rewards')) {
      final item = _map(row);
      _string(item, 'key');
      _integer(item, 'xp');
      _date(item, 'created_at');
    }
    for (final row in _list(data, 'achievements')) {
      final item = _map(row);
      _string(item, 'id');
      _date(item, 'unlocked_at');
    }
    for (final row in _list(data, 'quest_claims')) {
      final item = _map(row);
      _string(item, 'key');
      _date(item, 'claimed_at');
    }
    return BackupPreview(_list(data, 'observations').length, count,
        isV2 ? plantIds.length : visitIds.length,
        includesPreferences: data['version'] == 3);
  }

  Future<BackupPreview> restore(Uint8List bytes) async {
    final preview = inspect(bytes);
    final data = _decode(bytes);
    final db = await GameStore.instance.database;
    final directory = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path,
        'observations',
        'restored-${const Uuid().v4()}'));
    await directory.create(recursive: true);
    final newObservations = <Map<String, Object?>>[];
    final newPhotos = <Map<String, Object?>>[];
    final newPlants = <Map<String, Object?>>[];
    AppPreferences? previousPreferences;
    var preferencesWritten = false;
    try {
      if (data['version'] == 2 || data['version'] == 3) {
        for (final entry in _list(data, 'plants')) {
          final row = _map(entry);
          newPlants.add({
            'id': _string(row, 'id'),
            'created_at': _string(row, 'created_at'),
            'species_id': row['species_id'],
            'custom_name': _string(row, 'custom_name'),
            'nickname': _string(row, 'nickname'),
            'place_label': _string(row, 'place_label'),
          });
        }
      }
      for (final entry in _list(data, 'observations')) {
        final row = _map(entry);
        final id = _string(row, 'id');
        final plantId =
            data['version'] != 1 ? _string(row, 'plant_id') : const Uuid().v4();
        if (data['version'] == 1) {
          newPlants.add({
            'id': plantId,
            'created_at': _string(row, 'created_at'),
            'species_id': row['species_id'],
            'custom_name': '',
            'nickname': '',
            'place_label': '',
          });
        }
        final primaryBytes = _photoBytes(row['photo'], null);
        final primaryPath = p.join(directory.path, '${const Uuid().v4()}.jpg');
        await File(primaryPath).writeAsBytes(primaryBytes, flush: true);
        newObservations.add({
          'id': id,
          'plant_id': plantId,
          'image_path': primaryPath,
          'image_hash': sha256.convert(primaryBytes).toString(),
          'created_at': _string(row, 'created_at'),
          'local_day': _string(row, 'local_day'),
          'local_week': _string(row, 'local_week'),
          'species_id': row['species_id'],
          'status': _string(row, 'status'),
          'notes': _string(row, 'notes'),
          'reward_xp': _integer(row, 'reward_xp'),
        });
        for (final extra in _list(row, 'extra_photos')) {
          final extraRow = _map(extra);
          final photoBytes = _photoBytes(extraRow['photo'], null);
          final path = p.join(directory.path, '${const Uuid().v4()}.jpg');
          await File(path).writeAsBytes(photoBytes, flush: true);
          newPhotos.add({
            'id': _string(extraRow, 'id'),
            'observation_id': id,
            'image_path': path,
            'image_hash': sha256.convert(photoBytes).toString(),
            'created_at': _string(extraRow, 'created_at'),
          });
        }
      }
      final oldObservations =
          await db.query('observations', columns: ['image_path']);
      final oldPhotos =
          await db.query('observation_photos', columns: ['image_path']);
      if (data['version'] == 3) {
        previousPreferences = await AppPreferencesStore.instance.load();
        await AppPreferencesStore.instance
            .save(_preferences(data['preferences']));
        preferencesWritten = true;
      }
      await db.transaction((txn) async {
        for (final table in [
          'observation_photos',
          'observations',
          'personal_plants',
          'discoveries',
          'rewards',
          'achievements',
          'quest_claims'
        ]) {
          await txn.delete(table);
        }
        for (final row in newPlants) {
          await txn.insert('personal_plants', row);
        }
        for (final row in newObservations) {
          await txn.insert('observations', row);
        }
        for (final row in newPhotos) {
          await txn.insert('observation_photos', row);
        }
        for (final spec in <(String, List<String>)>[
          (
            'discoveries',
            ['species_id', 'first_observation_id', 'discovered_at']
          ),
          ('rewards', ['key', 'xp', 'created_at']),
          ('achievements', ['id', 'unlocked_at']),
          ('quest_claims', ['key', 'claimed_at']),
        ]) {
          for (final entry in _list(data, spec.$1)) {
            final source = _map(entry);
            await txn.insert(spec.$1, {
              for (final column in spec.$2) column: source[column],
            });
          }
        }
      });
      for (final row in [...oldObservations, ...oldPhotos]) {
        final file = File(row['image_path'] as String);
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {
          // The restored journal is already committed; stale files can remain.
        }
      }
      return preview;
    } catch (_) {
      if (preferencesWritten && previousPreferences != null) {
        try {
          await AppPreferencesStore.instance.save(previousPreferences);
        } catch (_) {}
      }
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    }
  }

  Map<String, dynamic> _decode(Uint8List bytes) {
    if (bytes.length > 200 * 1024 * 1024) {
      throw const FormatException('Backup is larger than 200 MB.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    final data = _map(decoded);
    if (data['format'] != 'flora-journal' ||
        (data['version'] != 1 &&
            data['version'] != 2 &&
            data['version'] != 3)) {
      throw const FormatException('This is not a supported FLORA backup.');
    }
    return data;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup structure.');
    }
    return value;
  }

  AppPreferences _preferences(Object? value) {
    final row = _map(value);
    final name = row['display_name'];
    final avatar = row['avatar'];
    if (name is! String ||
        name.length > 40 ||
        avatar is! String ||
        avatar.length > 40 ||
        row['large_text'] is! bool ||
        row['reduced_motion'] is! bool ||
        (row.containsKey('haptics') && row['haptics'] is! bool) ||
        (row.containsKey('camera_sound') && row['camera_sound'] is! bool)) {
      throw const FormatException('Invalid profile preferences in backup.');
    }
    return AppPreferences.fromJson(row);
  }

  List<dynamic> _list(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! List) throw const FormatException('Invalid backup list.');
    return value;
  }

  String _string(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) throw const FormatException('Invalid backup field.');
    return value;
  }

  int _integer(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! int) throw const FormatException('Invalid backup number.');
    return value;
  }

  void _date(Map<String, dynamic> row, String key) {
    if (DateTime.tryParse(_string(row, key)) == null) {
      throw const FormatException('Invalid backup date.');
    }
  }

  void _validateObservation(Map<String, dynamic> row) {
    _string(row, 'id');
    _date(row, 'created_at');
    _string(row, 'local_day');
    _string(row, 'local_week');
    final speciesId = row['species_id'];
    if (speciesId != null &&
        (speciesId is! String || speciesById(speciesId) == null)) {
      throw const FormatException('Backup includes an unknown catalog entry.');
    }
    final status = _string(row, 'status');
    if (status != (speciesId == null ? 'unknown' : 'user_selected')) {
      throw const FormatException('Invalid plant selection in backup.');
    }
    if (_string(row, 'notes').length > 500) {
      throw const FormatException('A note is too long.');
    }
    _integer(row, 'reward_xp');
  }

  Uint8List _photoBytes(Object? value, Set<String>? hashes) {
    final photo = _map(value);
    final bytes = base64Decode(_string(photo, 'base64'));
    if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('Invalid photo size in backup.');
    }
    final hash = sha256.convert(bytes).toString();
    if (hash != _string(photo, 'sha256') ||
        (hashes != null && !hashes.add(hash))) {
      throw const FormatException('A backup photo is damaged or duplicated.');
    }
    return bytes;
  }
}
