import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/traffic_segment.dart';

class ClosedRoadMarker {
  static Marker build(TrafficSegment segment) {
    return Marker(
      markerId: MarkerId('single_loc_${segment.id}'),
      position: LatLng(segment.singleLat!, segment.singleLng!),
      infoWindow: InfoWindow(
        title: segment.singleLocation ?? 'Closed Road',
        snippet: segment.sentence ?? '', 
      ),
    );
  }
}
