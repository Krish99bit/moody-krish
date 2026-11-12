import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final String? artworkPath;
  final String seed;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  const ArtworkWidget({
    Key? key,
    this.artworkPath,
    required this.seed,
    this.size = 50.0,
    this.borderRadius = 8.0,
    this.fallbackIcon = Icons.music_note_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasValidFile = artworkPath != null &&
        artworkPath!.isNotEmpty &&
        File(artworkPath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: hasValidFile ? null : AppTheme.albumGradient(seed),
          color: AppTheme.surfaceElevated,
        ),
        child: hasValidFile
            ? Image.file(
                File(artworkPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: size * 0.48,
        color: AppTheme.textSecondary.withOpacity(0.8),
      ),
    );
  }
}
