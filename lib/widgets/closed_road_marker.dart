import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/marker_icon_helper.dart';
import '../models/traffic_segment.dart';

class ClosedRoadMarker {
  static Marker build(TrafficSegment segment, {bool isWarning = false}) {
    final icon = isWarning
        ? MarkerIconHelper().warning!
        : MarkerIconHelper().closed!;

    return Marker(
      markerId: MarkerId('closed_${segment.id}'),
      position: LatLng(segment.singleLat!, segment.singleLng!),
      icon: icon,
      infoWindow: InfoWindow(
        title: segment.singleLocation ?? 'Jalan Ditutup',
        snippet: segment.sentence ?? '',
      ),
    );
  }
}
