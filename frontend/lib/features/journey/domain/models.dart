import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class Stop with _$Stop {
  const factory Stop({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required String city,
    String? landmark,
  }) = _Stop;

  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
}

@freezed
class RouteModel with _$RouteModel {
  const factory RouteModel({
    required int id,
    @JsonKey(name: 'board_name') required String boardName,
    required String operator,
    required bool active,
  }) = _RouteModel;

  factory RouteModel.fromJson(Map<String, dynamic> json) => _$RouteModelFromJson(json);
}

@freezed
class Segment with _$Segment {
  const factory Segment({
    required String type, // "walk", "bus", "transfer_wait"
    required String instruction,
    @JsonKey(name: 'from_name') String? fromName,
    @JsonKey(name: 'to_name') String? toName,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'duration_mins') double? durationMins,
    @JsonKey(name: 'route_name') String? routeName,
    String? operator,
    @JsonKey(name: 'board_stop') String? boardStop,
    @JsonKey(name: 'alight_stop') String? alightStop,
    @JsonKey(name: 'stops_count') int? stopsCount,
    double? fare,
    @JsonKey(name: 'stop_name') String? stopName,
  }) = _Segment;

  factory Segment.fromJson(Map<String, dynamic> json) => _$SegmentFromJson(json);
}

@freezed
class JourneyOption with _$JourneyOption {
  const factory JourneyOption({
    required String type, // "direct", "transfer"
    @JsonKey(name: 'total_duration_mins') required double totalDurationMins,
    @JsonKey(name: 'total_distance_km') required double totalDistanceKm,
    @JsonKey(name: 'total_fare') required double totalFare,
    @JsonKey(name: 'walking_distance_km') required double walkingDistanceKm,
    @JsonKey(name: 'walking_duration_mins') required double walkingDurationMins,
    @JsonKey(name: 'bus_duration_mins') required double busDurationMins,
    required List<Segment> segments,
  }) = _JourneyOption;

  factory JourneyOption.fromJson(Map<String, dynamic> json) => _$JourneyOptionFromJson(json);
}

@freezed
class Journey with _$Journey {
  const factory Journey({
    required int id,
    @JsonKey(name: 'source_name') required String sourceName,
    @JsonKey(name: 'destination_name') required String destinationName,
    @JsonKey(name: 'source_lat') required double sourceLat,
    @JsonKey(name: 'source_lng') required double sourceLng,
    @JsonKey(name: 'dest_lat') required double destLat,
    @JsonKey(name: 'dest_lng') required double destLng,
    @JsonKey(name: 'response_data') required Map<String, dynamic> responseData,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Journey;

  factory Journey.fromJson(Map<String, dynamic> json) => _$JourneyFromJson(json);
}
