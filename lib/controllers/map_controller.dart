import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapController extends ChangeNotifier {
  GoogleMapController? _googleMapController;

  final Set<Marker> _markers = {};
  final Set<Polyline> _trafficPolylines = {};
  final Set<Polyline> _directionPolylines = {};
  final Set<Marker> _trafficMarkers = {};
  final Set<Marker> _directionMarkers = {};

 
  Set<Polyline> _combinedPolylines = {}; 
  GoogleMapController? get controller => _googleMapController;
  Set<Marker> get markers =>  {..._trafficMarkers, ..._directionMarkers};
  Set<Polyline> get polylines => _combinedPolylines;
  bool get hasController => _googleMapController != null;

  void setController(GoogleMapController controller) {
    _googleMapController = controller;
  }

  void zoomIn() {
    _googleMapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    _googleMapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void moveTo(LatLng position, {double zoom = 15.0}) {
    _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  void setMarkers(Set<Marker> markers) {
    _markers.clear();
    _markers.addAll(markers);
    notifyListeners();
  }
  
  void setTrafficMarkers(Set<Marker> markers) {
    _trafficMarkers
      ..clear()
      ..addAll(markers);
    notifyListeners();
  }

  void setDirectionMarkers(Set<Marker> markers) {
    _directionMarkers
      ..clear()
      ..addAll(markers);
    notifyListeners();
  }

  void clearDirectionMarkers() {
    _directionMarkers.clear();
    notifyListeners();
  }
  void setTrafficPolylines(Set<Polyline> polylines) {
    _trafficPolylines
      ..clear()
      ..addAll(polylines);
    _updateAllPolylines();
  }

  void setDirectionPolylines(Set<Polyline> polylines) {
    _directionPolylines
      ..clear()
      ..addAll(polylines);
    _updateAllPolylines();
  }

  void clearDirectionPolylines() {
    _directionPolylines.clear();
    _updateAllPolylines();
  }

  void _updateAllPolylines() {
    _combinedPolylines = {
      ..._trafficPolylines,
      ..._directionPolylines,
    };
    notifyListeners();
  }

  void clearMapObjects() {
    _markers.clear();
    _trafficPolylines.clear();
    _directionPolylines.clear();
    _combinedPolylines.clear();
    notifyListeners();
  }

  void disposeController() {
    _googleMapController?.dispose();
    _googleMapController = null;
  }

  Future<void> moveToAddress(String address, {double zoom = 16}) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
      }
    } catch (e) {
      debugPrint('Error locating "$address": $e');
    }
  }

  Future<void> moveToUserLocation({double zoom = 15}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!serviceEnabled || permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      moveTo(target, zoom: zoom);
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi: $e');
    }
  }
}
