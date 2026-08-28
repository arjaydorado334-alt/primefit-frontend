import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// The circular "PF" badge used in the navbar, hero section and sidebar.
class PrimeFitBadge extends StatelessWidget {
  final double size;
  const PrimeFitBadge({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.iconGradient,
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.fitness_center,
          color: AppColors.cyan,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// "Prime" + "Fit" wordmark with two-tone coloring, used next to the badge.
class PrimeFitWordmark extends StatelessWidget {
  final double fontSize;
  const PrimeFitWordmark({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.archivoBlack(fontSize: fontSize, letterSpacing: -0.3),
        children: const [
          TextSpan(text: 'Prime', style: TextStyle(color: AppColors.cyan)),
          TextSpan(text: 'Fit', style: TextStyle(color: AppColors.yellow)),
        ],
      ),
    );
  }
}
