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
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: fromController,
                decoration: const InputDecoration(
                  labelText: 'Dari mana?',
                  prefixIcon: Icon(Icons.location_on),
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
            const SizedBox(height: 8),
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'Ke mana?',
                  prefixIcon: Icon(Icons.flag),
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
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onFindRoute,
              icon: const Icon(Icons.directions),
              label: const Text('Cari Rute'),
            )
          ],
        ),
      ),
    );
  }
}
