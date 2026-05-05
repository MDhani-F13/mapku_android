import 'package:flutter/material.dart';
import '../models/search_history_entry.dart';

class SearchHistoryList extends StatelessWidget {
  final List<SearchHistoryEntry> entries;

  const SearchHistoryList({super.key, required this.entries});

  String formatTime(DateTime time) {
    final local = time.toLocal();

    final day = local.day;
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final month = monthNames[local.month];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return "$day $month, $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "Tidak ada riwayat.",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isSingle = entry.type == 'single';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSingle
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSingle ? Icons.search : Icons.swap_horiz,
                  size: 20,
                  color: isSingle ? Colors.blue : Colors.green,
                ),
              ),

              title: Text(
                entry.query,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),

              subtitle: Text(
                formatTime(entry.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}