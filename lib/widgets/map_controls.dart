import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleDirectionMode;
  final VoidCallback onOpenProfile;
  final bool isDirectionMode;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleDirectionMode,
    required this.onOpenProfile,
    required this.isDirectionMode,
    
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔘 Zoom & profile (bottom)
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
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
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            heroTag: "profileBtn",
            mini: true,
            onPressed: onOpenProfile,
            child: const Icon(Icons.person),
          ),
        ),

        // 🧭 Direction toggle (top right)
        Positioned(
          top: 10,
          right: 10,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.directions,
                size: 20,
                color: isDirectionMode ? Colors.blueGrey : Colors.black,
              ),
              onPressed: onToggleDirectionMode,
            ),
          ),
        ),
      ],
    );
  }
}
