// lib/models/traffic_report.dart
import 'traffic_segment.dart';

class TrafficReport {
  final int id;
  final String query;
  final String text;
  final String? time;
  final String? createdAt;
  final List<TrafficSegment> segments;

  TrafficReport({
    required this.id,
    required this.query,
    required this.text,
    this.time,
    this.createdAt,
    required this.segments,
  });

  factory TrafficReport.fromJson(Map<String, dynamic> json) {
    return TrafficReport(
      id: json['id'],
      query: json['query'],
      text: json['text'],
      time: json['time'],
      createdAt: json['created_at'],
      segments: (json['segments'] as List)
          .map((s) => TrafficSegment.fromJson(s))
          .toList(),
    );
  }
}
