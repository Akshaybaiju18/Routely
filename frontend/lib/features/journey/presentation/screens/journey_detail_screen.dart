import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/models.dart';

class JourneyDetailScreen extends StatefulWidget {
  final JourneyOption option;
  const JourneyDetailScreen({super.key, required this.option});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  GoogleMapController? _mapController;
  bool _useMockMap = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMapDetails();
  }

  void _loadMapDetails() {
    // Generate Markers and Polylines based on segments
    List<LatLng> busPoints = [];
    List<LatLng> walkPoints = [];

    // Let's mock coordinate positions based on stops or draw lines
    // In a production app, stops coordinates will come from the Stop model
    // Here we extract what we can or fall back to mock offsets
    LatLng startLatLng = const LatLng(9.9931, 76.3575); // Kakkanad approx
    LatLng endLatLng = const LatLng(9.9670, 76.2430); // Fort Kochi approx

    _markers.add(Marker(
      markerId: const MarkerId('start'),
      position: startLatLng,
      infoWindow: const InfoWindow(title: 'Start Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('end'),
      position: endLatLng,
      infoWindow: const InfoWindow(title: 'Destination Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    // Simple polylines connecting the steps
    List<LatLng> allPoints = [startLatLng];

    final busSegments = widget.option.segments.where((s) => s.type == 'bus').toList();
    if (busSegments.isNotEmpty) {
      // Adding dummy points in between for mock visual mapping representation
      LatLng midpoint1 = const LatLng(9.9880, 76.3000); // Kaloor Stop
      _markers.add(Marker(
        markerId: const MarkerId('stop_mid'),
        position: midpoint1,
        infoWindow: InfoWindow(title: busSegments[0].boardStop ?? 'Bus Stop'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
      allPoints.add(midpoint1);
    }
    allPoints.add(endLatLng);

    _polylines.add(Polyline(
      polylineId: const PolylineId('route_path'),
      points: allPoints,
      color: Colors.teal,
      width: 5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Details'),
      ),
      body: Column(
        children: [
          // Map Section (Top)
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                _useMockMap ? _buildMockMap() : _buildGoogleMap(),
                // Map Toggle Button for testability
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'mapToggle',
                    backgroundColor: Colors.white.withOpacity(0.9),
                    onPressed: () {
                      setState(() {
                        _useMockMap = !_useMockMap;
                      });
                    },
                    icon: Icon(
                      _useMockMap ? Icons.map : Icons.layers_clear,
                      color: Colors.teal,
                    ),
                    label: Text(
                      _useMockMap ? 'Use Google Maps' : 'Use Mock Map',
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions Section (Bottom)
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

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(9.9880, 76.3000), // Kaloor center
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildMockMap() {
    return Container(
      color: Colors.teal.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 12),
            const Text(
              'Interactive Mock Map Active',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Text(
              'Visualizing paths without Google Maps API Key.',
              style: TextStyle(color: Colors.teal.shade800),
            ),
            const SizedBox(height: 16),
            // Mock visualization panel
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _mockNode('Start', Colors.green),
                    const Icon(Icons.arrow_forward),
                    _mockNode('Transit Hub', Colors.orange),
                    const Icon(Icons.arrow_forward),
                    _mockNode('Destination', Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockNode(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 12, backgroundColor: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
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
