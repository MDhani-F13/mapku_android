class SearchHistoryEntry {
  final String type; // 'single' atau 'from_to'
  final String query;
  final DateTime timestamp;

  SearchHistoryEntry({
    required this.type,
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'query': query,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      type: json['type'],
      query: json['query'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
