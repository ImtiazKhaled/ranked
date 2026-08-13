import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranked/data/emotion_wheel_data.dart';
import 'package:ranked/features/emotion/emotion_picker.dart';
import 'package:ranked/models/emotion.dart';

/// A stand-in for the editor form: a scrolling column with the picker roughly
/// where "Emotion" sits, so the dial has to cope with a real anchor position.
Widget _harness({EmotionRef? value, ValueChanged<EmotionRef?>? onChanged}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('New rank')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 300), // Summary / Description / Rank
              EmotionPicker(value: value, onChanged: onChanged ?? (_) {}),
              const SizedBox(height: 400),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The full box a node paints into (emoji + label), not just its label.
///
/// The trigger button previews the name you're on, so the same text can appear
/// twice; the node's own [IgnorePointer] wrapper is the smallest box of the
/// candidates (route-level IgnorePointers cover the whole page).
Rect _nodeRect(WidgetTester tester, String name) {
  final boxes = find
      .ancestor(of: find.text(name), matching: find.byType(IgnorePointer))
      .evaluate()
      .map((e) => e.renderObject! as RenderBox)
      .map((b) => b.localToGlobal(Offset.zero) & b.size)
      .toList()
    ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));

  expect(boxes, isNotEmpty, reason: 'no node box rendered for "$name"');
  return boxes.first;
}

/// Taps a node dead centre. Labels are pointer-transparent — the hit target is
/// a separate, narrower box centred on the same point — so tap by position.
Future<void> _tapNode(WidgetTester tester, String name) async {
  await tester.tapAt(_nodeRect(tester, name).center);
  await tester.pumpAndSettle();
}

/// Walks the dial down to [primary] › [secondary] by tapping.
Future<void> _openTo(
  WidgetTester tester,
  String primary,
  String secondary,
) async {
  await tester.tap(find.text('Add emotion'));
  await tester.pumpAndSettle();

  await _tapNode(tester, primary);
  await _tapNode(tester, secondary);
}

void main() {
  group('emotion dial on a phone viewport', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first;
      view.physicalSize = const Size(390 * 3, 844 * 3); // iPhone-ish
      view.devicePixelRatio = 3;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first;
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    testWidgets('every tertiary leaf stays inside the screen', (tester) async {
      const screen = Rect.fromLTWH(0, 0, 390, 844);
      final problems = <String>[];

      // Check every primary/secondary pair — the widest fans overflow first.
      for (final primary in kEmotionWheel) {
        for (final secondary in primary.children) {
          final path = '${primary.name} › ${secondary.name}';

          // Tear the tree down so each pair starts from a closed dial.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(_harness());
          await tester.pumpAndSettle();

          await _openTo(tester, primary.name, secondary.name);

          for (final leaf in secondary.children) {
            if (find.text(leaf.name).evaluate().isEmpty) {
              problems.add('$path › ${leaf.name}: never rendered');
              continue;
            }
            final r = _nodeRect(tester, leaf.name);
            if (!screen.contains(r.topLeft) || !screen.contains(r.bottomRight)) {
              problems.add('$path › ${leaf.name}: box $r is outside $screen');
            }
          }
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    testWidgets('the dial hinges on the centre of the trigger button',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(CompositedTransformTarget));

      await tester.tap(find.text('Add emotion'));
      await tester.pumpAndSettle();

      // Primaries all sit on one circle; its centre is the dial's hinge.
      final hinge = _fitCircleCentre(
        [for (final p in kEmotionWheel) _nodeRect(tester, p.name).center],
      );

      expect((hinge.dx - button.center.dx).abs(), lessThan(2),
          reason: 'hinge $hinge is not horizontally centred on $button');
      expect((hinge.dy - button.center.dy).abs(), lessThan(2),
          reason: 'hinge $hinge is not vertically centred on $button');
    });

    testWidgets('tapping through the tiers commits the leaf', (tester) async {
      EmotionRef? picked;
      await tester.pumpWidget(_harness(onChanged: (e) => picked = e));
      await tester.pumpAndSettle();

      await _openTo(tester, 'Happy', 'Optimistic');
      await _tapNode(tester, 'Hopeful');

      expect(picked, isNotNull);
      expect(picked!.primary, 'Happy');
      expect(picked!.secondary, 'Optimistic');
      expect(picked!.tertiary, 'Hopeful');
    });

    testWidgets('dragging out and lifting on a leaf commits it', (tester) async {
      EmotionRef? picked;
      await tester.pumpWidget(_harness(onChanged: (e) => picked = e));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(CompositedTransformTarget));

      // Press the button, then slide out through the tiers without lifting.
      // The first move is what wins the drag and opens the dial.
      final drag = await tester.startGesture(button.center);
      await drag.moveBy(const Offset(0, -30));
      await tester.pumpAndSettle();

      await drag.moveTo(_nodeRect(tester, 'Happy').center);
      await tester.pumpAndSettle();

      await drag.moveTo(_nodeRect(tester, 'Optimistic').center);
      await tester.pumpAndSettle();

      final leaf = _nodeRect(tester, 'Hopeful').center;
      await drag.moveTo(leaf);
      await tester.pumpAndSettle();

      // Lifting off the leaf is what selects it.
      expect(picked, isNull);
      await drag.up();
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.tertiary, 'Hopeful');
    });

    testWidgets('lifting off the bands selects nothing and keeps the dial open',
        (tester) async {
      EmotionRef? picked;
      var changed = false;
      await tester.pumpWidget(_harness(onChanged: (e) {
        picked = e;
        changed = true;
      }));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(CompositedTransformTarget));
      final drag = await tester.startGesture(button.center);
      await drag.moveBy(const Offset(0, -30));
      await tester.pumpAndSettle();

      await drag.moveTo(_nodeRect(tester, 'Happy').center);
      await tester.pumpAndSettle();
      await drag.moveTo(const Offset(370, 820)); // empty corner
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();

      expect(changed, isFalse);
      expect(picked, isNull);
      // Still open, so the tap-to-drill fallback keeps working.
      expect(find.text('Optimistic'), findsOneWidget);
    });
  });

  testWidgets('the clear button sits flush against the emotion button',
      (tester) async {
    EmotionRef? picked = const EmotionRef(
      primary: 'Happy',
      secondary: 'Optimistic',
      tertiary: 'Hopeful',
      emoji: '🌱',
    );
    await tester
        .pumpWidget(_harness(value: picked, onChanged: (e) => picked = e));
    await tester.pumpAndSettle();

    final label = tester.getRect(find.text('Hopeful'));
    final clear = tester.getRect(find.byIcon(Icons.close_rounded));

    // One pill: the clear half is immediately right of the emotion half and
    // shares its vertical centre.
    expect(clear.center.dx, greaterThan(label.right));
    expect((clear.center.dy - label.center.dy).abs(), lessThan(16));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });
}

/// Least-squares centre of the circle through [points] (Kåsa's linear fit).
Offset _fitCircleCentre(List<Offset> points) {
  var sx = 0.0, sy = 0.0, sxx = 0.0, syy = 0.0, sxy = 0.0;
  var sxz = 0.0, syz = 0.0, sz = 0.0;
  for (final p in points) {
    final z = p.dx * p.dx + p.dy * p.dy;
    sx += p.dx;
    sy += p.dy;
    sxx += p.dx * p.dx;
    syy += p.dy * p.dy;
    sxy += p.dx * p.dy;
    sxz += p.dx * z;
    syz += p.dy * z;
    sz += z;
  }
  final n = points.length.toDouble();
  final a = 2 * (sxx - sx * sx / n);
  final b = 2 * (sxy - sx * sy / n);
  final c = 2 * (syy - sy * sy / n);
  final d = sxz - sx * sz / n;
  final e = syz - sy * sz / n;
  final det = a * c - b * b;
  return Offset((d * c - e * b) / det, (a * e - b * d) / det);
}
