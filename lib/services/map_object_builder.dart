import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapku_android/models/traffic_segment.dart';
import 'package:mapku_android/services/traffic_service.dart';
import '../widgets/closed_road_polyline.dart';
import '../widgets/closed_road_marker.dart';
import '../widgets/closed_road_info_marker.dart';

class MapObjectBuilder {
  static Future<(Set<Polyline>, Set<Marker>)> buildMapObjects(List<TrafficSegment> segments) async {
    final Set<Polyline> polylineSet = {};
    final Set<Marker> markerSet = {};

    for (final segment in segments) {
      // Pastikan polyline sudah ada
      if (segment.fromLat != null &&
          segment.fromLng != null &&
          segment.toLat != null &&
          segment.toLng != null) {

        // Kalau belum punya polyline, ambil dari server
        if (segment.routePolyline == null || segment.routePolyline!.isEmpty) {
          final fetched = await TrafficService.fetchPolyline(segment.id);
          if (fetched != null) {
            segment.routePolyline = fetched;
          }
        }

        // Tambahkan polyline ke peta
        final polyline = ClosedRoadPolyline.draw(segment);
          polylineSet.addAll(polyline);
        

        // Tambahkan marker ikon (warning jika usedFallback)
        markerSet.add(
          ClosedRoadInfoMarker.build(segment, isWarning: segment.usedFallback == true),
        );
      }

      // Untuk single location segment
      if (segment.singleLat != null && segment.singleLng != null) {
        markerSet.add(
          ClosedRoadMarker.build(segment, isWarning: segment.usedFallback == true),
        );
      }
    }

    return (polylineSet, markerSet);
  }
}

