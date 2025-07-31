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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: TypeAheadField<String>(
          textFieldConfiguration: TextFieldConfiguration(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          suggestionsCallback: (pattern) async {
            return await _placeService.fetchSuggestions(pattern);
          },
          itemBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion),
          ),
          onSuggestionSelected: onSuggestionSelected,
        ),
      ),
    );
  }
}
