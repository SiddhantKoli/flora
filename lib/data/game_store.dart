import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'game_rules.dart';
import 'observation.dart';
import 'personal_plant.dart';
import 'species.dart';

class SaveResult {
  const SaveResult(
      {required this.observation,
      required this.xpEarned,
      required this.firstDiscovery,
      required this.duplicateImage});
  final Observation? observation;
  final int xpEarned;
  final bool firstDiscovery;
  final bool duplicateImage;
}

class GameSnapshot {
  const GameSnapshot(
      {required this.observations,
      required this.plants,
      required this.unlockedIds,
      required this.xp,
      required this.achievements,
      required this.dailyProgress,
      required this.weeklyProgress,
      required this.dailyClaimed,
      required this.weeklyClaimed});
  final List<Observation> observations;
  final List<PersonalPlant> plants;
  final Set<String> unlockedIds;
  final int xp;
  final Set<String> achievements;
  final int dailyProgress;
  final int weeklyProgress;
  final bool dailyClaimed;
  final bool weeklyClaimed;

  PersonalPlant? plantById(String? id) {
    for (final plant in plants) {
      if (plant.id == id) return plant;
    }
    return null;
  }
}

class GameStore {
  GameStore._();
  static final instance = GameStore._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final file = p.join(await getDatabasesPath(), 'flora.db');
    return _database =
        await openDatabase(file, version: 3, onCreate: (db, _) async {
      await db.execute(
          'CREATE TABLE personal_plants (id TEXT PRIMARY KEY, created_at TEXT NOT NULL, species_id TEXT, custom_name TEXT NOT NULL DEFAULT "", nickname TEXT NOT NULL DEFAULT "", place_label TEXT NOT NULL DEFAULT "")');
      await db.execute(
          'CREATE TABLE observations (id TEXT PRIMARY KEY, plant_id TEXT, image_path TEXT NOT NULL, image_hash TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL, local_day TEXT NOT NULL, local_week TEXT NOT NULL, species_id TEXT, status TEXT NOT NULL, notes TEXT NOT NULL DEFAULT "", reward_xp INTEGER NOT NULL DEFAULT 0)');
      await db.execute(
          'CREATE TABLE discoveries (species_id TEXT PRIMARY KEY, first_observation_id TEXT NOT NULL, discovered_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE rewards (key TEXT PRIMARY KEY, xp INTEGER NOT NULL, created_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE achievements (id TEXT PRIMARY KEY, unlocked_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE quest_claims (key TEXT PRIMARY KEY, claimed_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE observation_photos (id TEXT PRIMARY KEY, observation_id TEXT NOT NULL, image_path TEXT NOT NULL, image_hash TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
            'CREATE TABLE observation_photos (id TEXT PRIMARY KEY, observation_id TEXT NOT NULL, image_path TEXT NOT NULL, image_hash TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL)');
      }
      if (oldVersion < 3) {
        await db.execute(
            'CREATE TABLE personal_plants (id TEXT PRIMARY KEY, created_at TEXT NOT NULL, species_id TEXT, custom_name TEXT NOT NULL DEFAULT "", nickname TEXT NOT NULL DEFAULT "", place_label TEXT NOT NULL DEFAULT "")');
        await db.execute('ALTER TABLE observations ADD COLUMN plant_id TEXT');
        final oldVisits = await db
            .query('observations', columns: ['id', 'created_at', 'species_id']);
        for (final visit in oldVisits) {
          final plantId = const Uuid().v4();
          await db.insert('personal_plants', {
            'id': plantId,
            'created_at': visit['created_at'],
            'species_id': visit['species_id'],
            'custom_name': '',
            'nickname': '',
            'place_label': '',
          });
          await db.update('observations', {'plant_id': plantId},
              where: 'id = ?', whereArgs: [visit['id']]);
        }
      }
    });
  }

  String _day(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

  String _week(DateTime time) {
    final monday = DateTime(time.year, time.month, time.day)
        .subtract(Duration(days: time.weekday - 1));
    return _day(monday);
  }

  Future<GameSnapshot> snapshot() async {
    final db = await database;
    final now = DateTime.now();
    final rows = await db.query('observations', orderBy: 'created_at DESC');
    final plantRows = await db.query('personal_plants');
    final photoRows =
        await db.query('observation_photos', orderBy: 'created_at ASC');
    final photosByObservation = <String, List<String>>{};
    for (final photo in photoRows) {
      photosByObservation
          .putIfAbsent(photo['observation_id'] as String, () => [])
          .add(photo['image_path'] as String);
    }
    final discoveries = await db.query('discoveries', columns: ['species_id']);
    final rewards =
        await db.rawQuery('SELECT COALESCE(SUM(xp), 0) AS total FROM rewards');
    final achievements = await db.query('achievements', columns: ['id']);
    final daily = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM observations WHERE local_day = ? AND status = ? AND species_id IS NOT NULL',
        [_day(now), 'user_selected']);
    final weekly = await db.rawQuery(
        'SELECT COUNT(DISTINCT species_id) AS total FROM observations WHERE local_week = ? AND status = ? AND species_id IS NOT NULL',
        [_week(now), 'user_selected']);
    final claims = await db.query('quest_claims',
        where: 'key IN (?, ?)',
        whereArgs: ['daily:${_day(now)}', 'weekly:${_week(now)}']);
    final claimKeys = claims.map((row) => row['key'] as String).toSet();
    final observations = rows
        .map((row) => Observation.fromMap({
              ...row,
              'extra_image_paths': photosByObservation[row['id']] ?? <String>[],
            }))
        .toList();
    final visitsByPlant = <String, List<Observation>>{};
    for (final visit in observations) {
      final id = visit.plantId;
      if (id != null) visitsByPlant.putIfAbsent(id, () => []).add(visit);
    }
    final plants = plantRows
        .map((row) => PersonalPlant.fromMap(
            row, visitsByPlant[row['id']] ?? <Observation>[]))
        .toList()
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    return GameSnapshot(
      observations: observations,
      plants: plants,
      unlockedIds:
          discoveries.map((row) => row['species_id'] as String).toSet(),
      xp: (rewards.first['total'] as int?) ?? 0,
      achievements: achievements.map((row) => row['id'] as String).toSet(),
      dailyProgress: (daily.first['total'] as int?) ?? 0,
      weeklyProgress: (weekly.first['total'] as int?) ?? 0,
      dailyClaimed: claimKeys.contains('daily:${_day(now)}'),
      weeklyClaimed: claimKeys.contains('weekly:${_week(now)}'),
    );
  }

  Future<SaveResult> saveObservation(
      {required File source,
      String? plantId,
      String? speciesId,
      String customName = '',
      String nickname = '',
      String placeLabel = '',
      String notes = ''}) async {
    if (speciesId != null && speciesById(speciesId) == null)
      throw ArgumentError.value(speciesId, 'speciesId');
    if (customName.trim().length > 80 ||
        nickname.trim().length > 60 ||
        placeLabel.trim().length > 80 ||
        notes.trim().length > 500) {
      throw ArgumentError('A journal field is too long.');
    }
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) throw StateError('The selected photo is empty.');
    final hash = sha256.convert(bytes).toString();
    final db = await database;
    final existing = await db.query('observations',
        columns: ['id'], where: 'image_hash = ?', whereArgs: [hash], limit: 1);
    final attached = await db.query('observation_photos',
        columns: ['id'], where: 'image_hash = ?', whereArgs: [hash], limit: 1);
    if (existing.isNotEmpty || attached.isNotEmpty)
      return const SaveResult(
          observation: null,
          xpEarned: 0,
          firstDiscovery: false,
          duplicateImage: true);

    final now = DateTime.now();
    final id = const Uuid().v4();
    final targetPlantId = plantId ?? const Uuid().v4();
    var effectiveSpeciesId = speciesId;
    final directory = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'observations'));
    await directory.create(recursive: true);
    final image = File(
        p.join(directory.path, '$id${p.extension(source.path).toLowerCase()}'));
    await image.writeAsBytes(bytes, flush: true);
    var reward = 0;
    var first = false;
    try {
      await db.transaction((txn) async {
        if (plantId == null) {
          await txn.insert('personal_plants', {
            'id': targetPlantId,
            'created_at': now.toUtc().toIso8601String(),
            'species_id': speciesId,
            'custom_name': speciesId == null ? customName.trim() : '',
            'nickname': nickname.trim(),
            'place_label': placeLabel.trim(),
          });
        } else {
          final plantRows = await txn.query('personal_plants',
              columns: ['species_id'],
              where: 'id = ?',
              whereArgs: [plantId],
              limit: 1);
          if (plantRows.isEmpty) throw StateError('Plant no longer exists.');
          effectiveSpeciesId = plantRows.first['species_id'] as String?;
        }
        if (effectiveSpeciesId != null) {
          final found = await txn.query('discoveries',
              where: 'species_id = ?',
              whereArgs: [effectiveSpeciesId],
              limit: 1);
          first = found.isEmpty;
          final priorRepeat = await txn.query('observations',
              columns: ['id'],
              where: 'species_id = ? AND local_day = ? AND reward_xp = ?',
              whereArgs: [effectiveSpeciesId, _day(now), repeatObservationXp],
              limit: 1);
          reward = discoveryReward(
              firstDiscovery: first,
              rewardedRepeatToday: priorRepeat.isNotEmpty);
        }
        await txn.insert('observations', {
          'id': id,
          'plant_id': targetPlantId,
          'image_path': image.path,
          'image_hash': hash,
          'created_at': now.toUtc().toIso8601String(),
          'local_day': _day(now),
          'local_week': _week(now),
          'species_id': effectiveSpeciesId,
          'status': effectiveSpeciesId == null ? 'unknown' : 'user_selected',
          'notes': notes.trim(),
          'reward_xp': reward,
        });
        if (effectiveSpeciesId != null) {
          if (first)
            await txn.insert('discoveries', {
              'species_id': effectiveSpeciesId,
              'first_observation_id': id,
              'discovered_at': now.toUtc().toIso8601String()
            });
          if (reward > 0)
            await txn.insert('rewards', {
              'key': 'observation:$id',
              'xp': reward,
              'created_at': now.toUtc().toIso8601String()
            });
          final count = Sqflite.firstIntValue(
                  await txn.rawQuery('SELECT COUNT(*) FROM discoveries')) ??
              0;
          if (count >= 1)
            await txn.insert(
                'achievements',
                {
                  'id': 'first_discovery',
                  'unlocked_at': now.toUtc().toIso8601String()
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
          if (count >= 5)
            await txn.insert(
                'achievements',
                {
                  'id': 'five_species',
                  'unlocked_at': now.toUtc().toIso8601String()
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
    } catch (_) {
      if (await image.exists()) await image.delete();
      rethrow;
    }
    return SaveResult(
        observation: Observation(
            id: id,
            imagePath: image.path,
            createdAt: now.toUtc(),
            status: effectiveSpeciesId == null ? 'unknown' : 'user_selected',
            plantId: targetPlantId,
            speciesId: effectiveSpeciesId,
            notes: notes.trim()),
        xpEarned: reward,
        firstDiscovery: first,
        duplicateImage: false);
  }

  Future<int> claimQuest(String kind) async {
    if (kind != 'daily' && kind != 'weekly') throw ArgumentError.value(kind);
    final db = await database;
    final now = DateTime.now();
    final period = kind == 'daily' ? _day(now) : _week(now);
    final key = '$kind:$period';
    final target = kind == 'daily' ? 1 : 3;
    final reward = kind == 'daily' ? dailyQuestXp : weeklyQuestXp;
    return db.transaction((txn) async {
      final alreadyClaimed = await txn.query('quest_claims',
          columns: ['key'], where: 'key = ?', whereArgs: [key], limit: 1);
      if (alreadyClaimed.isNotEmpty) return 0;
      final count = kind == 'daily'
          ? Sqflite.firstIntValue(await txn.rawQuery(
                  'SELECT COUNT(*) FROM observations WHERE local_day = ? AND status = ?',
                  [
                    period,
                    'user_selected'
                  ])) ??
              0
          : Sqflite.firstIntValue(await txn.rawQuery(
                  'SELECT COUNT(DISTINCT species_id) FROM observations WHERE local_week = ? AND status = ?',
                  [period, 'user_selected'])) ??
              0;
      if (count < target) return 0;
      await txn.insert('quest_claims',
          {'key': key, 'claimed_at': now.toUtc().toIso8601String()});
      await txn.insert('rewards', {
        'key': 'quest:$key',
        'xp': reward,
        'created_at': now.toUtc().toIso8601String()
      });
      return reward;
    });
  }

  Future<void> updateNotes(String id, String notes) async {
    final db = await database;
    await db.update('observations', {'notes': notes.trim()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<String> addObservationPhoto(String observationId, File source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) throw StateError('The captured photo is empty.');
    final hash = sha256.convert(bytes).toString();
    final db = await database;
    final owner = await db.query('observations',
        columns: ['id'], where: 'id = ?', whereArgs: [observationId], limit: 1);
    if (owner.isEmpty) throw StateError('Observation no longer exists.');
    final matchingPrimary = await db.query('observations',
        columns: ['id'], where: 'image_hash = ?', whereArgs: [hash], limit: 1);
    final matchingExtra = await db.query('observation_photos',
        columns: ['id'], where: 'image_hash = ?', whereArgs: [hash], limit: 1);
    if (matchingPrimary.isNotEmpty || matchingExtra.isNotEmpty) {
      throw StateError('This photo is already in your journal.');
    }
    final id = const Uuid().v4();
    final directory = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'observations'));
    await directory.create(recursive: true);
    final file = File(
        p.join(directory.path, '$id${p.extension(source.path).toLowerCase()}'));
    await file.writeAsBytes(bytes, flush: true);
    try {
      await db.insert('observation_photos', {
        'id': id,
        'observation_id': observationId,
        'image_path': file.path,
        'image_hash': hash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
    return file.path;
  }

  Future<void> deleteObservationPhoto(
      String observationId, String imagePath) async {
    final db = await database;
    final rows = await db.query('observation_photos',
        columns: ['id'],
        where: 'observation_id = ? AND image_path = ?',
        whereArgs: [observationId, imagePath],
        limit: 1);
    if (rows.isEmpty) throw StateError('Photo no longer exists.');
    await db.delete('observation_photos',
        where: 'id = ?', whereArgs: [rows.first['id']]);
    final file = File(imagePath);
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The journal no longer references this photo.
    }
  }

  /// Correct a manual label without granting another discovery reward.
  /// Previously earned XP stays earned; the Plantdex follows current labels.
  Future<void> updateObservation(String id,
      {required String? speciesId, required String notes}) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('observations',
          columns: ['plant_id'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) throw StateError('Observation no longer exists.');
      await txn.update('observations', {'notes': notes.trim()},
          where: 'id = ?', whereArgs: [id]);
      final plantId = rows.first['plant_id'] as String?;
      if (plantId == null) return;
      final plants = await txn.query('personal_plants',
          where: 'id = ?', whereArgs: [plantId], limit: 1);
      if (plants.isEmpty) throw StateError('Plant no longer exists.');
      final plant = plants.first;
      await _writePlant(txn, plantId,
          speciesId: speciesId,
          customName: speciesId == null ? plant['custom_name'] as String : '',
          nickname: plant['nickname'] as String,
          placeLabel: plant['place_label'] as String);
    });
  }

  Future<void> updatePersonalPlant(String plantId,
      {required String? speciesId,
      required String customName,
      required String nickname,
      required String placeLabel}) async {
    final db = await database;
    await db.transaction((txn) => _writePlant(txn, plantId,
        speciesId: speciesId,
        customName: customName,
        nickname: nickname,
        placeLabel: placeLabel));
  }

  Future<void> _writePlant(Transaction txn, String plantId,
      {required String? speciesId,
      required String customName,
      required String nickname,
      required String placeLabel}) async {
    if (speciesId != null && speciesById(speciesId) == null) {
      throw ArgumentError.value(speciesId, 'speciesId');
    }
    if (customName.trim().length > 80 ||
        nickname.trim().length > 60 ||
        placeLabel.trim().length > 80) {
      throw ArgumentError('A plant label is too long.');
    }
    final rows = await txn.query('personal_plants',
        columns: ['species_id'],
        where: 'id = ?',
        whereArgs: [plantId],
        limit: 1);
    if (rows.isEmpty) throw StateError('Plant no longer exists.');
    final oldId = rows.first['species_id'] as String?;
    await txn.update(
        'personal_plants',
        {
          'species_id': speciesId,
          'custom_name': speciesId == null ? customName.trim() : '',
          'nickname': nickname.trim(),
          'place_label': placeLabel.trim(),
        },
        where: 'id = ?',
        whereArgs: [plantId]);
    if (oldId == speciesId) return;
    await txn.update(
        'observations',
        {
          'species_id': speciesId,
          'status': speciesId == null ? 'unknown' : 'user_selected',
        },
        where: 'plant_id = ?',
        whereArgs: [plantId]);
    if (oldId != null) await _reconcileDiscovery(txn, oldId);
    if (speciesId != null) {
      await _reconcileDiscovery(txn, speciesId);
      final count = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM discoveries')) ??
          0;
      final now = DateTime.now().toUtc().toIso8601String();
      if (count >= 1) {
        await txn.insert(
            'achievements', {'id': 'first_discovery', 'unlocked_at': now},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (count >= 5) {
        await txn.insert(
            'achievements', {'id': 'five_species', 'unlocked_at': now},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> _reconcileDiscovery(Transaction txn, String speciesId) async {
    final visits = await txn.query('observations',
        columns: ['id', 'created_at'],
        where: 'species_id = ?',
        whereArgs: [speciesId],
        orderBy: 'created_at ASC',
        limit: 1);
    if (visits.isEmpty) {
      await txn.delete('discoveries',
          where: 'species_id = ?', whereArgs: [speciesId]);
      return;
    }
    await txn.insert(
        'discoveries',
        {
          'species_id': speciesId,
          'first_observation_id': visits.first['id'],
          'discovered_at': visits.first['created_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteObservation(Observation observation) async {
    final db = await database;
    final photos = await db.query('observation_photos',
        columns: ['image_path'],
        where: 'observation_id = ?',
        whereArgs: [observation.id]);
    await db.transaction((txn) async {
      await txn.delete('observation_photos',
          where: 'observation_id = ?', whereArgs: [observation.id]);
      await txn
          .delete('observations', where: 'id = ?', whereArgs: [observation.id]);
      if (observation.plantId != null) {
        final remaining = await txn.query('observations',
            columns: ['id'],
            where: 'plant_id = ?',
            whereArgs: [observation.plantId],
            limit: 1);
        if (remaining.isEmpty) {
          await txn.delete('personal_plants',
              where: 'id = ?', whereArgs: [observation.plantId]);
        }
      }
    });
    for (final path in [
      observation.imagePath,
      ...photos.map((row) => row['image_path'] as String)
    ]) {
      final image = File(path);
      try {
        if (await image.exists()) await image.delete();
      } catch (_) {
        // The journal no longer references this photo.
      }
    }
  }
}
