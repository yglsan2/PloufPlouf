import 'package:flutter/material.dart';

import '../services/plouf_sound_service.dart';
import '../services/sound_preferences_service.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  void initState() {
    super.initState();
    SoundPreferencesService.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    SoundPreferencesService.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sounds = SoundPreferencesService.instance;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paramètres',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Personnalisez l\'expérience en classe.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            child: SwitchListTile(
              value: sounds.enabled,
              onChanged: (v) => sounds.setEnabled(v),
              title: const Text('Sons PloufPlouf'),
              subtitle: const Text(
                'Countdown, roue, tirages et équipes — vibrations conservées si coupé',
              ),
              secondary: Icon(
                sounds.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: theme.colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await PloufSoundService.instance.preview(PloufSound.plouf);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aperçu : 3, 2, 1… PloufPlouf !'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Tester le son « PloufPlouf ! »'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.looks_one_rounded, size: 18),
                label: const Text('Tick'),
                onPressed: () => PloufSoundService.instance.preview(PloufSound.tick),
              ),
              ActionChip(
                avatar: const Icon(Icons.casino_rounded, size: 18),
                label: const Text('Roue'),
                onPressed: () => PloufSoundService.instance.preview(PloufSound.spin),
              ),
              ActionChip(
                avatar: const Icon(Icons.emoji_events_rounded, size: 18),
                label: const Text('Victoire'),
                onPressed: () => PloufSoundService.instance.preview(PloufSound.win),
              ),
              ActionChip(
                avatar: const Icon(Icons.groups_rounded, size: 18),
                label: const Text('Équipes'),
                onPressed: () => PloufSoundService.instance.preview(PloufSound.teams),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
