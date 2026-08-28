import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A generic placeholder view for sections that are not yet built.
class PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderView({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMutedOnLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This feature is coming soon!',
              style: TextStyle(fontSize: 16, color: AppColors.textMutedOnLight),
            ),
          ],
        ),
      ),
    );
  }
}