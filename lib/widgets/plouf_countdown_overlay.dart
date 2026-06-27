import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/sound_feedback.dart';

/// Compte à rebours « 3, 2, 1, PloufPlouf! » avant un tirage.
class PloufCountdownOverlay {
  PloufCountdownOverlay._();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, child) => const _CountdownBody(),
    );
  }
}

class _CountdownBody extends StatefulWidget {
  const _CountdownBody();

  @override
  State<_CountdownBody> createState() => _CountdownBodyState();
}

class _CountdownBodyState extends State<_CountdownBody>
    with SingleTickerProviderStateMixin {
  static const _finalStep = 'PloufPlouf!';
  static const _steps = ['3', '2', '1', _finalStep];
  int _index = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      _pulse.forward(from: 0);
      if (i < 3) {
        SoundFeedback.tick();
      } else {
        SoundFeedback.plouf();
      }
      await Future<void>.delayed(
        Duration(milliseconds: i == _steps.length - 1 ? 700 : 550),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _steps[_index];
    final isPlouf = text == _finalStep;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(parent: _pulse, curve: Curves.elasticOut),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isPlouf ? 36 : 48,
              vertical: 36,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Text(
              text,
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: isPlouf ? 36 : 64,
                letterSpacing: isPlouf ? -0.5 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
