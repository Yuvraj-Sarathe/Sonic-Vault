import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/audio/audio_service.dart';
import 'core/theme/accent_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/library/views/library_view.dart';
import 'features/browse/views/browse_view.dart';
import 'features/player/views/player_view.dart';
import 'features/playlists/views/playlists_view.dart';
import 'features/playlists/views/create_playlist_dialog.dart';
import 'features/settings/views/settings_view.dart';
import 'providers/audio_providers.dart';
import 'providers/song_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/library',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => NoTransitionPage(
              child: LibraryView(key: state.pageKey),
            ),
          ),
          GoRoute(
            path: '/browse',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BrowseView(key: state.pageKey),
            ),
          ),
          GoRoute(
            path: '/playlists',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PlaylistsView(key: state.pageKey),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlayerView(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );
});

class SonicVaultApp extends ConsumerWidget {
  const SonicVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SonicVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(accent),
      routerConfig: router,
    );
  }
}

/// Shell with bottom navigation bar and mini-player area.
class _ShellScreen extends ConsumerWidget {
  final Widget child;

  const _ShellScreen({required this.child});

  /// Returns true if an [EditableText] has focus, indicating a text input field.
  static bool _isTextFieldFocused(BuildContext context) {
    FocusNode? node = Focus.of(context);
    while (node != null) {
      if (node.context?.widget is EditableText) return true;
      node = node.parent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Determine current tab index from location
    final location = GoRouterState.of(context).uri.toString();
    final tabIndex = switch (location) {
      '/library' => 0,
      '/browse' => 1,
      String l when l.startsWith('/playlists') => 2,
      _ => 0,
    };

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!_isTextFieldFocused(context)) {
            ref.read(audioServiceProvider).togglePlayPause();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyN):
            () => ref.read(audioServiceProvider).next(),
        const SingleActivator(LogicalKeyboardKey.keyP):
            () => ref.read(audioServiceProvider).previous(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            () => ref.read(audioServiceProvider).seekRelative(const Duration(seconds: 5)),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            () => ref.read(audioServiceProvider).seekRelative(const Duration(seconds: -5)),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          _MiniPlayerBar(),
        ],
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: tabIndex,
        onTap: (index) {
          // Pop any pushed routes (e.g. PlaylistDetailView) on the shell
          // navigator before switching tabs, so tab switching works reliably.
          Navigator.of(context).popUntil((route) => route.isFirst);
          switch (index) {
            case 0:
              router.go('/library');
            case 1:
              router.go('/browse');
            case 2:
              router.go('/playlists');
          }
        },
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.library_music_outlined),
            activeIcon: const Icon(Icons.library_music),
            title: const Text('Library'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            title: const Text('Browse'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.queue_music_outlined),
            activeIcon: const Icon(Icons.queue_music),
            title: const Text('Playlists'),
          ),
        ],
      ),
      floatingActionButton: tabIndex == 2
          ? FloatingActionButton.small(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CreatePlaylistDialog(),
              ),
              child: const Icon(Icons.add),
            )
          : null,
        ),
      ),
    );
  }
}

/// Mini player bar displayed above the bottom navigation.
class _MiniPlayerBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(playerBarStateProvider);
    final state = stateAsync.asData?.value;
    final hasSong = state?.currentSong != null;
    final songsAsync = ref.watch(allSongsProvider);

    return GestureDetector(
      onTap: hasSong ? () => context.go('/player') : null,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Cover art placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state?.currentSong?.title ?? 'No Track',
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state?.currentSong?.artist ?? 'Select a song',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play random from queue (always available)
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  final service = ref.read(audioServiceProvider);
                  if (service.queue.isEmpty) {
                    final songs = songsAsync.asData?.value;
                    if (songs != null && songs.isNotEmpty) {
                      final refs = songs.map((s) => s.toSongRef()).toList();
                      final r = Random().nextInt(refs.length);
                      service.setQueue(refs, startIndex: r);
                    }
                  } else {
                    service.playRandom();
                  }
                },
                tooltip: 'Play Random',
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 20),
                onPressed: hasSong
                    ? () => ref.read(audioServiceProvider).previous()
                    : null,
                tooltip: 'Previous',
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    (state?.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  onPressed: hasSong
                      ? () => ref.read(audioServiceProvider).togglePlayPause()
                      : null,
                  color: Colors.white,
                  tooltip: (state?.isPlaying ?? false) ? 'Pause' : 'Play',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20),
                onPressed: hasSong
                    ? () => ref.read(audioServiceProvider).next()
                    : null,
                tooltip: 'Next',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// A simple bottom navigation bar widget (no external dep needed)
// ----------------------------------------------------------------
class SalomonBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SalomonBottomBarItem> items;

  const SalomonBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isSelected
                            ? (item.activeIcon ?? item.icon)
                            : item.icon,
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.white54,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          child: item.title,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SalomonBottomBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final Widget title;

  const SalomonBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.title,
  });
}
