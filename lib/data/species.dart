class Species {
  const Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.glyph,
    required this.color,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final String family;
  final String description;
  final String glyph;
  final int color;
}

/// Draft seed content for the prototype. These entries are not a validated
/// launch catalog or evidence that the app can identify these species.
const seedSpecies = <Species>[
  Species(id: 'monstera-deliciosa', commonName: 'Swiss cheese plant', scientificName: 'Monstera deliciosa', family: 'Araceae', description: 'A climbing tropical plant known for split leaves.', glyph: '✳', color: 0xFFBCD0A9),
  Species(id: 'ficus-elastica', commonName: 'Rubber plant', scientificName: 'Ficus elastica', family: 'Moraceae', description: 'An evergreen tree often grown indoors for its broad leaves.', glyph: '❦', color: 0xFFB6C6B0),
  Species(id: 'ocimum-tenuiflorum', commonName: 'Holy basil', scientificName: 'Ocimum tenuiflorum', family: 'Lamiaceae', description: 'An aromatic plant in the mint family.', glyph: '✿', color: 0xFFC9D3A4),
  Species(id: 'hibiscus-rosa-sinensis', commonName: 'Chinese hibiscus', scientificName: 'Hibiscus rosa-sinensis', family: 'Malvaceae', description: 'A flowering shrub with large, showy blooms.', glyph: '✾', color: 0xFFE0B7A8),
  Species(id: 'aloe-vera', commonName: 'Aloe vera', scientificName: 'Aloe vera', family: 'Asphodelaceae', description: 'A succulent with thick, fleshy leaves.', glyph: '✳', color: 0xFFB9CAA4),
  Species(id: 'epipremnum-aureum', commonName: 'Golden pothos', scientificName: 'Epipremnum aureum', family: 'Araceae', description: 'A tropical vine with heart-shaped leaves.', glyph: '❧', color: 0xFFD2D6A2),
  Species(id: 'azadirachta-indica', commonName: 'Neem', scientificName: 'Azadirachta indica', family: 'Meliaceae', description: 'A tree with compound leaves and small white flowers.', glyph: '❦', color: 0xFFAFC7A0),
  Species(id: 'bougainvillea-glabra', commonName: 'Bougainvillea', scientificName: 'Bougainvillea glabra', family: 'Nyctaginaceae', description: 'A climbing shrub recognized by its colorful bracts.', glyph: '✿', color: 0xFFD4B8C6),
];

Species? speciesById(String? id) {
  for (final species in seedSpecies) {
    if (species.id == id) return species;
  }
  return null;
}
