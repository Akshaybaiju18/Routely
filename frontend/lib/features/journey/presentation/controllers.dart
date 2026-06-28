import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/journey_repository.dart';
import '../../../core/di/providers.dart';
import '../domain/models.dart';
import '../domain/location_point.dart';

// State provider for selected source location
final sourceLocationProvider = StateProvider<LocationPoint?>((ref) => null);

// State provider for selected destination location
final destinationLocationProvider = StateProvider<LocationPoint?>((ref) => null);

// OpenStreetMap Nominatim Auto-complete suggestions provider
final osmSuggestionsProvider = FutureProvider.family<List<LocationPoint>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final repo = ref.watch(journeyRepositoryProvider);
  return repo.searchPlacesOSM(query);
});

// Journey results provider
final journeyProvider = FutureProvider<Journey?>((ref) async {
  final source = ref.watch(sourceLocationProvider);
  final destination = ref.watch(destinationLocationProvider);
  
  if (source == null || destination == null) return null;
  
  final repo = ref.watch(journeyRepositoryProvider);
  return repo.planJourney(
    sourceLat: source.latitude,
    sourceLng: source.longitude,
    destLat: destination.latitude,
    destLng: destination.longitude,
  );
});
