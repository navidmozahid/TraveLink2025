import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'destination_map_screen.dart';

// ✅ NEW service pages
import 'hotels_offers_screen.dart';
import 'car_rentals_offers_screen.dart';
import 'travel_agencies_offers_screen.dart';
import 'ticket_agencies_offers_screen.dart';
import 'travel_experiences_screen.dart';
import 'emergency_help_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(23.8103, 90.4125); // Default (Dhaka)
  bool _loadingLocation = false;

  // ✅ Search + Route variables
  final TextEditingController _searchController = TextEditingController();
  bool _searchLoading = false;

  LatLng? _destinationPosition;
  String? _destinationName;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final String _googleApiKey = "AIzaSyA3RRPPDyzQFLGZSY0j5YB6bb9ZNu9Xk0c";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() => _loadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentPosition = newLatLng;
        _loadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLatLng, 13),
      );

      _markers.removeWhere((m) => m.markerId.value == "me");
      _markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: newLatLng,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _loadingLocation = false);
    }
  }

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
      if (results.isEmpty) throw "No destination found";

      final first = results.first;
      final String placeName = first["name"] ?? query;

      final loc = first["geometry"]["location"];
      final LatLng dest = LatLng(loc["lat"], loc["lng"]);

      setState(() {
        _destinationPosition = dest;
        _destinationName = placeName;
      });

      _markers.removeWhere((m) => m.markerId.value == "destination");
      _markers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: dest,
          infoWindow: InfoWindow(title: placeName),
        ),
      );

      await _drawRouteToDestination(dest);

      if (!mounted) return;

      // ✅ open big map page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DestinationMapScreen(
            placeName: placeName,
            destination: dest,
          ),
        ),
      );
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

  Future<void> _drawRouteToDestination(LatLng destination) async {
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?"
            "origin=${_currentPosition.latitude},${_currentPosition.longitude}"
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
          width: 5,
          color: const Color(0xFF023e8a),
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  Widget _buildServiceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF023e8a)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: const Color(0xFF023e8a)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 6),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF023e8a),
            labelColor: const Color(0xFF023e8a),
            unselectedLabelColor: const Color(0xFF475569),
            tabs: const [
              Tab(text: "Search"),
              Tab(text: "Popular Destinations"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ MAP SECTION
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition,
                                zoom: 11,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              markers: _markers,
                              polylines: _polylines,
                            ),

                            // ✅ search bar fixed UI
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
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
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.send, size: 20),
                                        onPressed: _searchDestination,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ SERVICES GRID (NOW CLICKABLE ✅)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildServiceButton(
                          icon: Icons.hotel_outlined,
                          title: "Hotels Offers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HotelsOffersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildServiceButton(
                          icon: Icons.directions_car_outlined,
                          title: "Car Rentals Offers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const CarRentalsOffersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildServiceButton(
                          icon: Icons.travel_explore_outlined,
                          title: "Travel Agencies Offers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const TravelAgenciesOffersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildServiceButton(
                          icon: Icons.airplane_ticket_outlined,
                          title: "Ticket Agencies Offers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const TicketAgenciesOffersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildBigButton(
                      icon: Icons.emoji_events_outlined,
                      title: "Travel Experiences",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TravelExperiencesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildBigButton(
                      icon: Icons.emergency_outlined,
                      title: "Emergency Helps",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmergencyHelpScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListView(
                padding: const EdgeInsets.all(14),
                children: const [
                  Text(
                    "Popular Destinations",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text("Paris, France"),
                    subtitle: Text("Top city for travelers"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text("Dubai, UAE"),
                    subtitle: Text("Luxury & adventure"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text("Bali, Indonesia"),
                    subtitle: Text("Beaches & nature"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
