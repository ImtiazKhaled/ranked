import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/emotion_wheel_data.dart';
import '../../models/emotion.dart';

/// A trigger button that opens the multi-tier radial emotion wheel and reports
/// the chosen [EmotionRef]. Works with mouse hover (drill in by hovering) and
/// with tap (drill in by tapping) for touch devices.
class EmotionPicker extends StatelessWidget {
  const EmotionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EmotionRef? value;
  final ValueChanged<EmotionRef?> onChanged;

  Future<void> _open(BuildContext context) async {
    final selected = await showGeneralDialog<EmotionRef>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Emotion wheel',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value.clamp(0, 1),
          child: Transform.scale(
            scale: 0.85 + 0.15 * curved.value,
            child: Center(
              child: EmotionWheel(
                initial: value,
                onSelected: (e) => Navigator.of(ctx).pop(e),
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (v?.color ?? Colors.white).withValues(alpha: 0.5),
                width: 1.5,
              ),
              color: (v?.color ?? Colors.white).withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(v?.emoji ?? '😶', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v == null ? 'Add emotion' : v.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (v != null)
                      Text(
                        '${v.primary} › ${v.secondary}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (v != null)
          IconButton(
            tooltip: 'Clear emotion',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}

/// The radial wheel itself: concentric rings of primary -> secondary ->
/// tertiary emotions that expand as you hover/tap inward-out.
class EmotionWheel extends StatefulWidget {
  const EmotionWheel({super.key, required this.onSelected, this.initial});

  final EmotionRef? initial;
  final ValueChanged<EmotionRef> onSelected;

  @override
  State<EmotionWheel> createState() => _EmotionWheelState();
}

class _EmotionWheelState extends State<EmotionWheel> {
  static const double _size = 620;
  static const Offset _center = Offset(_size / 2, _size / 2);
  static const double _r1 = 118; // primaries
  static const double _r2 = 210; // secondaries
  static const double _r3 = 288; // tertiaries

  int? _activePrimary; // index into kEmotionWheel
  int? _activeSecondary; // index into active primary's children

  EmotionNode? _hoverTertiary;
  EmotionNode? _hoverSecondary;
  EmotionNode? _hoverPrimary;

  @override
  void initState() {
    super.initState();
    // Pre-open to the initial selection's branch if present.
    final init = widget.initial;
    if (init != null) {
      final pi = kEmotionWheel.indexWhere((p) => p.name == init.primary);
      if (pi >= 0) {
        _activePrimary = pi;
        final si =
            kEmotionWheel[pi].children.indexWhere((s) => s.name == init.secondary);
        if (si >= 0) _activeSecondary = si;
      }
    }
  }

  Offset _polar(double radius, double angle) => Offset(
        _center.dx + radius * math.cos(angle),
        _center.dy + radius * math.sin(angle),
      );

  double _primaryAngle(int i) =>
      -math.pi / 2 + i * (2 * math.pi / kEmotionWheel.length);

  @override
  Widget build(BuildContext context) {
    final maxSide = MediaQuery.of(context).size.shortestSide - 48;
    final scale = (maxSide / _size).clamp(0.4, 1.0);

    final centerLabel = _hoverTertiary?.name ??
        _hoverSecondary?.name ??
        _hoverPrimary?.name ??
        (_activePrimary != null ? kEmotionWheel[_activePrimary!].name : 'How do you feel?');
    final centerEmoji = _hoverTertiary?.emoji ??
        _hoverSecondary?.emoji ??
        _hoverPrimary?.emoji ??
        (_activePrimary != null ? kEmotionWheel[_activePrimary!].emoji : '🎡');
    final centerColor = _activePrimary != null
        ? primaryEmotionColor(kEmotionWheel[_activePrimary!].name)
        : Colors.white;

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Center hub.
            Positioned(
              left: _center.dx - 70,
              top: _center.dy - 70,
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15151F),
                  border: Border.all(
                    color: centerColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: centerColor.withValues(alpha: 0.25),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(centerEmoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        centerLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tertiaries (deepest ring) for the active secondary.
            if (_activePrimary != null && _activeSecondary != null)
              ..._buildTertiaries(),

            // Secondaries for the active primary.
            if (_activePrimary != null) ..._buildSecondaries(),

            // Primaries (always visible).
            ..._buildPrimaries(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrimaries() {
    return [
      for (var i = 0; i < kEmotionWheel.length; i++)
        _node(
          node: kEmotionWheel[i],
          pos: _polar(_r1, _primaryAngle(i)),
          diameter: 62,
          color: primaryEmotionColor(kEmotionWheel[i].name),
          active: _activePrimary == i,
          onEnter: () => setState(() {
            _activePrimary = i;
            _activeSecondary = null;
            _hoverPrimary = kEmotionWheel[i];
            _hoverSecondary = null;
            _hoverTertiary = null;
          }),
          onTap: () => setState(() {
            _activePrimary = i;
            _activeSecondary = null;
          }),
        ),
    ];
  }

  List<Widget> _buildSecondaries() {
    final primary = kEmotionWheel[_activePrimary!];
    final color = primaryEmotionColor(primary.name);
    final base = _primaryAngle(_activePrimary!);
    final n = primary.children.length;
    // Fan the secondaries in an arc centred on the primary's angle.
    const spread = math.pi * 1.15;
    final step = n > 1 ? spread / (n - 1) : 0;
    return [
      for (var i = 0; i < n; i++)
        Builder(builder: (_) {
          final angle = base - spread / 2 + step * i;
          return _node(
            node: primary.children[i],
            pos: _polar(_r2, angle),
            diameter: 54,
            color: color,
            active: _activeSecondary == i,
            onEnter: () => setState(() {
              _activeSecondary = i;
              _hoverSecondary = primary.children[i];
              _hoverTertiary = null;
            }),
            onTap: () => setState(() => _activeSecondary = i),
          );
        }),
    ];
  }

  List<Widget> _buildTertiaries() {
    final primary = kEmotionWheel[_activePrimary!];
    final secondary = primary.children[_activeSecondary!];
    final color = primaryEmotionColor(primary.name);
    final base = _primaryAngle(_activePrimary!);
    final n = primary.children.length;
    const spread = math.pi * 1.15;
    final step = n > 1 ? spread / (n - 1) : 0;
    final secAngle = base - spread / 2 + step * _activeSecondary!;
    final tCount = secondary.children.length;
    const tSpread = 0.34;
    final tStep = tCount > 1 ? tSpread / (tCount - 1) : 0;
    return [
      for (var i = 0; i < tCount; i++)
        Builder(builder: (_) {
          final angle = secAngle - tSpread / 2 + tStep * i;
          final node = secondary.children[i];
          return _node(
            node: node,
            pos: _polar(_r3, angle),
            diameter: 52,
            color: color,
            active: false,
            highlight: true,
            onEnter: () => setState(() => _hoverTertiary = node),
            onTap: () => widget.onSelected(EmotionRef(
              primary: primary.name,
              secondary: secondary.name,
              tertiary: node.name,
              emoji: node.emoji,
            )),
          );
        }),
    ];
  }

  Widget _node({
    required EmotionNode node,
    required Offset pos,
    required double diameter,
    required Color color,
    required bool active,
    required VoidCallback onEnter,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Positioned(
      left: pos.dx - diameter / 2,
      top: pos.dy - diameter / 2,
      child: MouseRegion(
        onEnter: (_) => onEnter(),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? color.withValues(alpha: 0.9)
                  : const Color(0xFF1E1E2C),
              border: Border.all(
                color: color.withValues(alpha: highlight ? 0.95 : 0.7),
                width: highlight ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: active ? 0.5 : 0.2),
                  blurRadius: active ? 16 : 8,
                ),
              ],
            ),
            child: Text(
              node.emoji,
              style: TextStyle(fontSize: diameter * 0.42),
            ),
          ),
        ),
      ),
    );
  }
}
