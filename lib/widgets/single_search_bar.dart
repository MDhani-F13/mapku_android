import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/place_service.dart';

class SingleSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSuggestionSelected;
  final String hintText;

  SingleSearchBar({
    Key? key,
    required this.controller,
    required this.onSuggestionSelected,
    this.hintText = 'Cari tempat...',
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: TypeAheadField<String>(
          suggestionsCallback: (pattern) async {
            return await _placeService.fetchSuggestions(pattern);
          },
          itemBuilder: (context, suggestion) => ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(suggestion),
          ),
          onSuggestionSelected: onSuggestionSelected,
          textFieldConfiguration: TextFieldConfiguration(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
