// lib/widgets/app_snackbar.dart
//
// The little message bar shown at the bottom of the screen. Teal for normal
// messages, red when [isError] is true.
//
// Call it only while the screen is still showing (check `mounted` first in a
// State class), because it needs a live BuildContext.

import 'package:flutter/material.dart';

import '../core/theme.dart';

void showAppSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      message,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
    backgroundColor: isError ? AppColors.danger : AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  ));
}
