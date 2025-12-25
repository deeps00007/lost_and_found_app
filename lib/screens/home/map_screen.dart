import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item_model.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'item_detail_screen.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final ItemModel? focusItem;
  const MapScreen({super.key, this.focusItem});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _defaultLocation =
      const LatLng(28.6139, 77.2090); // Default: India

  bool _nearbyOnly = false;
  LatLng? _userLocation;
  bool _isLocating = false;
  late final AnimationController _signalController;

  @override
  void initState() {
    super.initState();
    _signalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _signalController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLocating = true);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocating = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        if (_nearbyOnly) {
          _mapController.move(_userLocation!, 14.0);
        }
      });
    } catch (e) {
      debugPrint('Error getting current location: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Map'),
        actions: [
          if (_isLocating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_nearbyOnly ? Icons.near_me : Icons.near_me_outlined),
            color: _nearbyOnly ? Colors.blue : null,
            tooltip: 'Nearby Only (10km)',
            onPressed: () async {
              if (_userLocation == null) {
                await _fetchUserLocation();
              }

              setState(() => _nearbyOnly = !_nearbyOnly);

              if (_nearbyOnly && _userLocation != null) {
                _mapController.move(_userLocation!, 14.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Focusing on your location (10km radius)')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading map data'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!.docs
              .map((doc) {
                return ItemModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
              })
              .where((item) => item.latitude != null && item.longitude != null)
              .toList();

          // Apply distance filter if _nearbyOnly is active
          final items = !_nearbyOnly || _userLocation == null
              ? allItems
              : allItems.where((item) {
                  final distance = Geolocator.distanceBetween(
                    _userLocation!.latitude,
                    _userLocation!.longitude,
                    item.latitude!,
                    item.longitude!,
                  );
                  return distance <= 10000; // 10km in meters
                }).toList();

          // Create a map to link Markers back to ItemModels for the cluster builder
          final Map<Key, ItemModel> markerToItem = {};
          final markers = items.map((item) {
            final key = ValueKey(item.id);
            markerToItem[key] = item;

            return Marker(
              key: key,
              point: LatLng(item.latitude!, item.longitude!),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () {
                  _showItemPopup(context, item);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color:
                              item.type == 'lost' ? Colors.red : Colors.green,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: item.images.isNotEmpty
                            ? Image.network(
                                item.images.first,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 30,
                                    color: Colors.grey[400],
                                  );
                                },
                              )
                            : Icon(
                                Icons.image,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          // Determine initial center
          LatLng center = _defaultLocation;
          if (widget.focusItem != null &&
              widget.focusItem!.latitude != null &&
              widget.focusItem!.longitude != null) {
            center = LatLng(
                widget.focusItem!.latitude!, widget.focusItem!.longitude!);
          } else if (items.isNotEmpty) {
            center = LatLng(items.first.latitude!, items.first.longitude!);
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.focusItem != null ? 18.0 : 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.app.lost_and_found',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(80, 80),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    final count = clusterMarkers.length;
                    final displayItems = clusterMarkers
                        .take(2)
                        .map((m) => markerToItem[m.key]!)
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3436),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (displayItems.length > 1)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: _buildMiniImage(displayItems[1]),
                            ),
                          if (displayItems.isNotEmpty)
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: _buildMiniImage(displayItems[0]),
                            ),
                          if (count > 2)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '+${count - 2}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // User Location Signal Animation - 10km Radius
              if (_nearbyOnly && _userLocation != null)
                AnimatedBuilder(
                  animation: _signalController,
                  builder: (context, child) {
                    return CircleLayer(
                      circles: [
                        // Primary Ripple
                        CircleMarker(
                          point: _userLocation!,
                          radius: 10000 *
                              _signalController.value, // Animated up to 10km
                          useRadiusInMeter: true,
                          color: Colors.blue
                              .withOpacity(0.1 * (1 - _signalController.value)),
                          borderColor: Colors.blue
                              .withOpacity(0.3 * (1 - _signalController.value)),
                          borderStrokeWidth: 2,
                        ),
                        // Secondary Ripple (Offset)
                        CircleMarker(
                          point: _userLocation!,
                          radius:
                              10000 * ((_signalController.value + 0.5) % 1.0),
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.1 *
                              (1 - ((_signalController.value + 0.5) % 1.0))),
                          borderColor: Colors.blue.withOpacity(0.3 *
                              (1 - ((_signalController.value + 0.5) % 1.0))),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    );
                  },
                ),

              // User Blue Dot - Fixed size Marker
              if (_nearbyOnly && _userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _showItemPopup(BuildContext context, ItemModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.images.isNotEmpty
                            ? item.images.first
                            : 'https://via.placeholder.com/150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.type == 'lost'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.type == 'lost' ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: TextStyle(
                        color: item.type == 'lost' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(item: item),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniImage(ItemModel item) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: item.type == 'lost' ? Colors.red : Colors.green,
          width: 2,
        ),
        color: Colors.grey[300],
      ),
      child: ClipOval(
        child: item.images.isNotEmpty
            ? Image.network(
                item.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 20,
                    color: Colors.grey),
              )
            : const Icon(Icons.image, size: 20, color: Colors.grey),
      ),
    );
  }
}
