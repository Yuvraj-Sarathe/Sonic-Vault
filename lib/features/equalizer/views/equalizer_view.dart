import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/audio_constants.dart';

class EqualizerView extends ConsumerWidget {
  const EqualizerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Equalizer Coming Soon',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Fine-tune your audio with ${AudioConstants.eqBandCount}-band EQ',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AudioConstants.eqPresets.keys.map((preset) {
                return FilterChip(
                  label: Text(preset),
                  selected: false,
                  onSelected: (_) {},
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
