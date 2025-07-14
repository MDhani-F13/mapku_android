class TrafficSegment {
  final int id;
  final String? fromLocation;
  final String? toLocation;
  final String? singleLocation;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final double? singleLat;
  final double? singleLng;
  final String? sentence;
  String? routePolyline;
  final DateTime? time;

  TrafficSegment({
    required this.id,
    this.fromLocation,
    this.toLocation,
    this.singleLocation,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.singleLat,
    this.singleLng,
    this.sentence,
    this.routePolyline,
    this.time,
  });

  factory TrafficSegment.fromJson(Map<String, dynamic> json) {
    return TrafficSegment(
      id: json['id'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      singleLocation: json['single_location'],
      fromLat: json['from_lat'],
      fromLng: json['from_lng'],
      toLat: json['to_lat'],
      toLng: json['to_lng'],
      singleLat: json['single_lat'],
      singleLng: json['single_lng'],
      sentence: json['sentence'],
      routePolyline: json['route_polyline'],
      time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
    );
  }

  String get displayRoute => '$fromLocation ➜ $toLocation';
}
