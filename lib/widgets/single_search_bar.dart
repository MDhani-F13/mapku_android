import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/place_service.dart';
import 'dart:ui';

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

  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
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
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
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
      ),
    ),
  );
}
}
