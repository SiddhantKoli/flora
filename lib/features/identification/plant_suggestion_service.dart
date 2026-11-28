import 'dart:convert';

import 'package:http/http.dart' as http;

/// Set at build time. Never put the Pl@ntNet API key in the Android app.
const plantSuggestionEndpoint = String.fromEnvironment(
  'FLORA_IDENTIFY_ENDPOINT',
);

class PlantSuggestion {
  const PlantSuggestion({
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.score,
  });

  final String scientificName;
  final String commonName;
  final String family;
  final double score;

  String get displayName => commonName.isEmpty ? scientificName : commonName;

  factory PlantSuggestion.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return PlantSuggestion(
      scientificName: (json['scientificName'] as String? ?? '').trim(),
      commonName: (json['commonName'] as String? ?? '').trim(),
      family: (json['family'] as String? ?? '').trim(),
      score: rawScore is num ? rawScore.toDouble().clamp(0, 1) : 0,
    );
  }
}

class PlantSuggestionException implements Exception {
  const PlantSuggestionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PlantSuggestionService {
  const PlantSuggestionService({this.endpoint = plantSuggestionEndpoint});
  final String endpoint;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  Future<List<PlantSuggestion>> suggest(String originalPhotoPath) async {
    if (!isConfigured) {
      throw const PlantSuggestionException(
          'Plant suggestions are not connected yet. You can still name this plant yourself or save it as unknown.');
    }
    final uri =
        Uri.tryParse('${endpoint.replaceFirst(RegExp(r'/+$'), '')}/identify');
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' &&
            uri.host != 'localhost' &&
            uri.host != '10.0.2.2')) {
      throw const PlantSuggestionException(
          'The plant suggestion service is not configured correctly.');
    }
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files
            .add(await http.MultipartFile.fromPath('image', originalPhotoPath));
      final streamed =
          await request.send().timeout(const Duration(seconds: 35));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 35));
      if (response.statusCode == 404) {
        throw const PlantSuggestionException(
            'No plant match was found. Try another photo or save this one as unknown.');
      }
      if (response.statusCode == 429) {
        throw const PlantSuggestionException(
            'The free daily suggestion limit has been reached. You can still add this plant manually.');
      }
      if (response.statusCode != 200) {
        throw const PlantSuggestionException(
            'Plant suggestions are unavailable right now. Your photo is still here.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['results'] is! List) {
        throw const FormatException('Unexpected suggestion response');
      }
      return (decoded['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PlantSuggestion.fromJson)
          .where((item) => item.scientificName.isNotEmpty)
          .take(5)
          .toList();
    } on PlantSuggestionException {
      rethrow;
    } catch (_) {
      throw const PlantSuggestionException(
          'Could not connect to plant suggestions. Check your connection or name the plant yourself.');
    }
  }
}
