import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/emotion_wheel_data.dart';
import '../../models/emotion.dart';
import '../../theme/app_theme.dart';

/// A trigger that, on hover (or tap), opens an inline dial above it — like the
/// Facebook reaction bar but three tiers deep. Each tier is a solid, curved
/// "cylinder" band radiating from the centre of the trigger button; hovering a
/// primary grows its secondaries on a band outside it, and so on. The trigger's
/// own text previews whichever emotion you're hovering; clicking a tertiary
/// attaches it.
class EmotionPicker extends StatefulWidget {
  const EmotionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EmotionRef? value;
  final ValueChanged<EmotionRef?> onChanged;

  @override
  State<EmotionPicker> createState() => _EmotionPickerState();
}

class _EmotionPickerState extends State<EmotionPicker> {
  // --- dial geometry ---
  static const double _w = 600;
  static const double _h = 470;
  static const double _bottomPad = 170; // room below hinge for lower-right dip
  // Hinge — anchored to the button's centre via [_followerAnchor].
  static const Offset _hinge = Offset(_w / 2, _h - _bottomPad);
  static const double _r1 = 116; // primaries
  static const double _r2 = 196; // secondaries (gap 80)
  static const double _r3 = 276; // tertiaries (gap 80 — equidistant)
  static const double _band = 66; // band thickness (contains emoji + label)
  static const double _rightCap = -28; // fan may dip below button line (right)
  static const double _leftReachPx = 70; // max px a node extends left of hinge

  // Fractional alignment of the hinge within the fan box (maps to button centre).
  static const Alignment _followerAnchor =
      Alignment(0, ((_h - _bottomPad) / _h) * 2 - 1);

  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  Timer? _closeTimer;

  int? _activePrimary;
  int? _activeSecondary;

  // Live preview of the currently-hovered node, shown on the trigger button.
  String? _previewEmoji;
  String? _previewLabel;
  String? _previewSubtitle;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  // --- open/close with hover forgiveness ---
  void _open() {
    _cancelClose();
    _syncActiveToValue();
    if (!_portal.isShowing) setState(_portal.show);
  }

  void _toggle() => _portal.isShowing ? _close() : _open();

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), _close);
  }

  void _cancelClose() => _closeTimer?.cancel();

  void _close() {
    _closeTimer?.cancel();
    if (!mounted) return;
    _clearPreview();
    if (_portal.isShowing) _portal.hide();
  }

  void _clearPreview() {
    setState(() {
      _previewEmoji = null;
      _previewLabel = null;
      _previewSubtitle = null;
    });
  }

  void _setPreview(String emoji, String label, String subtitle) {
    setState(() {
      _previewEmoji = emoji;
      _previewLabel = label;
      _previewSubtitle = subtitle;
    });
  }

  void _syncActiveToValue() {
    final v = widget.value;
    if (v == null) {
      _activePrimary = null;
      _activeSecondary = null;
      return;
    }
    final pi = kEmotionWheel.indexWhere((p) => p.name == v.primary);
    _activePrimary = pi >= 0 ? pi : null;
    _activeSecondary = pi >= 0
        ? _nullIfNeg(
            kEmotionWheel[pi].children.indexWhere((s) => s.name == v.secondary))
        : null;
  }

  int? _nullIfNeg(int i) => i >= 0 ? i : null;

  void _commit(EmotionRef ref) {
    widget.onChanged(ref);
    _close();
  }

  // --- angle helpers ---
  double _rad(double deg) => deg * math.pi / 180;

  Offset _polar(double r, double deg) {
    final a = _rad(deg);
    return Offset(_hinge.dx + r * math.cos(a), _hinge.dy - r * math.sin(a));
  }

  /// Left-cap angle (deg) for a tier at radius [r], so a node there never
  /// extends more than [_leftReachPx] to the left of the hinge.
  double _leftCap(double r) =>
      180 - math.acos((_leftReachPx / r).clamp(0.0, 1.0)) * 180 / math.pi;

  /// Evenly-spaced angles for [count] items centred on [center] spanning [span]
  /// degrees, clamped to the window [[minDeg], [maxDeg]].
  List<double> _arc(
      int count, double center, double span, double minDeg, double maxDeg) {
    if (count <= 1) return [center.clamp(minDeg, maxDeg)];
    final half = span / 2;
    var start = center + half;
    var end = center - half;
    if (start > maxDeg) {
      final shift = start - maxDeg;
      start -= shift;
      end -= shift;
    }
    if (end < minDeg) {
      final shift = minDeg - end;
      start += shift;
      end += shift;
    }
    if (start > maxDeg) start = maxDeg;
    if (end < minDeg) end = minDeg;
    final step = (start - end) / (count - 1);
    return [for (var i = 0; i < count; i++) start - step * i];
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: _buildTrigger(),
    );
  }

  // --- trigger button ---
  Widget _buildTrigger() {
    final v = widget.value;
    final previewing = _previewEmoji != null;

    final emoji = previewing ? _previewEmoji! : (v?.emoji ?? '😶');
    final label =
        previewing ? _previewLabel! : (v == null ? 'Add emotion' : v.label);
    // Parent path ("primary › secondary") shown ABOVE the leaf name.
    final subtitle = previewing
        ? _previewSubtitle
        : (v != null ? '${v.primary} › ${v.secondary}' : null);

    final color = v?.color ?? AppTheme.accent;

    return Row(
      children: [
        CompositedTransformTarget(
          link: _link,
          child: MouseRegion(
            onEnter: (_) => _open(),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withValues(alpha: 0.5), width: 1.5),
                  color: color.withValues(alpha: 0.08),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        Text(label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (v != null)
          IconButton(
            tooltip: 'Clear emotion',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => widget.onChanged(null),
          ),
      ],
    );
  }

  // --- flyout overlay ---
  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.center,
          followerAnchor: _followerAnchor,
          offset: const Offset(18, 0),
          child: MouseRegion(
            onEnter: (_) => _cancelClose(),
            onExit: (_) {
              _clearPreview();
              _scheduleClose();
            },
            child: _buildDial(),
          ),
        ),
      ],
    );
  }

  Widget _buildDial() {
    final p1Max = _leftCap(_r1);
    final primaryAngles = _arc(kEmotionWheel.length, (p1Max + _rightCap) / 2,
        p1Max - _rightCap, _rightCap, p1Max);

    List<double> secondaryAngles = const [];
    if (_activePrimary != null) {
      final m = kEmotionWheel[_activePrimary!].children.length;
      final p2Max = _leftCap(_r2);
      final span = math.min(p2Max - _rightCap, (m - 1) * 18.0);
      secondaryAngles =
          _arc(m, primaryAngles[_activePrimary!], span, _rightCap, p2Max);
    }

    List<double> tertiaryAngles = const [];
    if (_activePrimary != null && _activeSecondary != null) {
      final t = kEmotionWheel[_activePrimary!]
          .children[_activeSecondary!]
          .children
          .length;
      final p3Max = _leftCap(_r3);
      tertiaryAngles =
          _arc(t, secondaryAngles[_activeSecondary!], 20, _rightCap, p3Max);
    }

    final activeColor = _activePrimary != null
        ? primaryEmotionColor(kEmotionWheel[_activePrimary!].name)
        : AppTheme.accent;

    // Solid, opaque "cylinder" bands — one per visible tier (no big outer disc).
    final bands = <_Band>[
      _Band(_r1, primaryAngles.first, primaryAngles.last, _band,
          Color.lerp(Colors.white, activeColor, 0.12)!),
      if (secondaryAngles.isNotEmpty)
        _Band(_r2, secondaryAngles.first, secondaryAngles.last, _band,
            Color.lerp(Colors.white, activeColor, 0.16)!),
      if (tertiaryAngles.isNotEmpty)
        _Band(_r3, tertiaryAngles.first, tertiaryAngles.last, _band,
            Color.lerp(Colors.white, activeColor, 0.20)!),
    ];

    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(_w, _h),
            painter: _BandPainter(_hinge, bands),
          ),

          // Tier 3 — tertiaries.
          if (_activePrimary != null && _activeSecondary != null)
            for (var i = 0; i < tertiaryAngles.length; i++)
              _node(
                angle: tertiaryAngles[i],
                radius: _r3,
                emojiSize: 25,
                node: kEmotionWheel[_activePrimary!]
                    .children[_activeSecondary!]
                    .children[i],
                color: activeColor,
                active: false,
                onEnter: () {
                  final p = kEmotionWheel[_activePrimary!];
                  final s = p.children[_activeSecondary!];
                  final leaf = s.children[i];
                  _setPreview(leaf.emoji, leaf.name, '${p.name} › ${s.name}');
                },
                onTap: () {
                  final p = kEmotionWheel[_activePrimary!];
                  final s = p.children[_activeSecondary!];
                  final leaf = s.children[i];
                  _commit(EmotionRef(
                    primary: p.name,
                    secondary: s.name,
                    tertiary: leaf.name,
                    emoji: leaf.emoji,
                  ));
                },
              ),

          // Tier 2 — secondaries.
          if (_activePrimary != null)
            for (var i = 0; i < secondaryAngles.length; i++)
              _node(
                angle: secondaryAngles[i],
                radius: _r2,
                emojiSize: 26,
                node: kEmotionWheel[_activePrimary!].children[i],
                color: activeColor,
                active: _activeSecondary == i,
                onEnter: () {
                  final p = kEmotionWheel[_activePrimary!];
                  final s = p.children[i];
                  setState(() => _activeSecondary = i);
                  _setPreview(s.emoji, s.name, p.name);
                },
                onTap: () => setState(() => _activeSecondary = i),
              ),

          // Tier 1 — primaries (always visible, drawn on top).
          for (var i = 0; i < kEmotionWheel.length; i++)
            _node(
              angle: primaryAngles[i],
              radius: _r1,
              emojiSize: 27,
              node: kEmotionWheel[i],
              color: primaryEmotionColor(kEmotionWheel[i].name),
              active: _activePrimary == i,
              onEnter: () {
                final p = kEmotionWheel[i];
                setState(() {
                  _activePrimary = i;
                  _activeSecondary = null;
                });
                _setPreview(p.emoji, p.name, '');
              },
              onTap: () => setState(() {
                _activePrimary = i;
                _activeSecondary = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _node({
    required double angle,
    required double radius,
    required double emojiSize,
    required EmotionNode node,
    required Color color,
    required bool active,
    required VoidCallback onEnter,
    required VoidCallback onTap,
  }) {
    final pos = _polar(radius, angle);
    const nodeWidth = 86.0;
    return Positioned(
      left: pos.dx - nodeWidth / 2,
      top: pos.dy - _band / 2,
      width: nodeWidth,
      height: _band,
      child: MouseRegion(
        onEnter: (_) => onEnter(),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.16 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Text(node.emoji, style: TextStyle(fontSize: emojiSize)),
              ),
              const SizedBox(height: 1),
              // Scale long labels down so they always fit inside the band.
              SizedBox(
                width: nodeWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    node.name,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.05,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                      color: active ? _readable(color) : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A darker, legible variant of a node colour for active labels.
  Color _readable(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}

class _Band {
  final double radius;
  final double startDeg; // larger angle (left)
  final double endDeg; // smaller angle (right)
  final double width;
  final Color color;

  const _Band(this.radius, this.startDeg, this.endDeg, this.width, this.color);
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.hinge, this.bands);

  final Offset hinge;
  final List<_Band> bands;

  double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bands) {
      final rect = Rect.fromCircle(center: hinge, radius: b.radius);
      // Our angles are CCW from +x with y-up; canvas is y-down, so negate.
      final start = -_rad(b.startDeg);
      final sweep = _rad(b.startDeg - b.endDeg);

      // Soft shadow for a raised-cylinder look.
      canvas.save();
      canvas.translate(0, 2);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = b.width
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.restore();

      // Solid opaque band.
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = b.width
          ..strokeCap = StrokeCap.round
          ..color = b.color,
      );
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.bands != bands || old.hinge != hinge;
}
