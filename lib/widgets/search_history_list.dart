import 'package:flutter/material.dart';
import '../models/search_history_entry.dart';

class SearchHistoryList extends StatelessWidget {
  final List<SearchHistoryEntry> entries;

  const SearchHistoryList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text("Tidak ada riwayat.", style: TextStyle(fontStyle: FontStyle.italic));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          leading: Icon(entry.type == 'single' ? Icons.search : Icons.swap_horiz),
          title: Text(entry.query),
          subtitle: Text(entry.timestamp.toLocal().toString()),
        );
      },
    );
  }
}
