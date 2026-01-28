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
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TypeAheadField<String>(
          suggestionsCallback: _placeService.fetchSuggestions,
          itemBuilder: (context, suggestion) => ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(suggestion),
            dense: true,
          ),
          onSuggestionSelected: onSuggestionSelected,
          textFieldConfiguration: TextFieldConfiguration(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSuggestionSelected,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),
        ),
      ),
    );
  }
}
