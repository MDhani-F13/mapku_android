import 'package:flutter/material.dart';
import 'dart:ui';

class ProfileButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileButton({
    super.key,
    required this.onPressed,
  });

 @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Tooltip(
    message: "Profil",
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPressed,
              child: const Icon(
                Icons.person_outline,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
