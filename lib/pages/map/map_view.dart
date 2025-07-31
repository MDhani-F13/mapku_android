import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatelessWidget {
  final LatLng initialPosition;
  final double zoom;
  final void Function(GoogleMapController) onMapCreated;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const MapView({
    super.key,
    required this.initialPosition,
    required this.zoom,
    required this.onMapCreated,
    required this.markers,
    required this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: zoom,
      ),
      polylines: polylines,
      markers: markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
    );
  }
}
