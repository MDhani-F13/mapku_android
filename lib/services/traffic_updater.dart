import 'dart:async';
import '../models/traffic_segment.dart';
import 'traffic_service.dart';

class TrafficUpdater {
  final TrafficService _trafficService = TrafficService();
  Timer? _timer;

  Future<List<TrafficSegment>> loadValidSegments() async {
    final segments = await _trafficService.fetchSegments();
    final now = DateTime.now();

    return segments.where((seg) {
      if (seg.time == null) return true;
      return now.difference(seg.time!).inHours < 4;
    }).toList();
  }

  void startPeriodicUpdates({
    required Function(List<TrafficSegment>) onUpdate,
    Duration interval = const Duration(minutes: 10),
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final segments = await loadValidSegments();
      onUpdate(segments);
    });
  }

  void stop() {
    _timer?.cancel();
  }
}