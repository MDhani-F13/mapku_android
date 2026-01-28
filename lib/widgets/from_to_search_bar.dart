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

  InputDecoration _decoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📍 FROM
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: fromController,
                decoration: _decoration(
                  context,
                  hint: 'Dari mana?',
                  icon: Icons.trip_origin,
                ),
              ),
              suggestionsCallback: _placeService.fetchSuggestions,
              itemBuilder: _suggestionTile,
              onSuggestionSelected: (val) {
                fromController.text = val;
              },
            ),

            const SizedBox(height: 12),

            // subtle divider
            const Divider(height: 1),

            const SizedBox(height: 12),

            // 🏁 TO
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: toController,
                decoration: _decoration(
                  context,
                  hint: 'Ke mana?',
                  icon: Icons.flag_outlined,
                ),
              ),
              suggestionsCallback: _placeService.fetchSuggestions,
              itemBuilder: _suggestionTile,
              onSuggestionSelected: (val) {
                toController.text = val;
              },
            ),

            const SizedBox(height: 18),

            // 🧭 FIND ROUTE
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onFindRoute,
                icon: const Icon(Icons.directions),
                label: const Text('Cari Rute'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionTile(BuildContext context, String suggestion) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(suggestion),
      dense: true,
    );
  }
}
