import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoverArtView extends ConsumerWidget {
  final String? imagePath;
  final double size;

  const CoverArtView({
    super.key,
    this.imagePath,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(theme),
        ),
      );
    }

    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.3,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
