import 'observation.dart';
import 'species.dart';

/// A particular plant the user follows. Visits are dated observations.
class PersonalPlant {
  const PersonalPlant({
    required this.id,
    required this.createdAt,
    required this.visits,
    this.speciesId,
    this.customName = '',
    this.nickname = '',
    this.placeLabel = '',
  });

  final String id;
  final DateTime createdAt;
  final String? speciesId;
  final String customName;
  final String nickname;
  final String placeLabel;
  final List<Observation> visits;

  String get plantLabel {
    final catalogName = speciesById(speciesId)?.commonName;
    if (catalogName != null) return catalogName;
    if (customName.trim().isNotEmpty) return customName.trim();
    return 'Unknown plant';
  }

  String get displayName =>
      nickname.trim().isNotEmpty ? nickname.trim() : plantLabel;

  String get labelDetail =>
      nickname.trim().isNotEmpty ? plantLabel : 'Your field journal';

  Observation? get latestVisit => visits.isEmpty ? null : visits.first;

  DateTime get lastSeenAt => latestVisit?.createdAt ?? createdAt;

  bool get hasCatalogName => speciesById(speciesId) != null;

  PersonalPlant copyWith({
    String? speciesId,
    bool clearSpecies = false,
    String? customName,
    String? nickname,
    String? placeLabel,
    List<Observation>? visits,
  }) =>
      PersonalPlant(
        id: id,
        createdAt: createdAt,
        speciesId: clearSpecies ? null : speciesId ?? this.speciesId,
        customName: customName ?? this.customName,
        nickname: nickname ?? this.nickname,
        placeLabel: placeLabel ?? this.placeLabel,
        visits: visits ?? this.visits,
      );

  factory PersonalPlant.fromMap(
          Map<String, Object?> row, List<Observation> visits) =>
      PersonalPlant(
        id: row['id'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        speciesId: row['species_id'] as String?,
        customName: row['custom_name'] as String? ?? '',
        nickname: row['nickname'] as String? ?? '',
        placeLabel: row['place_label'] as String? ?? '',
        visits: visits,
      );
}
