import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreFullMapScreen extends StatefulWidget {
  final LatLng currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const ExploreFullMapScreen({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
  });

  @override
  State<ExploreFullMapScreen> createState() => _ExploreFullMapScreenState();
}

class _ExploreFullMapScreenState extends State<ExploreFullMapScreen> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Map"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentPosition,
          zoom: 13,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        markers: widget.markers,
        polylines: widget.polylines,
        onMapCreated: (c) => _controller = c,
      ),
    );
  }
}
