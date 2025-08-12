import 'package:flutter/material.dart';

class DirectionControls extends StatelessWidget {
  final bool isDirectionMode;
  final VoidCallback onToggle;

  const DirectionControls({
    super.key,
    required this.isDirectionMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDirectionMode ? "Tutup Mode Rute" : "Mode Arah",
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.alt_route, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
