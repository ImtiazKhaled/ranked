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
              EmotionPicker(
                value: value,
                onChanged: onChanged ?? (_) {},
              ),
              const SizedBox(height: 400),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Walks the dial down to [primary] › [secondary] by tapping, then returns the
/// on-screen rects of the two tertiary leaves that appear.
Future<List<Rect>> _openTo(
  WidgetTester tester,
  String primary,
  String secondary,
) async {
  await tester.tap(find.text('Add emotion'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(primary));
  await tester.pumpAndSettle();

  await tester.tap(find.text(secondary));
  await tester.pumpAndSettle();

  final node = kEmotionWheel
      .firstWhere((p) => p.name == primary)
      .children
      .firstWhere((s) => s.name == secondary);

  return [
    for (final leaf in node.children) tester.getRect(find.text(leaf.name)),
  ];
}

void main() {
  group('emotion dial fits a phone viewport', () {
    setUp(() {
      // iPhone-ish logical size.
      final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
      view.physicalSize = const Size(390 * 3, 844 * 3);
      view.devicePixelRatio = 3;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    testWidgets('every tertiary leaf stays inside the screen', (tester) async {
      const screen = Rect.fromLTWH(0, 0, 390, 844);

      // Check every primary/secondary combination — the widest fans are the
      // ones most likely to overflow.
      for (final primary in kEmotionWheel) {
        for (final secondary in primary.children) {
          await tester.pumpWidget(_harness());
          await tester.pumpAndSettle();

          final rects = await _openTo(tester, primary.name, secondary.name);
          expect(rects, isNotEmpty);

          for (final r in rects) {
            expect(
              screen.contains(r.topLeft) && screen.contains(r.bottomRight),
              isTrue,
              reason: '${primary.name} › ${secondary.name} leaf at $r '
                  'is outside $screen',
            );
          }
        }
      }
    });

    testWidgets('the dial hinges on the centre of the trigger button',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final trigger = tester.getRect(find.text('Add emotion'));
      await tester.tap(find.text('Add emotion'));
      await tester.pumpAndSettle();

      // Primaries all sit on one circle; its centre is the hinge.
      final points = [
        for (final p in kEmotionWheel) tester.getRect(find.text(p.name)).center,
      ];

      // The button's centre is a little left of the label's centre (the emoji
      // sits before it), so derive the hinge from the geometry instead: the
      // radii from the true hinge are all equal.
      final hinge = _fitCircleCentre(points);
      final radii = [for (final p in points) (p - hinge).distance];
      final spread = radii.reduce((a, b) => a > b ? a : b) -
          radii.reduce((a, b) => a < b ? a : b);
      expect(spread, lessThan(6), reason: 'primaries are not concentric');

      // That centre must land on the trigger button, vertically dead-centre.
      expect((hinge.dy - trigger.center.dy).abs(), lessThan(14));
      expect(hinge.dx, greaterThan(trigger.left - 60));
      expect(hinge.dx, lessThan(trigger.right + 10));
    });

    testWidgets('tapping through the tiers commits the leaf', (tester) async {
      EmotionRef? picked;
      await tester.pumpWidget(_harness(onChanged: (e) => picked = e));
      await tester.pumpAndSettle();

      await _openTo(tester, 'Happy', 'Optimistic');
      await tester.tap(find.text('Hopeful'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.primary, 'Happy');
      expect(picked!.secondary, 'Optimistic');
      expect(picked!.tertiary, 'Hopeful');
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
    await tester.pumpWidget(_harness(value: picked, onChanged: (e) => picked = e));
    await tester.pumpAndSettle();

    final label = tester.getRect(find.text('Hopeful'));
    final clear = tester.getRect(find.byIcon(Icons.close_rounded));

    // Same pill: the clear icon is to the right of the label and vertically
    // centred with it, with no gap-sized whitespace between the halves.
    expect(clear.center.dx, greaterThan(label.right));
    expect((clear.center.dy - label.center.dy).abs(), lessThan(16));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });
}

/// Least-squares centre of the circle through [points] (Kåsa's linear fit).
Offset _fitCircleCentre(List<Offset> points) {
  var sx = 0.0, sy = 0.0, sxx = 0.0, syy = 0.0, sxy = 0.0, sxz = 0.0, syz = 0.0;
  var sz = 0.0;
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
