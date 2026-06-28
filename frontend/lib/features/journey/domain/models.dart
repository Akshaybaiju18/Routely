class Stop {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String city;
  final String? landmark;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.landmark,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      landmark: json['landmark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'landmark': landmark,
    };
  }
}

class RouteModel {
  final int id;
  final String boardName;
  final String operator;
  final bool active;

  RouteModel({
    required this.id,
    required this.boardName,
    required this.operator,
    required this.active,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as int,
      boardName: json['board_name'] as String,
      operator: json['operator'] as String,
      active: json['active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_name': boardName,
      'operator': operator,
      'active': active,
    };
  }
}

class Segment {
  final String type;
  final String instruction;
  final String? fromName;
  final String? toName;
  final double? distanceKm;
  final double? durationMins;
  final String? routeName;
  final String? operator;
  final String? boardStop;
  final String? alightStop;
  final int? stopsCount;
  final double? fare;
  final String? stopName;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;

  Segment({
    required this.type,
    required this.instruction,
    this.fromName,
    this.toName,
    this.distanceKm,
    this.durationMins,
    this.routeName,
    this.operator,
    this.boardStop,
    this.alightStop,
    this.stopsCount,
    this.fare,
    this.stopName,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      type: json['type'] as String,
      instruction: json['instruction'] as String,
      fromName: json['from_name'] as String?,
      toName: json['to_name'] as String?,
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      durationMins: json['duration_mins'] != null ? (json['duration_mins'] as num).toDouble() : null,
      routeName: json['route_name'] as String?,
      operator: json['operator'] as String?,
      boardStop: json['board_stop'] as String?,
      alightStop: json['alight_stop'] as String?,
      stopsCount: json['stops_count'] as int?,
      fare: json['fare'] != null ? (json['fare'] as num).toDouble() : null,
      stopName: json['stop_name'] as String?,
      startLat: json['start_lat'] != null ? (json['start_lat'] as num).toDouble() : null,
      startLng: json['start_lng'] != null ? (json['start_lng'] as num).toDouble() : null,
      endLat: json['end_lat'] != null ? (json['end_lat'] as num).toDouble() : null,
      endLng: json['end_lng'] != null ? (json['end_lng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'instruction': instruction,
      'from_name': fromName,
      'to_name': toName,
      'distance_km': distanceKm,
      'duration_mins': durationMins,
      'route_name': routeName,
      'operator': operator,
      'board_stop': boardStop,
      'alight_stop': alightStop,
      'stops_count': stopsCount,
      'fare': fare,
      'stop_name': stopName,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
    };
  }
}

class JourneyOption {
  final String type;
  final double totalDurationMins;
  final double totalDistanceKm;
  final double totalFare;
  final double walkingDistanceKm;
  final double walkingDurationMins;
  final double busDurationMins;
  final List<Segment> segments;

  JourneyOption({
    required this.type,
    required this.totalDurationMins,
    required this.totalDistanceKm,
    required this.totalFare,
    required this.walkingDistanceKm,
    required this.walkingDurationMins,
    required this.busDurationMins,
    required this.segments,
  });

  factory JourneyOption.fromJson(Map<String, dynamic> json) {
    return JourneyOption(
      type: json['type'] as String,
      totalDurationMins: (json['total_duration_mins'] as num).toDouble(),
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalFare: (json['total_fare'] as num).toDouble(),
      walkingDistanceKm: (json['walking_distance_km'] as num).toDouble(),
      walkingDurationMins: (json['walking_duration_mins'] as num).toDouble(),
      busDurationMins: (json['bus_duration_mins'] as num).toDouble(),
      segments: (json['segments'] as List)
          .map((s) => Segment.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'total_duration_mins': totalDurationMins,
      'total_distance_km': totalDistanceKm,
      'total_fare': totalFare,
      'walking_distance_km': walkingDistanceKm,
      'walking_duration_mins': walkingDurationMins,
      'bus_duration_mins': busDurationMins,
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }
}

class Journey {
  final int id;
  final String sourceName;
  final String destinationName;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;
  final Map<String, dynamic> responseData;
  final String createdAt;

  Journey({
    required this.id,
    required this.sourceName,
    required this.destinationName,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
    required this.responseData,
    required this.createdAt,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as int,
      sourceName: json['source_name'] as String,
      destinationName: json['destination_name'] != null ? json['destination_name'] as String : '',
      sourceLat: (json['source_lat'] as num).toDouble(),
      sourceLng: (json['source_lng'] as num).toDouble(),
      destLat: (json['dest_lat'] as num).toDouble(),
      destLng: (json['dest_lng'] as num).toDouble(),
      responseData: Map<String, dynamic>.from(json['response_data'] as Map),
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_name': sourceName,
      'destination_name': destinationName,
      'source_lat': sourceLat,
      'source_lng': sourceLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'response_data': responseData,
      'created_at': createdAt,
    };
  }
}
