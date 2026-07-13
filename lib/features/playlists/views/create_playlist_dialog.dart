import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/playlist_providers.dart';

/// Dialog for creating a new playlist with name validation.
class CreatePlaylistDialog extends ConsumerStatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  ConsumerState<CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Playlist'),
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
          onFieldSubmitted: (_) => _create(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _create,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(playlistDaoProvider);
    final now = DateTime.now();
    await dao.insertPlaylist(PlaylistsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(_nameController.text.trim()),
      dateCreated: Value(now),
      dateModified: Value(now),
      sortOrder: const Value(0),
    ));
    ref.invalidate(allPlaylistsProvider);
    if (mounted) Navigator.pop(context);
  }
}
