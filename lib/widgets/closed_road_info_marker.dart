import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/traffic_segment.dart';

class ClosedRoadInfoMarker {
  static Marker build(TrafficSegment segment) {
    final from = segment.fromLocation ?? 'Unknown';
    final to = segment.toLocation ?? 'Unknown';

    double midLat;
    double midLng;

    if (segment.routePolyline != null && segment.routePolyline!.isNotEmpty) {
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decoded = polylinePoints.decodePolyline(segment.routePolyline!);

      if (decoded.isNotEmpty) {
        final midPoint = decoded[decoded.length ~/ 2];
        midLat = midPoint.latitude;
        midLng = midPoint.longitude;
      } else {
        // Fallback kalau decode gagal
        midLat = (segment.fromLat! + segment.toLat!) / 2;
        midLng = (segment.fromLng! + segment.toLng!) / 2;
      }
    } else {
      // Fallback kalau nggak ada polyline
      midLat = (segment.fromLat! + segment.toLat!) / 2;
      midLng = (segment.fromLng! + segment.toLng!) / 2;
    }

    return Marker(
      markerId: MarkerId('info_marker_${segment.id}'),
      position: LatLng(midLat, midLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: '$from ➜ $to',
        snippet: segment.sentence ?? '',
      ),
    );
  }
}