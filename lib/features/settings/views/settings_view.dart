import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/theme/accent_colors.dart';
import '../../../core/utils/media_scanner.dart';
import '../../../providers/library_providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  double _volume = 0.8;
  String? _musicFolderPath;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _volume = prefs.getDouble('default_volume') ?? 0.8;
      _musicFolderPath = prefs.getString('music_folder_path');
      _isLoadingPrefs = false;
    });
    // Apply persisted volume to audio service
    ref.read(audioServiceProvider).setVolume(_volume);
  }

  Future<void> _onVolumeChanged(double volume) async {
    setState(() => _volume = volume);
    await ref.read(audioServiceProvider).setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_volume', volume);
  }

  Future<void> _pickMusicFolder() async {
    // On Android, we use the native SAF folder picker (content:// tree URI) —
    // the OS handles scoped storage automatically; no MANAGE_EXTERNAL_STORAGE
    // or runtime storage permissions needed.
    // On other platforms (Windows, macOS, Linux), request storage permission.
    if (!Platform.isAndroid) {
      PermissionStatus status = PermissionStatus.granted;
      if (await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Storage permission is required to scan music files.'),
              action: SnackBarAction(
                  label: 'Settings', onPressed: openAppSettings),
            ),
          );
        }
        return;
      }
    }

    // On Android, use the native SAF picker which returns a raw content:// URI.
    // FilePicker.getDirectoryPath converts SAF URIs to filesystem paths,
    // which defeats the tree walker on Android 11+ scoped storage.
    late final String? dirPath;
    if (Platform.isAndroid) {
      dirPath = await MediaScanner.pickFolder();
    } else {
      dirPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );
    }
    if (dirPath == null) return;

    // On Android, persist the SAF tree URI permission so it survives restarts
    // (native picker already persists it, but this is a safety net)
    if (Platform.isAndroid) {
      await MediaScanner.persistFolderPermission(dirPath);
    }

    setState(() => _musicFolderPath = dirPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('music_folder_path', dirPath);
    // Trigger a library scan for the new folder
    if (mounted) {
      ref.read(libraryScanProvider.notifier).scanFolder(dirPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: 'Music Library'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Music Folder'),
                    subtitle: Text(
                      _musicFolderPath ?? 'Not set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickMusicFolder,
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'Audio'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.volume_up_outlined),
                        title: const Text('Default Volume'),
                        subtitle: Text('${(_volume * 100).round()}%'),
                        trailing: SizedBox(
                          width: 160,
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(_volume * 100).round()}%',
                            onChanged: _onVolumeChanged,
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.fast_forward_outlined),
                        title: const Text('Crossfade'),
                        subtitle: const Text('3 seconds'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO(Phase 3): Implement crossfade duration picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Crossfade settings coming in Phase 3'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'Appearance'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Accent Color'),
                    subtitle: Text(accent.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accent.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _showAccentPicker(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'Playback'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.shuffle),
                        title: const Text('Shuffle by Default'),
                        value: false,
                        onChanged: (_) {
                          // TODO(Phase 3): Wire to AudioService defaults
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Shuffle default coming in Phase 3',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.repeat),
                        title: const Text('Repeat Mode'),
                        subtitle: const Text('Off'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO(Phase 3): Wire to AudioService defaults
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Repeat mode default coming in Phase 3',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'About'),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Version'),
                        subtitle: Text('1.3.3'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Licenses'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'SonicVault',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _showAccentPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Accent Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(AccentColors.presets.length, (i) {
                  final c = AccentColors.presets[i];
                  final isSelected =
                      ref.watch(accentColorProvider).name == c.name;
                  return GestureDetector(
                    onTap: () {
                      ref.read(accentColorProvider.notifier).setAccent(i);
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? c.color : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
