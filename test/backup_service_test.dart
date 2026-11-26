import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/backup_service.dart';

void main() {
  Uint8List backup({bool damaged = false, bool duplicate = false}) {
    final photoBytes = <int>[1, 2, 3, 4];
    final photo = {
      'base64': base64Encode(photoBytes),
      'sha256': damaged ? 'bad' : sha256.convert(photoBytes).toString(),
    };
    final data = {
      'format': 'flora-journal',
      'version': 1,
      'observations': [
        {
          'id': 'one',
          'created_at': '2026-11-26T00:00:00Z',
          'local_day': '2026-11-26',
          'local_week': '2026-11-23',
          'species_id': null,
          'status': 'unknown',
          'notes': '',
          'reward_xp': 0,
          'photo': photo,
          'extra_photos': duplicate
              ? [
                  {
                    'id': 'two',
                    'created_at': '2026-11-26T00:00:01Z',
                    'photo': photo,
                  }
                ]
              : [],
        }
      ],
      'discoveries': [],
      'rewards': [],
      'achievements': [],
      'quest_claims': [],
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  test('backup inspection counts entries and photos', () {
    final preview = BackupService.instance.inspect(backup());
    expect(preview.observationCount, 1);
    expect(preview.photoCount, 1);
  });

  test('backup inspection rejects damaged photo bytes', () {
    expect(() => BackupService.instance.inspect(backup(damaged: true)),
        throwsFormatException);
  });

  test('backup inspection rejects duplicate photos', () {
    expect(() => BackupService.instance.inspect(backup(duplicate: true)),
        throwsFormatException);
  });
}
