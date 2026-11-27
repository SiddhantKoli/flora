import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/observation.dart';
import 'package:flora/data/personal_plant.dart';

void main() {
  final first = Observation(
      id: 'visit-1',
      imagePath: 'one.jpg',
      createdAt: DateTime.utc(2026, 11, 1),
      status: 'unknown');
  final recent = Observation(
      id: 'visit-2',
      imagePath: 'two.jpg',
      createdAt: DateTime.utc(2026, 11, 20),
      status: 'unknown');

  test('nickname and custom name describe one plant across visits', () {
    final plant = PersonalPlant(
      id: 'plant-1',
      createdAt: first.createdAt,
      customName: 'Purple vine',
      nickname: 'Balcony friend',
      placeLabel: 'Balcony',
      visits: [recent, first],
    );
    expect(plant.displayName, 'Balcony friend');
    expect(plant.plantLabel, 'Purple vine');
    expect(plant.lastSeenAt, recent.createdAt);
    expect(plant.visits.length, 2);
    expect(plant.hasCatalogName, false);
  });

  test('catalog label stays distinct from personal nickname', () {
    final plant = PersonalPlant(
      id: 'plant-2',
      createdAt: first.createdAt,
      speciesId: 'monstera-deliciosa',
      nickname: 'Mira',
      visits: [first],
    );
    expect(plant.displayName, 'Mira');
    expect(plant.plantLabel, 'Swiss cheese plant');
    expect(plant.hasCatalogName, true);
  });
}
