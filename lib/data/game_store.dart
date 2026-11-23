import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'game_rules.dart';
import 'observation.dart';
import 'species.dart';

class SaveResult {
  const SaveResult({required this.observation, required this.xpEarned, required this.firstDiscovery, required this.duplicateImage});
  final Observation? observation;
  final int xpEarned;
  final bool firstDiscovery;
  final bool duplicateImage;
}

class GameSnapshot {
  const GameSnapshot({required this.observations, required this.unlockedIds, required this.xp, required this.achievements, required this.dailyProgress, required this.weeklyProgress, required this.dailyClaimed, required this.weeklyClaimed});
  final List<Observation> observations;
  final Set<String> unlockedIds;
  final int xp;
  final Set<String> achievements;
  final int dailyProgress;
  final int weeklyProgress;
  final bool dailyClaimed;
  final bool weeklyClaimed;
}

class GameStore {
  GameStore._();
  static final instance = GameStore._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final file = p.join(await getDatabasesPath(), 'flora.db');
    return _database = await openDatabase(file, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE observations (id TEXT PRIMARY KEY, image_path TEXT NOT NULL, image_hash TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL, local_day TEXT NOT NULL, local_week TEXT NOT NULL, species_id TEXT, status TEXT NOT NULL, notes TEXT NOT NULL DEFAULT "", reward_xp INTEGER NOT NULL DEFAULT 0)');
      await db.execute('CREATE TABLE discoveries (species_id TEXT PRIMARY KEY, first_observation_id TEXT NOT NULL, discovered_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE rewards (key TEXT PRIMARY KEY, xp INTEGER NOT NULL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE achievements (id TEXT PRIMARY KEY, unlocked_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE quest_claims (key TEXT PRIMARY KEY, claimed_at TEXT NOT NULL)');
    });
  }

  String _day(DateTime time) => '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

  String _week(DateTime time) {
    final monday = DateTime(time.year, time.month, time.day).subtract(Duration(days: time.weekday - 1));
    return _day(monday);
  }

  Future<GameSnapshot> snapshot() async {
    final db = await database;
    final now = DateTime.now();
    final rows = await db.query('observations', orderBy: 'created_at DESC');
    final discoveries = await db.query('discoveries', columns: ['species_id']);
    final rewards = await db.rawQuery('SELECT COALESCE(SUM(xp), 0) AS total FROM rewards');
    final achievements = await db.query('achievements', columns: ['id']);
    final daily = await db.rawQuery('SELECT COUNT(*) AS total FROM observations WHERE local_day = ? AND status = ? AND species_id IS NOT NULL', [_day(now), 'user_selected']);
    final weekly = await db.rawQuery('SELECT COUNT(DISTINCT species_id) AS total FROM observations WHERE local_week = ? AND status = ? AND species_id IS NOT NULL', [_week(now), 'user_selected']);
    final claims = await db.query('quest_claims', where: 'key IN (?, ?)', whereArgs: ['daily:${_day(now)}', 'weekly:${_week(now)}']);
    final claimKeys = claims.map((row) => row['key'] as String).toSet();
    return GameSnapshot(
      observations: rows.map(Observation.fromMap).toList(),
      unlockedIds: discoveries.map((row) => row['species_id'] as String).toSet(),
      xp: (rewards.first['total'] as int?) ?? 0,
      achievements: achievements.map((row) => row['id'] as String).toSet(),
      dailyProgress: (daily.first['total'] as int?) ?? 0,
      weeklyProgress: (weekly.first['total'] as int?) ?? 0,
      dailyClaimed: claimKeys.contains('daily:${_day(now)}'),
      weeklyClaimed: claimKeys.contains('weekly:${_week(now)}'),
    );
  }

  Future<SaveResult> saveObservation({required File source, String? speciesId, String notes = ''}) async {
    if (speciesId != null && speciesById(speciesId) == null) throw ArgumentError.value(speciesId, 'speciesId');
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) throw StateError('The selected photo is empty.');
    final hash = sha256.convert(bytes).toString();
    final db = await database;
    final existing = await db.query('observations', columns: ['id'], where: 'image_hash = ?', whereArgs: [hash], limit: 1);
    if (existing.isNotEmpty) return const SaveResult(observation: null, xpEarned: 0, firstDiscovery: false, duplicateImage: true);

    final now = DateTime.now();
    final id = const Uuid().v4();
    final directory = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'observations'));
    await directory.create(recursive: true);
    final image = File(p.join(directory.path, '$id${p.extension(source.path).toLowerCase()}'));
    await image.writeAsBytes(bytes, flush: true);
    var reward = 0;
    var first = false;
    try {
      await db.transaction((txn) async {
        if (speciesId != null) {
          final found = await txn.query('discoveries', where: 'species_id = ?', whereArgs: [speciesId], limit: 1);
          first = found.isEmpty;
          final priorRepeat = await txn.query('observations', columns: ['id'], where: 'species_id = ? AND local_day = ? AND reward_xp = ?', whereArgs: [speciesId, _day(now), repeatObservationXp], limit: 1);
          reward = discoveryReward(firstDiscovery: first, rewardedRepeatToday: priorRepeat.isNotEmpty);
        }
        await txn.insert('observations', {
          'id': id, 'image_path': image.path, 'image_hash': hash,
          'created_at': now.toUtc().toIso8601String(), 'local_day': _day(now), 'local_week': _week(now),
          'species_id': speciesId, 'status': speciesId == null ? 'unknown' : 'user_selected',
          'notes': notes.trim(), 'reward_xp': reward,
        });
        if (speciesId != null) {
          if (first) await txn.insert('discoveries', {'species_id': speciesId, 'first_observation_id': id, 'discovered_at': now.toUtc().toIso8601String()});
          if (reward > 0) await txn.insert('rewards', {'key': 'observation:$id', 'xp': reward, 'created_at': now.toUtc().toIso8601String()});
          final count = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM discoveries')) ?? 0;
          if (count >= 1) await txn.insert('achievements', {'id': 'first_discovery', 'unlocked_at': now.toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.ignore);
          if (count >= 5) await txn.insert('achievements', {'id': 'five_species', 'unlocked_at': now.toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
    } catch (_) {
      if (await image.exists()) await image.delete();
      rethrow;
    }
    return SaveResult(observation: Observation(id: id, imagePath: image.path, createdAt: now.toUtc(), status: speciesId == null ? 'unknown' : 'user_selected', speciesId: speciesId, notes: notes.trim()), xpEarned: reward, firstDiscovery: first, duplicateImage: false);
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
      final alreadyClaimed = await txn.query('quest_claims', columns: ['key'], where: 'key = ?', whereArgs: [key], limit: 1);
      if (alreadyClaimed.isNotEmpty) return 0;
      final count = kind == 'daily'
          ? Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM observations WHERE local_day = ? AND status = ?', [period, 'user_selected'])) ?? 0
          : Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(DISTINCT species_id) FROM observations WHERE local_week = ? AND status = ?', [period, 'user_selected'])) ?? 0;
      if (count < target) return 0;
      await txn.insert('quest_claims', {'key': key, 'claimed_at': now.toUtc().toIso8601String()});
      await txn.insert('rewards', {'key': 'quest:$key', 'xp': reward, 'created_at': now.toUtc().toIso8601String()});
      return reward;
    });
  }

  Future<void> updateNotes(String id, String notes) async {
    final db = await database;
    await db.update('observations', {'notes': notes.trim()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteObservation(Observation observation) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [observation.id]);
    final image = File(observation.imagePath);
    if (await image.exists()) await image.delete();
  }
}
