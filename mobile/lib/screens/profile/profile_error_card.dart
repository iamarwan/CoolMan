// lib/screens/profile/profile_error_card.dart
//
// A small "something failed, Retry" card.

import 'package:flutter/material.dart';


class ProfileErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorCard({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 36),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
