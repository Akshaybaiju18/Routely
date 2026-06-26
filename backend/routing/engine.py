import math
from django.db.models import F
from transport.models import Stop, Route, RouteStop

def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 + 
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def get_nearby_stops(lat, lng, radius_km=1.5):
    """
    Returns a list of tuples (stop, distance_km) sorted by distance.
    If no stops are found within radius_km, returns the single closest stop.
    """
    stops = Stop.objects.all()
    nearby = []
    
    for stop in stops:
        dist = haversine_distance(lat, lng, stop.latitude, stop.longitude)
        if dist <= radius_km:
            nearby.append((stop, dist))
            
    # Fallback to the absolute closest stop if none are within radius
    if not nearby and stops.exists():
        closest_stop = min(stops, key=lambda s: haversine_distance(lat, lng, s.latitude, s.longitude))
        dist = haversine_distance(lat, lng, closest_stop.latitude, closest_stop.longitude)
        nearby.append((closest_stop, dist))
        
    nearby.sort(key=lambda x: x[1])
    return nearby

def calculate_fare(stops_count):
    """
    Fare: ₹10 base fare for the first 3 stops, and ₹2 for each subsequent stop.
    """
    if stops_count <= 0:
        return 0.0
    if stops_count <= 3:
        return 10.0
    return 10.0 + (stops_count - 3) * 2.0

def find_journeys(source_lat, source_lng, dest_lat, dest_lng, radius_km=1.5):
    """
    Finds direct and one-transfer journeys from source coordinates to destination coordinates.
    """
    start_stops = get_nearby_stops(source_lat, source_lng, radius_km)
    end_stops = get_nearby_stops(dest_lat, dest_lng, radius_km)
    
    if not start_stops or not end_stops:
        return []
        
    journeys = []
    seen_journeys = set()  # To avoid duplicate recommendations

    # 1. Look for Direct Routes
    for start_stop, d_start in start_stops:
        for end_stop, d_end in end_stops:
            if start_stop.id == end_stop.id:
                continue
                
            # Find routes that pass through both stops
            start_rs = RouteStop.objects.filter(stop=start_stop)
            for s_rs in start_rs:
                # Check if the same route passes through end_stop later
                try:
                    e_rs = RouteStop.objects.get(route=s_rs.route, stop=end_stop)
                    if s_rs.sequence_number < e_rs.sequence_number:
                        stops_count = e_rs.sequence_number - s_rs.sequence_number
                        bus_duration = stops_count * 3
                        
                        # Walking details
                        walk_dist = d_start + d_end
                        walk_duration = walk_dist * 12 # 5 km/h -> 12 mins/km
                        
                        total_duration = bus_duration + walk_duration
                        fare = calculate_fare(stops_count)
                        
                        # Unique identifier for this route combination
                        journey_key = f"direct-{s_rs.route.id}-{start_stop.id}-{end_stop.id}"
                        if journey_key in seen_journeys:
                            continue
                        seen_journeys.add(journey_key)
                        
                        journeys.append({
                            "type": "direct",
                            "total_duration_mins": round(total_duration, 1),
                            "total_distance_km": round(walk_dist, 2), # Bus distance is not tracked, just walking for MVP
                            "total_fare": fare,
                            "walking_distance_km": round(walk_dist, 2),
                            "walking_duration_mins": round(walk_duration, 1),
                            "bus_duration_mins": bus_duration,
                            "segments": [
                                {
                                    "type": "walk",
                                    "from_name": "Source Location",
                                    "to_name": start_stop.name,
                                    "distance_km": round(d_start, 2),
                                    "duration_mins": round(d_start * 12, 1),
                                    "instruction": f"Walk {round(d_start * 1000)}m to {start_stop.name} bus stop."
                                },
                                {
                                    "type": "bus",
                                    "route_name": s_rs.route.board_name,
                                    "operator": s_rs.route.operator,
                                    "board_stop": start_stop.name,
                                    "alight_stop": end_stop.name,
                                    "stops_count": stops_count,
                                    "duration_mins": bus_duration,
                                    "fare": fare,
                                    "instruction": f"Board {s_rs.route.board_name} ({s_rs.route.operator}) at {start_stop.name}. Ride {stops_count} stops and alight at {end_stop.name}."
                                },
                                {
                                    "type": "walk",
                                    "from_name": end_stop.name,
                                    "to_name": "Destination Location",
                                    "distance_km": round(d_end, 2),
                                    "duration_mins": round(d_end * 12, 1),
                                    "instruction": f"Walk {round(d_end * 1000)}m from {end_stop.name} to destination."
                                }
                            ]
                        })
                except RouteStop.DoesNotExist:
                    continue

    # 2. Look for One-Transfer Routes
    for start_stop, d_start in start_stops:
        for end_stop, d_end in end_stops:
            if start_stop.id == end_stop.id:
                continue
                
            start_rs_list = RouteStop.objects.filter(stop=start_stop)
            end_rs_list = RouteStop.objects.filter(stop=end_stop)
            
            for s_rs in start_rs_list:
                for e_rs in end_rs_list:
                    # They must be different routes
                    if s_rs.route.id == e_rs.route.id:
                        continue
                        
                    # Find if there is a common stop between s_rs.route and e_rs.route
                    # acting as a transfer stop
                    common_stops = RouteStop.objects.filter(
                        route=s_rs.route,
                        stop__in=RouteStop.objects.filter(route=e_rs.route).values('stop')
                    )
                    
                    for transfer_rs1 in common_stops:
                        transfer_stop = transfer_rs1.stop
                        
                        # Get the sequence number on the second route
                        transfer_rs2 = RouteStop.objects.get(route=e_rs.route, stop=transfer_stop)
                        
                        # Validation:
                        # 1. Transfer stop must be after start stop on route 1
                        # 2. End stop must be after transfer stop on route 2
                        if (s_rs.sequence_number < transfer_rs1.sequence_number and 
                            transfer_rs2.sequence_number < e_rs.sequence_number):
                            
                            stops_1 = transfer_rs1.sequence_number - s_rs.sequence_number
                            stops_2 = e_rs.sequence_number - transfer_rs2.sequence_number
                            
                            bus_duration = (stops_1 + stops_2) * 3
                            transfer_delay = 10.0 # 10 mins transfer delay
                            
                            # Walking details
                            walk_dist = d_start + d_end
                            walk_duration = walk_dist * 12
                            
                            total_duration = bus_duration + transfer_delay + walk_duration
                            
                            fare_1 = calculate_fare(stops_1)
                            fare_2 = calculate_fare(stops_2)
                            total_fare = fare_1 + fare_2
                            
                            journey_key = f"transfer-{s_rs.route.id}-{e_rs.route.id}-{start_stop.id}-{transfer_stop.id}-{end_stop.id}"
                            if journey_key in seen_journeys:
                                continue
                            seen_journeys.add(journey_key)
                            
                            journeys.append({
                                "type": "transfer",
                                "total_duration_mins": round(total_duration, 1),
                                "total_distance_km": round(walk_dist, 2),
                                "total_fare": total_fare,
                                "walking_distance_km": round(walk_dist, 2),
                                "walking_duration_mins": round(walk_duration, 1),
                                "bus_duration_mins": bus_duration,
                                "segments": [
                                    {
                                        "type": "walk",
                                        "from_name": "Source Location",
                                        "to_name": start_stop.name,
                                        "distance_km": round(d_start, 2),
                                        "duration_mins": round(d_start * 12, 1),
                                        "instruction": f"Walk {round(d_start * 1000)}m to {start_stop.name} bus stop."
                                    },
                                    {
                                        "type": "bus",
                                        "route_name": s_rs.route.board_name,
                                        "operator": s_rs.route.operator,
                                        "board_stop": start_stop.name,
                                        "alight_stop": transfer_stop.name,
                                        "stops_count": stops_1,
                                        "duration_mins": stops_1 * 3,
                                        "fare": fare_1,
                                        "instruction": f"Board {s_rs.route.board_name} ({s_rs.route.operator}) at {start_stop.name}. Ride {stops_1} stops and alight at {transfer_stop.name}."
                                    },
                                    {
                                        "type": "transfer_wait",
                                        "stop_name": transfer_stop.name,
                                        "duration_mins": transfer_delay,
                                        "instruction": f"Transfer at {transfer_stop.name}. Wait approx. 10 minutes for connecting bus."
                                    },
                                    {
                                        "type": "bus",
                                        "route_name": e_rs.route.board_name,
                                        "operator": e_rs.route.operator,
                                        "board_stop": transfer_stop.name,
                                        "alight_stop": end_stop.name,
                                        "stops_count": stops_2,
                                        "duration_mins": stops_2 * 3,
                                        "fare": fare_2,
                                        "instruction": f"Board {e_rs.route.board_name} ({e_rs.route.operator}) at {transfer_stop.name}. Ride {stops_2} stops and alight at {end_stop.name}."
                                    },
                                    {
                                        "type": "walk",
                                        "from_name": end_stop.name,
                                        "to_name": "Destination Location",
                                        "distance_km": round(d_end, 2),
                                        "duration_mins": round(d_end * 12, 1),
                                        "instruction": f"Walk {round(d_end * 1000)}m from {end_stop.name} to destination."
                                    }
                                ]
                            })
                            
    # Sort journeys: prefer shorter duration
    journeys.sort(key=lambda x: x["total_duration_mins"])
    return journeys
