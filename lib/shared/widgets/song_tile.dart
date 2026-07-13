import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/file_utils.dart';

/// Reusable list tile widget displaying a single [Song].
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCoverTap;
  final bool showDuration;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.onCoverTap,
    this.showDuration = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = Duration(milliseconds: song.durationMs);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Cover art
            _buildLeading(theme),
            const SizedBox(width: 12),
            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.artist ?? 'Unknown Artist'} · ${song.album ?? 'Unknown Album'}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Three-dot menu button (always visible)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onPressed: () => onCoverTap?.call(),
                padding: EdgeInsets.zero,
                tooltip: 'Cover options',
                splashRadius: 14,
              ),
            ),
            // Duration
            if (showDuration)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  FileUtils.formatDuration(duration),
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    if (song.coverArtPath != null && File(song.coverArtPath!).existsSync()) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(song.coverArtPath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultLeading(theme),
        ),
      );
    }
    return _defaultLeading(theme);
  }

  Widget _defaultLeading(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Icon(
        Icons.music_note,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
