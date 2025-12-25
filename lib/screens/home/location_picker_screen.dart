import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController(); // Added
  LatLng _selectedLocation =
      const LatLng(28.6139, 77.2090); // Default: New Delhi
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    } else {
      _getCurrentLocation();
    }
  }

  // Search Function
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Close keyboard

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'com.app.lost_and_found', // Required by OSM
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLocation = LatLng(lat, lon);

          setState(() {
            _selectedLocation = newLocation;
            _mapController.move(_selectedLocation, 15.0);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      } else {
        throw 'Error searching location';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation, 15.0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.app.lost_and_found',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Search Bar Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchLocation(),
                decoration: InputDecoration(
                  hintText: 'Search city or place...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLocation,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
