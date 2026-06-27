import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/journey_repository.dart';
import '../../../core/di/providers.dart';
import '../domain/models.dart';

// State provider for selected source stop
final sourceStopProvider = StateProvider<Stop?>((ref) => null);

// State provider for selected destination stop
final destinationStopProvider = StateProvider<Stop?>((ref) => null);

// Auto-complete Search suggestions provider
final searchSuggestionsProvider = FutureProvider.family<List<Stop>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final repo = ref.watch(journeyRepositoryProvider);
  return repo.searchStops(query);
});

// Journey results provider
final journeyProvider = FutureProvider<Journey?>((ref) async {
  final source = ref.watch(sourceStopProvider);
  final destination = ref.watch(destinationStopProvider);
  
  if (source == null || destination == null) return null;
  
  final repo = ref.watch(journeyRepositoryProvider);
  return repo.planJourney(
    sourceLat: source.latitude,
    sourceLng: source.longitude,
    destLat: destination.latitude,
    destLng: destination.longitude,
  );
});
