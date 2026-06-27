import 'package:dio/dio.dart';
import '../domain/models.dart';

class JourneyRepository {
  final Dio _dio;

  JourneyRepository(this._dio);

  Future<List<Stop>> getStops() async {
    final response = await _dio.get('stops/');
    return (response.data as List).map((json) => Stop.fromJson(json)).toList();
  }

  Future<List<Stop>> getNearbyStops(double lat, double lng, {double radius = 1.5}) async {
    final response = await _dio.get('stops/nearby/', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    return (response.data as List).map((json) => Stop.fromJson(json)).toList();
  }

  Future<List<Stop>> searchStops(String query) async {
    final response = await _dio.post('search/', data: {'query': query});
    return (response.data as List).map((json) => Stop.fromJson(json)).toList();
  }

  Future<Journey> planJourney({
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) async {
    final response = await _dio.post('journey/', data: {
      'source_lat': sourceLat,
      'source_lng': sourceLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
    });
    return Journey.fromJson(response.data);
  }
}
