import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/emotion_wheel_data.dart';
import '../../models/emotion.dart';
import '../../theme/app_theme.dart';

/// A trigger that, on hover (or touch-drag), opens an inline dial above it —
/// like the Facebook reaction bar but three tiers deep. Each tier is a solid,
/// curved "cylinder" band radiating from the centre of the trigger button;
/// hovering a primary grows its secondaries on a band outside it, and so on.
/// The trigger's own text previews whichever emotion you're on; clicking (or
/// lifting your finger off) a tertiary attaches it.
///
/// The dial measures the room it has on screen when it opens and scales itself
/// to fit, so on a phone the fan sweeps upward into the space that exists
/// instead of running off the right edge.
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
  // --- base dial geometry (full scale, as tuned on desktop) ---
  static const double _kR1 = 116; // primaries
  static const double _kR2 = 196; // secondaries (gap 80)
  static const double _kR3 = 276; // tertiaries (gap 80 — equidistant)
  static const double _kBand = 66; // band thickness (contains emoji + label)
  static const double _kNodeW = 86; // node hit/label width
  static const double _kRightCap = -28; // fan may dip below the button line
  static const double _kLeftReachPx = 70; // max px a node extends left of hinge
  static const double _kSecondaryStep = 18; // deg between secondaries
  static const double _kTertiaryStep = 20; // deg between tertiaries
  static const double _kEdgePad = 8; // keep this clear of the viewport edge
  static const double _kMinScale = 0.55;

  final GlobalKey _triggerKey = GlobalKey();
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  Timer? _closeTimer;

  int? _activePrimary;
  int? _activeSecondary;

  // Live preview of the currently-hovered node, shown on the trigger button.
  String? _previewEmoji;
  String? _previewLabel;
  String? _previewSubtitle;

  // --- measured when the dial opens: where the hinge is, and its free space ---
  double _scale = 1;
  double _availLeft = double.infinity;
  double _availRight = double.infinity;
  double _availTop = double.infinity;
  Offset _hingeGlobal = Offset.zero;

  // --- touch drag state ---
  bool _touchMode = false;
  int? _dragLeaf; // tertiary index currently under the finger, if any

  // Scaled geometry.
  double get _r1 => _kR1 * _scale;
  double get _r2 => _kR2 * _scale;
  double get _r3 => _kR3 * _scale;
  double get _band => _kBand * _scale;
  double get _nodeW => _kNodeW * _scale;

  /// The dial is a square box centred on the hinge, so anchoring it centre-to-
  /// centre with the button puts the hinge exactly on the button's centre.
  double get _side => 2 * (_r3 + _band / 2 + _nodeW / 2);
  Offset get _hinge => Offset(_side / 2, _side / 2);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_portal.isShowing) _measure();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  // --- open/close with hover forgiveness ---
  void _open() {
    _cancelClose();
    _measure();
    _syncActiveToValue();
    if (!_portal.isShowing) setState(_portal.show);
  }

  void _toggle() => _portal.isShowing ? _close() : _open();

  void _scheduleClose() {
    if (_touchMode) return; // touch dismisses by tapping outside, not by exit
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), _close);
  }

  void _cancelClose() => _closeTimer?.cancel();

  void _close() {
    _closeTimer?.cancel();
    if (!mounted) return;
    _touchMode = false;
    _dragLeaf = null;
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

  // --- measuring the room the dial has ---

  /// Records the trigger's centre and how much space surrounds it, then picks a
  /// scale at which the whole fan fits. Cheap; called on every open and on any
  /// MediaQuery change while open.
  void _measure() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final centre = box.localToGlobal(box.size.center(Offset.zero));
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.viewPaddingOf(context);

    _hingeGlobal = centre;
    _availLeft = math.max(0, centre.dx - safe.left - _kEdgePad);
    _availRight = math.max(0, screen.width - centre.dx - safe.right - _kEdgePad);
    _availTop = math.max(0, centre.dy - safe.top - _kEdgePad);

    // Fit vertically (the fan reaches straight up) and horizontally (it needs
    // one roomy side to lean into, plus a little of the other).
    final vScale = _availTop / (_kR3 + _kBand / 2 + _kEdgePad);
    final wide = math.max(_availLeft, _availRight);
    final narrow = math.min(_availLeft, _availRight);
    final hScale = (wide + 0.35 * narrow) / (_kR3 + _kNodeW / 2);
    _scale = math.min(1.0, math.min(vScale, hScale)).clamp(_kMinScale, 1.0);
  }

  // --- angle helpers ---
  double _rad(double deg) => deg * math.pi / 180;
  double _deg(double rad) => rad * 180 / math.pi;

  Offset _polar(double r, double deg) {
    final a = _rad(deg);
    return Offset(_hinge.dx + r * math.cos(a), _hinge.dy - r * math.sin(a));
  }

  /// The angular window (min, max in degrees) a tier at radius [r] may use: the
  /// tuned desktop lean, tightened by whatever room the viewport actually
  /// leaves on each side. On a wide screen the viewport bounds are inert and
  /// the fan keeps its clockwise right-lean; on a phone they push it upward.
  (double, double) _window(double r) {
    final reach = _nodeW / 2;

    // Aesthetic cap: no node extends more than _kLeftReachPx left of the hinge.
    final leanCap =
        180 - _deg(math.acos((_kLeftReachPx * _scale / r).clamp(0.0, 1.0)));
    // Viewport caps: r*cos(theta) +/- reach must stay inside the screen.
    final leftBound = _deg(math.acos((-(_availLeft - reach) / r).clamp(-1.0, 1.0)));
    final rightBound = _deg(math.acos(((_availRight - reach) / r).clamp(-1.0, 1.0)));

    var lo = math.max(_kRightCap, rightBound);
    var hi = math.min(leanCap, leftBound);
    if (hi < lo) {
      final mid = (lo + hi) / 2;
      lo = mid;
      hi = mid;
    }
    return (lo, hi);
  }

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

  /// Angles for every visible tier, derived purely from current state — so the
  /// drag hit-test and the painted dial can never disagree.
  _DialLayout _layout() {
    final (lo1, hi1) = _window(_r1);
    final primary =
        _arc(kEmotionWheel.length, (lo1 + hi1) / 2, hi1 - lo1, lo1, hi1);

    var secondary = const <double>[];
    if (_activePrimary != null) {
      final m = kEmotionWheel[_activePrimary!].children.length;
      final (lo2, hi2) = _window(_r2);
      final span = math.min(hi2 - lo2, (m - 1) * _kSecondaryStep);
      secondary = _arc(m, primary[_activePrimary!], span, lo2, hi2);
    }

    var tertiary = const <double>[];
    if (_activePrimary != null &&
        _activeSecondary != null &&
        _activeSecondary! < secondary.length) {
      final t = kEmotionWheel[_activePrimary!]
          .children[_activeSecondary!]
          .children
          .length;
      final (lo3, hi3) = _window(_r3);
      final span = math.min(hi3 - lo3, (t - 1) * _kTertiaryStep);
      tertiary = _arc(t, secondary[_activeSecondary!], span, lo3, hi3);
    }

    return _DialLayout(primary, secondary, tertiary);
  }

  // --- touch: press, slide out through the tiers, lift to commit ---

  /// Which node (if any) sits under a global point. Tiers are tested outermost
  /// first so an overlapping tolerance prefers the deeper selection.
  _Hit? _hitTest(Offset global) {
    final local = global - _hingeGlobal; // canvas coords: y grows downward
    final r = local.distance;
    if (r < 1) return null;
    final deg = _deg(math.atan2(-local.dy, local.dx));
    final l = _layout();
    const slop = 12.0;

    for (final (tier, radius, angles) in [
      (3, _r3, l.tertiary),
      (2, _r2, l.secondary),
      (1, _r1, l.primary),
    ]) {
      if (angles.isEmpty) continue;
      if ((r - radius).abs() > _band / 2 + slop) continue;

      var best = 0;
      var bestDelta = double.infinity;
      for (var i = 0; i < angles.length; i++) {
        final d = (angles[i] - deg).abs();
        if (d < bestDelta) {
          bestDelta = d;
          best = i;
        }
      }
      final step = angles.length > 1
          ? (angles[0] - angles[1]).abs()
          : _kSecondaryStep * 2;
      if (bestDelta > step / 2 + _deg(slop / radius)) continue;
      return _Hit(tier, best);
    }
    return null;
  }

  void _onDragStart(DragStartDetails d) {
    _touchMode = true;
    _cancelClose();
    _measure();
    _syncActiveToValue();
    if (!_portal.isShowing) setState(_portal.show);
    _onDragUpdate(d.globalPosition);
  }

  void _onDragUpdate(Offset global) {
    final hit = _hitTest(global);
    if (hit == null) {
      // Off the bands: keep the fan as it is, but lifting here selects nothing.
      if (_dragLeaf != null) setState(() => _dragLeaf = null);
      return;
    }

    switch (hit.tier) {
      case 1:
        if (_activePrimary == hit.index && _dragLeaf == null) return;
        final p = kEmotionWheel[hit.index];
        setState(() {
          _activePrimary = hit.index;
          _activeSecondary = null;
          _dragLeaf = null;
        });
        _setPreview(p.emoji, p.name, '');
      case 2:
        if (_activeSecondary == hit.index && _dragLeaf == null) return;
        final p = kEmotionWheel[_activePrimary!];
        final s = p.children[hit.index];
        setState(() {
          _activeSecondary = hit.index;
          _dragLeaf = null;
        });
        _setPreview(s.emoji, s.name, p.name);
      case 3:
        if (_dragLeaf == hit.index) return;
        final p = kEmotionWheel[_activePrimary!];
        final s = p.children[_activeSecondary!];
        final leaf = s.children[hit.index];
        setState(() => _dragLeaf = hit.index);
        _setPreview(leaf.emoji, leaf.name, '${p.name} › ${s.name}');
    }
  }

  /// Lifting off a tertiary commits it. Lifting anywhere else leaves the dial
  /// open so the tap-to-drill path still works.
  void _onDragEnd() {
    final leaf = _dragLeaf;
    if (leaf == null || _activePrimary == null || _activeSecondary == null) {
      return;
    }
    final p = kEmotionWheel[_activePrimary!];
    final s = p.children[_activeSecondary!];
    final t = s.children[leaf];
    _commit(EmotionRef(
      primary: p.name,
      secondary: s.name,
      tertiary: t.name,
      emoji: t.emoji,
    ));
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
    final borderColor = color.withValues(alpha: 0.5);
    final scheme = Theme.of(context).colorScheme;
    const radius = 16.0;

    // The emotion half. A touch-only pan recognizer with a tight slop sits over
    // it so a drag out of the button wins the gesture arena against the
    // editor's ListView (otherwise reaching for tier 3 would scroll the page).
    final emotionHalf = CompositedTransformTarget(
      key: _triggerKey,
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _open(),
        child: RawGestureDetector(
          gestures: {
            PanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(
                supportedDevices: const {PointerDeviceKind.touch},
              ),
              (r) {
                r.gestureSettings =
                    const DeviceGestureSettings(touchSlop: 4);
                r.onStart = _onDragStart;
                r.onUpdate = (d) => _onDragUpdate(d.globalPosition);
                r.onEnd = (_) => _onDragEnd();
              },
            ),
          },
          child: Material(
            color: color.withValues(alpha: 0.08),
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
    );

    // One pill: the emotion button and (when set) the clear button, fused by a
    // shared border with a hairline between them.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1.5),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                emotionHalf,
                if (v != null) ...[
                  Container(width: 1.5, color: borderColor),
                  Material(
                    color: scheme.error,
                    child: InkWell(
                      onTap: () => widget.onChanged(null),
                      child: Tooltip(
                        message: 'Clear emotion',
                        child: SizedBox(
                          width: 44,
                          child: Center(
                            child: Icon(Icons.close_rounded,
                                size: 18, color: scheme.onError),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
          followerAnchor: Alignment.center,
          child: MouseRegion(
            onEnter: (_) => _cancelClose(),
            onExit: (_) {
              if (_touchMode) return;
              _clearPreview();
              _scheduleClose();
            },
            // Dead space inside the dial box dismisses; node taps win the arena.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Material(
                type: MaterialType.transparency,
                child: _buildDial(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDial() {
    final l = _layout();

    final activeColor = _activePrimary != null
        ? primaryEmotionColor(kEmotionWheel[_activePrimary!].name)
        : AppTheme.accent;

    // Solid, opaque "cylinder" bands — one per visible tier (no big outer disc).
    final bands = <_Band>[
      _Band(_r1, l.primary.first, l.primary.last, _band,
          Color.lerp(Colors.white, activeColor, 0.12)!),
      if (l.secondary.isNotEmpty)
        _Band(_r2, l.secondary.first, l.secondary.last, _band,
            Color.lerp(Colors.white, activeColor, 0.16)!),
      if (l.tertiary.isNotEmpty)
        _Band(_r3, l.tertiary.first, l.tertiary.last, _band,
            Color.lerp(Colors.white, activeColor, 0.20)!),
    ];

    return SizedBox(
      width: _side,
      height: _side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(_side, _side),
            painter: _BandPainter(_hinge, bands),
          ),

          // Tier 3 — tertiaries.
          for (var i = 0; i < l.tertiary.length; i++)
            _node(
              angle: l.tertiary[i],
              radius: _r3,
              emojiSize: _emojiSize(25),
              node: kEmotionWheel[_activePrimary!]
                  .children[_activeSecondary!]
                  .children[i],
              color: activeColor,
              active: _dragLeaf == i,
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
          for (var i = 0; i < l.secondary.length; i++)
            _node(
              angle: l.secondary[i],
              radius: _r2,
              emojiSize: _emojiSize(26),
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
          for (var i = 0; i < l.primary.length; i++)
            _node(
              angle: l.primary[i],
              radius: _r1,
              emojiSize: _emojiSize(27),
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

  /// Emoji and labels shrink with the dial, but only so far — below these
  /// floors a scaled-down wheel stops being readable.
  double _emojiSize(double base) => math.max(18, base * _scale);
  double get _labelSize => math.max(9, 11 * _scale);

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
    return Positioned(
      left: pos.dx - _nodeW / 2,
      top: pos.dy - _band / 2,
      width: _nodeW,
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
                width: _nodeW,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    node.name,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: _labelSize,
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

/// The angles of every visible tier for one frame.
class _DialLayout {
  const _DialLayout(this.primary, this.secondary, this.tertiary);

  final List<double> primary;
  final List<double> secondary;
  final List<double> tertiary;
}

/// A node the finger is over: [tier] is 1, 2 or 3.
class _Hit {
  const _Hit(this.tier, this.index);

  final int tier;
  final int index;
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
