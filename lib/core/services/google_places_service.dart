import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  static const String _placeId = 'ChIJg9lttwH-nRIREI8yOfGlWSk';

  // Configurar via variable de entorno o Firebase Remote Config - NUNCA hardcodear
  static const String _apiKey = String.fromEnvironment('GOOGLE_PLACES_KEY');

  Future<Map<String, dynamic>> getPlaceDetails() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$_placeId&fields=rating,user_ratings_total&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Cast explícito a Map para evitar 'avoid_dynamic_calls'
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          return data['result'] as Map<String, dynamic>;
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
