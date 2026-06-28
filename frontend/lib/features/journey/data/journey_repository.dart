import 'package:dio/dio.dart';
import '../domain/models.dart';
import '../domain/location_point.dart';

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

  Future<List<LocationPoint>> searchPlacesOSM(String query) async {
    if (query.trim().isEmpty) return const [];
    
    final dio = Dio(); 
    try {
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(
          headers: {
            'User-Agent': 'BusWisePublicTransportApp/1.0',
          },
        ),
      );
      
      if (response.data is List) {
        return (response.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat'].toString()) ?? 0.0;
          final lon = double.tryParse(map['lon'].toString()) ?? 0.0;
          final name = map['display_name'] as String? ?? 'Unknown Place';
          return LocationPoint(name: name, latitude: lat, longitude: lon);
        }).toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return const [];
  }
}
