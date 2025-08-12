import 'package:flutter/material.dart';

class ZoomButtons extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomButtons({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = 44.0;
    const cornerRadius = 14.0;

    Widget zoomButton(IconData icon, VoidCallback onPressed) {
      return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(cornerRadius),
          onTap: onPressed,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: Icon(icon, size: 22, color: Colors.black87),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        zoomButton(Icons.zoom_in, onZoomIn),
        const SizedBox(height: 12),
        zoomButton(Icons.zoom_out, onZoomOut),
      ],
    );
  }
}
