import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/traffic_updater.dart';
import '../services/map_object_builder.dart';

class TrafficController {
  final Duration refreshInterval;
  final TrafficUpdater _updater = TrafficUpdater();
  Timer? _timer;

  TrafficController({this.refreshInterval = const Duration(minutes: 10)});

  /// Memulai pembaruan berkala peta dengan segmen lalu lintas.
  void start({
    required Function(Set<Polyline>, Set<Marker>) onUpdate,
  }) async {
    await _loadAndUpdate(onUpdate);

    _timer = Timer.periodic(refreshInterval, (_) {
      _loadAndUpdate(onUpdate);
    });
  }

  /// Menghentikan pembaruan lalu lintas.
  void stop() {
    _timer?.cancel();
  }

  /// Memuat segmen terkini dan membangun polyline & marker dengan MapObjectBuilder.
  Future<void> _loadAndUpdate(
    Function(Set<Polyline>, Set<Marker>) onUpdate,
  ) async {
    try {
      final segments = await _updater.loadValidSegments();

      final (polylines, markers) =
          await MapObjectBuilder.buildMapObjects(segments);

      onUpdate(polylines, markers);
    } catch (e, st) {
      debugPrint('❌ Gagal load segmen lalu lintas: $e');
      debugPrint('$st');
    }
  }
}
