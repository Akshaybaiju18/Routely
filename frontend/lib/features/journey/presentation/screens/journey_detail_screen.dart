import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../domain/models.dart';

class JourneyDetailScreen extends StatefulWidget {
  final JourneyOption option;
  const JourneyDetailScreen({super.key, required this.option});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  ll.LatLng _centerPoint = const ll.LatLng(9.9880, 76.3000); // Kochi Kaloor default

  @override
  void initState() {
    super.initState();
    _loadMapDetails();
  }

  void _loadMapDetails() {
    _markers.clear();
    _polylines.clear();
    
    List<ll.LatLng> pathPoints = [];
    
    for (int i = 0; i < widget.option.segments.length; i++) {
      final segment = widget.option.segments[i];
      
      if (segment.startLat != null && segment.startLng != null) {
        final startPt = ll.LatLng(segment.startLat!, segment.startLng!);
        pathPoints.add(startPt);
        
        // Add start marker
        if (i == 0) {
          _markers.add(
            Marker(
              point: startPt,
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location, color: Colors.teal, size: 30),
            ),
          );
        } else if (segment.type == 'bus') {
          _markers.add(
            Marker(
              point: startPt,
              width: 40,
              height: 40,
              child: const Icon(Icons.directions_bus, color: Colors.teal, size: 24),
            ),
          );
        }
      }
      
      if (segment.endLat != null && segment.endLng != null) {
        final endPt = ll.LatLng(segment.endLat!, segment.endLng!);
        pathPoints.add(endPt);
        
        // Add end marker
        if (i == widget.option.segments.length - 1) {
          _markers.add(
            Marker(
              point: endPt,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: Colors.redAccent, size: 32),
            ),
          );
        }
      }
    }
    
    // Draw connecting paths
    if (pathPoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          points: pathPoints,
          color: Colors.teal.shade700,
          strokeWidth: 5.0,
        ),
      );
      
      // Compute midpoint to center the map view
      final midIndex = (pathPoints.length / 2).floor();
      _centerPoint = pathPoints[midIndex];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Details'),
      ),
      body: Column(
        children: [
          // OpenStreetMap section (Top half)
          Expanded(
            flex: 4,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _centerPoint,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.buswise.frontend',
                ),
                PolylineLayer(
                  polylines: _polylines,
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
          
          // Instructions Section (Bottom half)
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.option.totalDurationMins.toStringAsFixed(0)} minutes',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fare: ₹${widget.option.totalFare.toStringAsFixed(0)} • Walking: ${widget.option.walkingDistanceKm.toStringAsFixed(1)} km',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.payment, color: Colors.teal, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '₹${widget.option.totalFare.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    
                    // Steps list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: widget.option.segments.length,
                        itemBuilder: (context, index) {
                          final segment = widget.option.segments[index];
                          return _buildStepItem(segment, index == widget.option.segments.length - 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(Segment segment, bool isLast) {
    IconData icon;
    Color iconColor;
    
    switch (segment.type) {
      case 'walk':
        icon = Icons.directions_walk;
        iconColor = Colors.grey;
        break;
      case 'bus':
        icon = Icons.directions_bus;
        iconColor = Colors.teal;
        break;
      case 'transfer_wait':
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.trip_origin;
        iconColor = Colors.blue;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphics column
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Expanded(
                child: Container(
                  width: isLast ? 0 : 2,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Instruction detail text column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.instruction,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (segment.type == 'bus')
                    Text(
                      'Fare: ₹${segment.fare?.toStringAsFixed(0)} • Operator: ${segment.operator ?? "N/A"}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  if (segment.type == 'walk' && segment.distanceKm != null)
                    Text(
                      'Distance: ${segment.distanceKm!.toStringAsFixed(1)} km • Duration: ${segment.durationMins!.toStringAsFixed(0)} mins',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
