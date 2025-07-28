import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../utils/marker_icon_helper.dart';
import '../models/traffic_segment.dart';

class ClosedRoadInfoMarker {
  static Marker build(TrafficSegment segment, {bool isWarning = false}) {
    final icon = isWarning
        ? MarkerIconHelper().warning!
        : MarkerIconHelper().closed!;

    double midLat;
    double midLng;

    if (segment.routePolyline != null && segment.routePolyline!.isNotEmpty) {
      final decoded = PolylinePoints().decodePolyline(segment.routePolyline!);
      if (decoded.isNotEmpty) {
        final mid = decoded[decoded.length ~/ 2];
        midLat = mid.latitude;
        midLng = mid.longitude;
      } else {
        midLat = (segment.fromLat! + segment.toLat!) / 2;
        midLng = (segment.fromLng! + segment.toLng!) / 2;
      }
    } else {
      midLat = (segment.fromLat! + segment.toLat!) / 2;
      midLng = (segment.fromLng! + segment.toLng!) / 2;
    }

    return Marker(
      markerId: MarkerId('info_${segment.id}'),
      position: LatLng(midLat, midLng),
      icon: icon,
      infoWindow: InfoWindow(
        title: '${segment.fromLocation} ➜ ${segment.toLocation}',
        snippet: segment.sentence ?? '',
      ),
    );
  }
}
