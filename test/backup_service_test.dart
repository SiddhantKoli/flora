import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/backup_service.dart';

void main() {
  Uint8List backup(
      {bool damaged = false, bool duplicate = false, bool v2 = false}) {
    final photoBytes = <int>[1, 2, 3, 4];
    final photo = {
      'base64': base64Encode(photoBytes),
      'sha256': damaged ? 'bad' : sha256.convert(photoBytes).toString(),
    };
    final data = {
      'format': 'flora-journal',
      'version': v2 ? 2 : 1,
      if (v2)
        'plants': [
          {
            'id': 'plant-one',
            'created_at': '2026-11-26T00:00:00Z',
            'species_id': null,
            'custom_name': 'Purple vine',
            'nickname': 'Balcony friend',
            'place_label': 'Balcony',
          }
        ],
      'observations': [
        {
          'id': 'one',
          if (v2) 'plant_id': 'plant-one',
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
    expect(preview.plantCount, 1);
  });

  test('new backup format links visits to personal plants', () {
    final preview = BackupService.instance.inspect(backup(v2: true));
    expect(preview.plantCount, 1);
    expect(preview.observationCount, 1);
  });

  test('profile preferences are included in version 3 previews', () {
    final data =
        jsonDecode(utf8.decode(backup(v2: true))) as Map<String, dynamic>;
    data['version'] = 3;
    data['preferences'] = {
      'display_name': 'Siddhant',
      'avatar': 'leaf',
      'large_text': true,
      'reduced_motion': false,
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    expect(BackupService.instance.inspect(bytes).includesPreferences, isTrue);
    (data['preferences'] as Map<String, dynamic>)['large_text'] = 'yes';
    final invalid = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    expect(
        () => BackupService.instance.inspect(invalid), throwsFormatException);
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
