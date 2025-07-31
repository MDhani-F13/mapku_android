import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconHelper {
  static final MarkerIconHelper _instance = MarkerIconHelper._internal();
  static MarkerIconHelper get instance => _instance;

  factory MarkerIconHelper() {
    return _instance;
  }

  MarkerIconHelper._internal();

  BitmapDescriptor? start;
  BitmapDescriptor? end;
  BitmapDescriptor? closed;
  BitmapDescriptor? warning;

  Future<void> loadAll() async {
    start = await _load('assets/icons/start.png');
    end = await _load('assets/icons/end.png');
    closed = await _load('assets/icons/closed.png');
    warning = await _load('assets/icons/warning.png');
  }

  Future<BitmapDescriptor> _load(String asset) async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      asset,
    );
  }
}
