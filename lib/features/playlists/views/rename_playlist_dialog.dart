import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/playlist_providers.dart';

class RenamePlaylistDialog extends ConsumerStatefulWidget {
  final Playlist playlist;

  const RenamePlaylistDialog({super.key, required this.playlist});

  @override
  ConsumerState<RenamePlaylistDialog> createState() => _RenamePlaylistDialogState();
}

class _RenamePlaylistDialogState extends ConsumerState<RenamePlaylistDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Playlist'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            if (value.length > 100) {
              return 'Name must be 100 characters or less';
            }
            return null;
          },
          autofocus: true,
          onFieldSubmitted: (_) => _rename(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rename,
          child: const Text('Rename'),
        ),
      ],
    );
  }

  Future<void> _rename() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(playlistDaoProvider);
    final newName = _nameController.text.trim();

    await dao.updatePlaylist(PlaylistsCompanion(
      id: Value(widget.playlist.id),
      name: Value(newName),
      dateModified: Value(DateTime.now()),
    ));

    ref.invalidate(allPlaylistsProvider);
    if (mounted) Navigator.pop(context);
  }
}
