import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history_entry.dart';

class SearchHistoryService {
  static const _key = 'search_history';

  Future<List<SearchHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => SearchHistoryEntry.fromJson(json.decode(e))).toList();
  }

  Future<void> addEntry(SearchHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, entry); // tambah ke atas
    final encoded = history.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
