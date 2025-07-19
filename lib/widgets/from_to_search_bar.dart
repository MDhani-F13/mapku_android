import 'package:flutter/material.dart';

class FromToSearchBar extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onFindRoute;

  const FromToSearchBar({
    Key? key,
    required this.fromController,
    required this.toController,
    required this.onFindRoute,
  }) : super(key: key);

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
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'Dari mana?',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'Ke mana?',
                prefixIcon: Icon(Icons.flag),
              ),
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
