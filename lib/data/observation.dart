class Observation {
  const Observation({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.status,
    this.speciesId,
    this.notes = '',
  });

  final String id;
  final String imagePath;
  final DateTime createdAt;
  final String status;
  final String? speciesId;
  final String notes;

  bool get isConfirmed => status == 'user_selected' && speciesId != null;

  factory Observation.fromMap(Map<String, Object?> map) => Observation(
        id: map['id'] as String,
        imagePath: map['image_path'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: map['status'] as String,
        speciesId: map['species_id'] as String?,
        notes: map['notes'] as String? ?? '',
      );
}
