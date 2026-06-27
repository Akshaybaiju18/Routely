import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers.dart';
import '../../domain/models.dart';
import 'journey_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  
  String _sourceQuery = '';
  String _destQuery = '';
  
  bool _showSourceSuggestions = false;
  bool _showDestSuggestions = false;

  @override
  Widget build(BuildContext context) {
    final sourceStop = ref.watch(sourceStopProvider);
    final destStop = ref.watch(destinationStopProvider);
    final journeyAsync = ref.watch(journeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BusWise Navigation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Panel Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Source Field
                      TextField(
                        controller: _sourceController,
                        decoration: InputDecoration(
                          labelText: 'Source Location',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.teal),
                          suffixIcon: _sourceController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _sourceController.clear();
                                    ref.read(sourceStopProvider.notifier).state = null;
                                    setState(() { _sourceQuery = ''; });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _sourceQuery = val;
                            _showSourceSuggestions = true;
                          });
                        },
                      ),
                      
                      // Source Suggestions
                      if (_showSourceSuggestions && _sourceQuery.isNotEmpty)
                        _buildSuggestionsList(
                          query: _sourceQuery,
                          onSelect: (stop) {
                            ref.read(sourceStopProvider.notifier).state = stop;
                            _sourceController.text = stop.name;
                            setState(() {
                              _showSourceSuggestions = false;
                            });
                          },
                        ),
                        
                      const SizedBox(height: 16),
                      
                      // Destination Field
                      TextField(
                        controller: _destController,
                        decoration: InputDecoration(
                          labelText: 'Destination Location',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                          suffixIcon: _destController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _destController.clear();
                                    ref.read(destinationStopProvider.notifier).state = null;
                                    setState(() { _destQuery = ''; });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _destQuery = val;
                            _showDestSuggestions = true;
                          });
                        },
                      ),
                      
                      // Destination Suggestions
                      if (_showDestSuggestions && _destQuery.isNotEmpty)
                        _buildSuggestionsList(
                          query: _destQuery,
                          onSelect: (stop) {
                            ref.read(destinationStopProvider.notifier).state = stop;
                            _destController.text = stop.name;
                            setState(() {
                              _showDestSuggestions = false;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Journey Options Heading
              if (sourceStop != null && destStop != null) ...[
                const Text(
                  'Recommended Routes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 12),
                
                // Load Journey calculations
                journeyAsync.when(
                  data: (journey) {
                    if (journey == null) {
                      return const Center(child: Text('Enter both locations to search.'));
                    }
                    
                    final optionsList = journey.responseData['options'] as List?;
                    if (optionsList == null || optionsList.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No bus routes found connecting these coordinates. Seeding test routes might help!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    
                    final options = optionsList.map((j) => JourneyOption.fromJson(Map<String, dynamic>.from(j))).toList();
                    
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _buildJourneyOptionCard(context, option);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading routes: $err', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ] else ...[
                // Welcome card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.directions_bus, size: 64, color: Colors.teal),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome to BusWise!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for bus stops to plan your route. Try typing "Infopark" or "Kaloor".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList({required String query, required Function(Stop) onSelect}) {
    return Consumer(
      builder: (context, ref, child) {
        final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
        return suggestionsAsync.when(
          data: (stops) {
            if (stops.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No matching stops found.'),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: stops.length,
                itemBuilder: (context, i) {
                  final stop = stops[i];
                  return ListTile(
                    title: Text(stop.name),
                    subtitle: Text(stop.landmark ?? stop.city),
                    dense: true,
                    onTap: () => onSelect(stop),
                  );
                },
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Error: $e'),
        );
      },
    );
  }

  Widget _buildJourneyOptionCard(BuildContext context, JourneyOption option) {
    final isDirect = option.type == 'direct';
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JourneyDetailScreen(option: option),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDirect ? Colors.teal.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDirect ? 'DIRECT' : '1 TRANSFER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDirect ? Colors.teal.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '₹${option.totalFare.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${option.totalDurationMins.toStringAsFixed(0)} mins',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.directions_walk, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${option.walkingDistanceKm.toStringAsFixed(1)} km walking',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Bus numbers / summary
              _buildJourneySummaryIcons(option),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneySummaryIcons(JourneyOption option) {
    List<Widget> rowChildren = [];
    
    final busSegments = option.segments.where((s) => s.type == 'bus').toList();
    
    for (int i = 0; i < busSegments.length; i++) {
      if (i > 0) {
        rowChildren.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        ));
      }
      
      rowChildren.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus, size: 18, color: Colors.teal),
            const SizedBox(width: 4),
            Text(
              busSegments[i].routeName ?? 'Bus',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    
    return Row(children: rowChildren);
  }
}
