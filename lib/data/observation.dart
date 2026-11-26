class Observation {
  const Observation({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.status,
    this.speciesId,
    this.notes = '',
    this.extraImagePaths = const [],
  });

  final String id;
  final String imagePath;
  final DateTime createdAt;
  final String status;
  final String? speciesId;
  final String notes;
  final List<String> extraImagePaths;

  List<String> get allImagePaths => [imagePath, ...extraImagePaths];

  bool get isConfirmed => status == 'user_selected' && speciesId != null;

  factory Observation.fromMap(Map<String, Object?> map) => Observation(
        id: map['id'] as String,
        imagePath: map['image_path'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: map['status'] as String,
        speciesId: map['species_id'] as String?,
        notes: map['notes'] as String? ?? '',
        extraImagePaths:
            (map['extra_image_paths'] as List<String>?) ?? const [],
      );
}
