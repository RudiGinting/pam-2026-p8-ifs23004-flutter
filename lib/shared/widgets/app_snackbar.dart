// lib/shared/widgets/app_snackbar.dart

import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

void showAppSnackBar(
    BuildContext context, {
      required String message,
      SnackBarType type = SnackBarType.info,
    }) {
  final colors = {
    SnackBarType.success: (const Color(0xFF13DEB9), const Color(0xFFE2FBF7)),
    SnackBarType.error:   (const Color(0xFFFA896B), const Color(0xFFFFF1ED)),
    SnackBarType.warning: (const Color(0xFFFFAE1F), const Color(0xFFFFF5E3)),
    SnackBarType.info:    (const Color(0xFF539BFF), const Color(0xFFEAF3FF)),
  };
  final icons = {
    SnackBarType.success: Icons.check_circle_rounded,
    SnackBarType.error:   Icons.error_rounded,
    SnackBarType.warning: Icons.warning_rounded,
    SnackBarType.info:    Icons.info_rounded,
  };

  final (iconColor, bgColor) = colors[type]!;
  final icon = icons[type]!;

  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tombol Close
            GestureDetector(
              onTap: () => messenger.hideCurrentSnackBar(),
              child: Icon(
                Icons.close_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
}