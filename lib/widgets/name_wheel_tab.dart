import 'package:flutter/material.dart';

import '../services/pick_fairness_service.dart';
import 'name_wheel_screen.dart';

/// Onglet Roue intégré — tire les noms des participants présents.
class NameWheelTab extends StatelessWidget {
  const NameWheelTab({
    super.key,
    required this.names,
    required this.favorEquity,
    required this.onFavorEquityChanged,
  });

  final List<String> names;
  final bool favorEquity;
  final ValueChanged<bool> onFavorEquityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSpin = names.length >= 2;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.casino_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Roue des noms',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canSpin
                        ? '${names.length} élève(s) présent(s) sur la roue.'
                        : 'Cochez au moins 2 élèves présents dans l\'onglet Équipes.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: favorEquity,
            onChanged: onFavorEquityChanged,
            title: const Text('Favoriser l\'équité'),
            subtitle: const Text(
              'Les élèves moins souvent tirés ont plus de chances — idéal pour l\'oral',
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: PickFairnessService.instance,
            builder: (context, _) {
              if (names.isEmpty) return const SizedBox.shrink();
              final neverPicked = names
                  .where((n) => PickFairnessService.instance.pickCount(n) == 0)
                  .length;
              return Material(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.balance_rounded, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          neverPicked > 0
                              ? '$neverPicked élève(s) jamais tiré(s) — l\'équité les favorise'
                              : 'Historique d\'équité actif pour toute la classe',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: canSpin
                ? () => NameWheelScreen.open(
                      context,
                      names: names,
                      favorEquity: favorEquity,
                    )
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ouvrir la roue plein écran'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Astuce : mode élimination pour un tournoi ou un ordre de passage.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
