import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/place_service.dart';

class FromToSearchBar extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onFindRoute;

  FromToSearchBar({
    Key? key,
    required this.fromController,
    required this.toController,
    required this.onFindRoute,
  }) : super(key: key);

  final PlaceService _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📍 From
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: fromController,
                decoration: InputDecoration(
                  hintText: 'Dari mana?',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await _placeService.fetchSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) =>
                  ListTile(title: Text(suggestion)),
              onSuggestionSelected: (suggestion) {
                fromController.text = suggestion;
              },
            ),

            const SizedBox(height: 12),

            // 🏁 To
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: toController,
                decoration: InputDecoration(
                  hintText: 'Ke mana?',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await _placeService.fetchSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) =>
                  ListTile(title: Text(suggestion)),
              onSuggestionSelected: (suggestion) {
                toController.text = suggestion;
              },
            ),

            const SizedBox(height: 16),

            // 🧭 Find Route Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: onFindRoute,
                icon: const Icon(Icons.directions),
                label: const Text('Cari Rute'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
