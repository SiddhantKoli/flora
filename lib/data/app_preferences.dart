import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPreferences {
  const AppPreferences(
      {this.displayName = '',
      this.avatar = 'leaf',
      this.largeText = false,
      this.reducedMotion = false,
      this.haptics = true,
      this.cameraSound = false});

  final String displayName;
  final String avatar;
  final bool largeText;
  final bool reducedMotion;
  final bool haptics;
  final bool cameraSound;

  AppPreferences copyWith(
          {String? displayName,
          String? avatar,
          bool? largeText,
          bool? reducedMotion,
          bool? haptics,
          bool? cameraSound}) =>
      AppPreferences(
        displayName: displayName ?? this.displayName,
        avatar: avatar ?? this.avatar,
        largeText: largeText ?? this.largeText,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        haptics: haptics ?? this.haptics,
        cameraSound: cameraSound ?? this.cameraSound,
      );

  Map<String, Object> toJson() => {
        'display_name': displayName,
        'avatar': avatar,
        'large_text': largeText,
        'reduced_motion': reducedMotion,
        'haptics': haptics,
        'camera_sound': cameraSound,
      };

  static AppPreferences fromJson(Map<String, dynamic> data) => AppPreferences(
        displayName: (data['display_name'] as String? ?? '').trim(),
        avatar: data['avatar'] as String? ?? 'leaf',
        largeText: data['large_text'] == true,
        reducedMotion: data['reduced_motion'] == true,
        haptics: data['haptics'] != false,
        cameraSound: data['camera_sound'] == true,
      );
}

class AppPreferencesStore {
  AppPreferencesStore._();
  static final instance = AppPreferencesStore._();

  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'preferences.json'));
  }

  Future<AppPreferences> load() async {
    final file = await _file;
    if (!await file.exists()) return const AppPreferences();
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is Map<String, dynamic>) return AppPreferences.fromJson(data);
    } catch (_) {
      // Keep the journal usable if the optional display preferences are damaged.
    }
    return const AppPreferences();
  }

  Future<void> save(AppPreferences preferences) async {
    if (preferences.displayName.length > 40) {
      throw ArgumentError('Display name is too long.');
    }
    final file = await _file;
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(preferences.toJson()), flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}
