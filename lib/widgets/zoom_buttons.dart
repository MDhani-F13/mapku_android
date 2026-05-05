import 'package:flutter/material.dart';
import 'dart:ui';

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
  final theme = Theme.of(context);

  return ClipRRect(
    borderRadius: BorderRadius.circular(cornerRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.75),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(cornerRadius),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: Colors.black87,
              ),
            ),
          ),
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
