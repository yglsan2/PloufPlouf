import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/plouf_fun_messages.dart';
import '../services/pick_fairness_service.dart';
import '../utils/sound_feedback.dart';
import '../utils/wheel_math.dart';

/// Roue des noms plein écran — inspirée Wheel of Names.
class NameWheelScreen extends StatefulWidget {
  const NameWheelScreen({
    super.key,
    required this.names,
    this.favorEquity = true,
    this.onWinner,
  });

  final List<String> names;
  final bool favorEquity;
  final ValueChanged<String>? onWinner;

  static Future<String?> open(
    BuildContext context, {
    required List<String> names,
    bool favorEquity = true,
  }) {
    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut au moins 2 noms pour faire tourner la roue.'),
        ),
      );
      return Future.value(null);
    }
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NameWheelScreen(
          names: names,
          favorEquity: favorEquity,
        ),
      ),
    );
  }

  @override
  State<NameWheelScreen> createState() => _NameWheelScreenState();
}

class _NameWheelScreenState extends State<NameWheelScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late AnimationController _spin;
  double _rotation = 0;
  bool _spinning = false;
  String? _winner;
  final List<String> _history = [];
  List<String> _pool = [];
  bool _eliminationMode = false;

  static const _wheelColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFFAD1457),
    Color(0xFF2E7D32),
    Color(0xFF4527A0),
    Color(0xFF00838F),
    Color(0xFFC62828),
    Color(0xFF5D4037),
  ];

  @override
  void initState() {
    super.initState();
    _pool = List<String>.from(widget.names);
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _spin.addListener(() => setState(() {}));
    _spin.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _onSpinEnd();
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onSpinEnd() {
    final idx = WheelMath.indexAtPointer(_rotation, _pool.length);
    final name = _pool[idx];
    setState(() {
      _spinning = false;
      _winner = name;
      _history.insert(0, name);
    });
    SoundFeedback.win();
    PickFairnessService.instance.beginSession();
    PickFairnessService.instance.recordPicks([name]);
    widget.onWinner?.call(name);
  }

  void _launchSpin() {
    if (_spinning || _pool.length < 2) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _spinning = true;
      _winner = null;
    });
    final winnerIndex = _pool.indexOf(
      PickFairnessService.instance.pickOne(
        _pool,
        _random,
        favorEquity: widget.favorEquity,
      ),
    );
    final target = WheelMath.targetRotation(
      segmentCount: _pool.length,
      winnerIndex: winnerIndex,
      currentRotation: _rotation,
    );
    _rotation = target;
    _spin.duration = Duration(milliseconds: 2800 + _random.nextInt(1200));
    _spin.forward(from: 0);
    SoundFeedback.spin();
  }

  void _removeWinner() {
    if (_winner == null) return;
    setState(() {
      _pool.remove(_winner);
      _winner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = _spin.isAnimating
        ? _rotation * _spin.value
        : _rotation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roue des noms'),
        actions: [
          IconButton(
            tooltip: 'Mode élimination',
            onPressed: _spinning
                ? null
                : () => setState(() => _eliminationMode = !_eliminationMode),
            icon: Icon(
              _eliminationMode ? Icons.filter_1_rounded : Icons.replay_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _spinning
                    ? PloufFunMessages.spinning(_random)
                    : (_winner != null
                        ? PloufFunMessages.winner(_random)
                        : 'Appuyez sur Tourner !'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Transform.rotate(
                          angle: angle,
                          child: CustomPaint(
                            painter: _WheelPainter(
                              names: _pool,
                              colors: _wheelColors,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 48,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_winner != null) ...[
                const SizedBox(height: 8),
                Text(
                  _winner!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_spinning || _pool.length < 2) ? null : _launchSpin,
                icon: _spinning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.casino_rounded),
                label: Text(_spinning ? 'La roue tourne…' : 'Tourner la roue'),
              ),
              if (_eliminationMode && _winner != null && _pool.length > 1) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _removeWinner,
                  icon: const Icon(Icons.person_remove_rounded),
                  label: const Text('Retirer le gagnant et relancer'),
                ),
              ],
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Historique',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _history.length.clamp(0, 8),
                    separatorBuilder: (_, i) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => Chip(
                      label: Text(_history[i]),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.names, required this.colors});

  final List<String> names;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (names.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;
    final slice = 2 * pi / names.length;

    for (var i = 0; i < names.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      final start = -pi / 2 + i * slice;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        slice,
        true,
        paint,
      );

      final textAngle = start + slice / 2;
      final textOffset = Offset(
        center.dx + cos(textAngle) * radius * 0.62,
        center.dy + sin(textAngle) * radius * 0.62,
      );
      _drawLabel(canvas, names[i], textOffset, textAngle + pi / 2);
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1E3A5F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      18,
      Paint()..color = const Color(0xFF1E3A5F),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double angle) {
    final display = text.length > 14 ? '${text.substring(0, 12)}…' : text;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 13,
        fontWeight: ui.FontWeight.w600,
        textAlign: TextAlign.center,
      ),
    )..addText(display);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 90));
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.drawParagraph(
      paragraph,
      Offset(-paragraph.maxIntrinsicWidth / 2, -paragraph.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.names != names;
}
