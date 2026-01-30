import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

class DestinationMapScreen extends StatefulWidget {
  final String placeName;
  final LatLng destination;

  const DestinationMapScreen({
    super.key,
    required this.placeName,
    required this.destination,
  });

  @override
  State<DestinationMapScreen> createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  GoogleMapController? _mapController;

  LatLng? _currentPosition;
  bool _loadingLocation = true;

  final TextEditingController _searchController = TextEditingController();
  bool _searchLoading = false;

  LatLng? _destinationPosition;
  String _destinationName = "";

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ✅ YOUR GOOGLE API KEY (Directions + Places enabled)
  final String _googleApiKey = "AIzaSyA3RRPPDyzQFLGZSY0j5YB6bb9ZNu9Xk0c";

  @override
  void initState() {
    super.initState();
    _destinationPosition = widget.destination;
    _destinationName = widget.placeName;

    _searchController.text = widget.placeName;

    _setup();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    await _getCurrentLocation();

    if (_currentPosition != null && _destinationPosition != null) {
      _addMarkers();
      await _drawRouteToDestination(_destinationPosition!);

      _fitMapToTwoPoints(_currentPosition!, _destinationPosition!);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _loadingLocation = false);
    }
  }

  void _addMarkers() {
    _markers.clear();

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "You"),
        ),
      );
    }

    if (_destinationPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: _destinationPosition!,
          infoWindow: InfoWindow(title: _destinationName),
        ),
      );
    }

    setState(() {});
  }

  // ✅ SEARCH DESTINATION INSIDE BIG MAP
  Future<void> _searchDestination() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (_searchLoading) return;
    setState(() => _searchLoading = true);

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&key=$_googleApiKey",
      );

      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw "Google API error: ${res.statusCode}";
      }

      final body = jsonDecode(res.body);

      if (body["status"] != "OK") {
        throw body["error_message"] ?? body["status"] ?? "Search failed";
      }

      final results = body["results"] as List;
      if (results.isEmpty) {
        throw "No destination found";
      }

      final first = results.first;
      final loc = first["geometry"]["location"];

      final LatLng dest = LatLng(loc["lat"], loc["lng"]);

      setState(() {
        _destinationPosition = dest;
        _destinationName = first["name"] ?? query;
      });

      _addMarkers();

      // ✅ clear old route + redraw
      _polylines.clear();

      if (_currentPosition != null) {
        await _drawRouteToDestination(dest);
        _fitMapToTwoPoints(_currentPosition!, dest);
      } else {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(dest, 14));
      }
    } catch (e) {
      debugPrint("Search error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  // ✅ Draw route polyline using Directions API
  Future<void> _drawRouteToDestination(LatLng destination) async {
    if (_currentPosition == null) return;

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?"
            "origin=${_currentPosition!.latitude},${_currentPosition!.longitude}"
            "&destination=${destination.latitude},${destination.longitude}"
            "&mode=driving"
            "&key=$_googleApiKey",
      );

      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw "Directions API error: ${res.statusCode}";
      }

      final body = jsonDecode(res.body);

      if (body["status"] != "OK") {
        throw body["error_message"] ?? body["status"] ?? "Route failed";
      }

      final routes = body["routes"] as List;
      if (routes.isEmpty) return;

      final polyline = routes.first["overview_polyline"]["points"];
      final points = PolylinePoints().decodePolyline(polyline);

      final routeCoords =
      points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: routeCoords,
          width: 6,
          color: const Color(0xFF023e8a),
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  Future<void> _fitMapToTwoPoints(LatLng a, LatLng b) async {
    try {
      final southWest = LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      );

      final northEast = LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      );

      final bounds = LatLngBounds(southwest: southWest, northeast: northEast);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } catch (_) {}
  }

  void _clearRoute() {
    setState(() {
      _destinationPosition = null;
      _destinationName = "";
      _searchController.clear();
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == "destination");
    });
  }

  @override
  Widget build(BuildContext context) {
    final initTarget = _destinationPosition ?? widget.destination;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinationName.isEmpty ? "Map" : _destinationName),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initTarget,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // ✅ SEARCH BAR TOP (FIX ISSUE 2)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search destination...",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchDestination(),
                    ),
                  ),
                  if (_searchLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: _searchDestination,
                    ),
                  if (_destinationPosition != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _clearRoute,
                    ),
                ],
              ),
            ),
          ),

          if (_loadingLocation)
            Positioned(
              bottom: 18,
              left: 18,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  "Getting location...",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
