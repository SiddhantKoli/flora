import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flora/features/identification/plant_suggestion_service.dart';

void main() {
  test('reads model scores and names without treating them as verified', () {
    final suggestion = PlantSuggestion.fromJson({
      'scientificName': 'Hibiscus rosa-sinensis',
      'commonName': 'Chinese hibiscus',
      'family': 'Malvaceae',
      'score': 0.82,
    });
    expect(suggestion.displayName, 'Chinese hibiscus');
    expect(suggestion.scientificName, 'Hibiscus rosa-sinensis');
    expect(suggestion.score, 0.82);
  });

  test('sends a photo to the configured endpoint and parses candidates',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory =
        await Directory.systemTemp.createTemp('flora-suggestion-test-');
    final photo = File('${directory.path}/photo.jpg');
    await photo.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
    final pending = server.first.then((request) async {
      expect(request.uri.path, '/identify');
      expect(request.method, 'POST');
      expect(request.headers.contentType?.mimeType, 'multipart/form-data');
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'results': [
          {
            'scientificName': 'Monstera deliciosa',
            'commonName': 'Swiss cheese plant',
            'family': 'Araceae',
            'score': 0.91,
          }
        ]
      }));
      await request.response.close();
    });
    try {
      final service =
          PlantSuggestionService(endpoint: 'http://localhost:${server.port}');
      final results = await service.suggest(photo.path);
      await pending;
      expect(results.single.scientificName, 'Monstera deliciosa');
      expect(results.single.score, 0.91);
    } finally {
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
