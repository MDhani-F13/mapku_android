// lib/widgets/map_controls.dart

import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: "zoomIn",
          mini: true,
          onPressed: onZoomIn,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "zoomOut",
          mini: true,
          onPressed: onZoomOut,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
