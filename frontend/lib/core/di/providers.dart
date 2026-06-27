import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../features/journey/data/journey_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return JourneyRepository(client.dio);
});
