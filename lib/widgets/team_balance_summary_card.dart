import 'package:flutter/material.dart';

import '../utils/team_balance_summary.dart';

/// Jauge de confiance après un tirage d'équipes.
class TeamBalanceSummaryCard extends StatelessWidget {
  const TeamBalanceSummaryCard({
    super.key,
    required this.summary,
  });

  final TeamBalanceSummary summary;

  Color _scoreColor(BuildContext context) {
    if (summary.scorePercent >= 85) {
      return const Color(0xFF2E7D32);
    }
    if (summary.scorePercent >= 60) {
      return const Color(0xFFF57C00);
    }
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(context);

    return Material(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded, color: scoreColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bilan du tirage',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary.scorePercent} %',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: summary.scorePercent / 100,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 12),
            ...summary.highlights.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      line.contains('non respectée') || line.contains('ajuster')
                          ? Icons.info_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: line.contains('non respectée') || line.contains('ajuster')
                          ? theme.colorScheme.tertiary
                          : scoreColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
