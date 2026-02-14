import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/services/google_places_service.dart';

final googlePlacesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return GooglePlacesService().getPlaceDetails();
});
