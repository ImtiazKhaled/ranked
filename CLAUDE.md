# CLAUDE.md — "Ranked"

Guidance for working in this repo. Read this first.

## What this is

**Ranked** is a **Flutter web app** for logging and ranking personal "moments."
Each entry is a *score* of a moment with a summary, description, a tier grade, an
emotion picked from a 3-tier emotion wheel, tags, and an optional image. Entries
render as a Pinterest-style masonry board grouped by time. Everything is stored
**locally in the browser (IndexedDB)** — there is **no backend and no auth**; data
is intentionally device/browser specific.

- App/brand name shown to users: **Ranked** (browser tab, list header).
- The create/edit entry screen heading reads **"New rank" / "Edit rank"**.
- Dart package name is `ranked` (see `pubspec.yaml`).

## Run / build / test

```bash
flutter run -d chrome      # or: -d edge   (dev, hot reload: r / R / q)
flutter analyze            # keep clean — 0 issues expected
flutter test               # unit tests in test/widget_test.dart
flutter build web --no-tree-shake-icons   # production bundle -> build/web
```

Toolchain: Flutter 3.44.1 / Dart 3.12.1 (stable). Web-only (`flutter create` was
run with `--platforms web`).

## Tech stack

- **State**: `flutter_riverpod` (StateNotifier + derived Providers).
- **Storage**: `hive_ce` / `hive_ce_flutter` → IndexedDB on web.
- **Masonry**: `flutter_staggered_grid_view` (`SliverMasonryGrid`).
- **Routing**: `go_router`.
- **Other**: `image_picker`, `uuid`, `intl`, `google_fonts` (Inter).

> `hive_ce_generator` / `build_runner` are dev deps but are **not used** — models
> are stored as plain `Map`s (Hive natively handles `Map`, `DateTime`,
> `Uint8List`, `List`, primitives), so there are **no generated `.g.dart`
> adapters and no codegen step**. Keep it that way unless there's a strong reason.

## Architecture / layout

```
lib/
  main.dart            # Hive init + ProviderScope (overrides localStoreProvider)
  app.dart             # MaterialApp.router, go_router routes, AppTheme.light
  data/
    emotion_wheel_data.dart  # the 7→secondary→tertiary emotion taxonomy + colors
    local_store.dart         # opens Hive boxes 'entries' & 'tags'
  models/  entry.dart tag.dart emotion.dart tier.dart   # plain + toMap/fromMap
  providers/providers.dart   # ALL providers (entries, tags, ranked, filter, sections)
  utils/
    color_from_string.dart   # deterministic tag colours (name -> stable HSL)
    date_grouping.dart       # groups entries into timeline sections
  theme/  app_theme.dart (light) + gradients.dart
  widgets/ gradient_border_box.dart, tier_badge.dart, tag_chip.dart
  features/
    entries/ list_screen.dart, entry_card.dart
    editor/  entry_editor_screen.dart, tier_selector.dart, tag_multiselect.dart
    emotion/ emotion_picker.dart          # the custom emotion-wheel dial
```

Routes (`app.dart`): `/` → list, `/entry/new` → create, `/entry/:id` → edit.

## Domain model & conventions

- **Entry** (`models/entry.dart`): id, summary, description, `Tier`, `EmotionRef?`,
  `tagIds: List<String>`, `imageBytes: Uint8List?`, createdAt/updatedAt.
  Persisted via `toMap()`/`fromMap()` into the `entries` Hive box keyed by id.
- **Tier** (`models/tier.dart`): enum `S/A/B/C/D`, each with a fixed gradient/colors.
  This is the entry's "score". Rendered by `widgets/tier_badge.dart`.
- **Tag** (`models/tag.dart`): id + name only. **Colour and usage count are NOT
  stored** — colour is derived from the name (`utils/color_from_string.dart`) so it's
  consistent everywhere; usage is computed live in `rankedTagsProvider`. Tags are
  surfaced **ranked by usage** in both the filter bar and the create-tag multiselect.
- **EmotionRef** (`models/emotion.dart`): the chosen path primary→secondary→tertiary
  + leaf emoji; colour derived from its primary via `primaryEmotionColor()`.
- **Timeline grouping** (`utils/date_grouping.dart`): every day in the current week
  gets its own section (Today / Yesterday / weekday); older entries bundle into
  "Week of Mon DD – Sun DD".
- **Filtering**: tag filter uses **OR** semantics (`visibleSectionsProvider`).

### Providers (all in `providers/providers.dart`)
`localStoreProvider` (overridden in main) · `entriesProvider` (StateNotifier CRUD) ·
`entryByIdProvider` · `tagsProvider` (+ `createOrGet`) · `rankedTagsProvider`
(usage-ranked) · `filterProvider` (active tag ids) · `visibleSectionsProvider`
(filtered + grouped timeline).

## The emotion wheel (`features/emotion/emotion_picker.dart`)

The most custom piece. A hover/tap flyout ("dial") anchored to the "Add emotion"
button — FB-reaction style, three tiers deep.

- Opens on hover (desktop) or on press-and-drag / tap (touch) via `OverlayPortal` +
  `CompositedTransformFollower`. Hover-forgiving close (180 ms timer).
- Three **concentric solid arc "cylinder" bands** (`_BandPainter`), one per tier.
  Base radii `_kR1=116 / _kR2=196 / _kR3=276` (kept **equidistant**, 80px gaps),
  band thickness `_kBand=66` — all multiplied by a runtime **`_scale`**.
- Emojis are bare (no container) with **bold labels** underneath (`FittedBox`
  scale-down so long names fit). Each node is **two boxes**: a wide,
  `IgnorePointer` visual and a narrow hit target one arc-step wide, so taps and
  hovers land on the emotion they look like they landed on.
- **Fitting the viewport** — `_measure()` (on open + on MediaQuery change) records
  the trigger's centre and the free space around it, then picks `_scale`.
  `_window(r)` returns the angular window per tier: the tuned desktop lean
  (`_kLeftReachPx` / `_kRightCap`) **intersected** with caps derived from the real
  screen edges. On a wide screen the screen caps are inert and the fan keeps its
  clockwise right-lean; on a phone they swing it upward so tier 3 stays reachable.
  Tuning knobs: **`_kLeftReachPx`** (pull fan left/right), **`_kRightCap`** (lean).
- **Two things that will silently break the hinge** if you touch them:
  1. The dial box is a square centred on the hinge and is **wider than a phone
     screen** — it must be sized by the `Positioned` in `_buildOverlay`, or the
     Stack's loose constraints squeeze it and slide the hinge off the button.
  2. The trigger has a **fixed-width label column** (`_kLabelWidth`). The live
     preview swaps in names of very different lengths; letting the button resize
     drags the whole dial around under the cursor mid-selection.
- **Touch**: a `PanGestureRecognizer` on the trigger with a tight `touchSlop` (so it
  beats the editor's `ListView` in the gesture arena) — press, slide out through
  the tiers, lift on a tertiary to commit. `_hitTest()` resolves the finger to a
  node analytically from polar coordinates rather than by widget hit-testing.
  Lifting off the bands selects nothing and leaves the dial open for tap-to-drill.
- Covered by `test/emotion_picker_test.dart`, which asserts every
  primary/secondary pair keeps its tertiary leaves on screen at 390×844.
- The trigger button **live-previews** the hovered emotion; the parent path
  (`Primary › Secondary`) shows **above** the leaf name. Clicking a tertiary commits.
- Emotion taxonomy + per-primary colours live in `data/emotion_wheel_data.dart`
  (provided by the user; keep verbatim).

## Theme

Light theme in `theme/app_theme.dart`. Use the semantic colours
`AppTheme.textMuted` and `AppTheme.hairline` for secondary text / borders — do
**not** hardcode `Colors.white...` for muted UI (it was a dark-theme habit and is
invisible on the light background). Cards/fields use gradient borders via
`widgets/gradient_border_box.dart`.

## Gotchas

- **No `Material` ancestor → yellow underline on `Text`.** Any custom overlay must
  sit under a `Material`/`MaterialType.transparency` (this bit the emotion wheel).
- Images are downscaled on pick (~1280px) before storing bytes to keep IndexedDB lean.
- Keep `flutter analyze` at **0 issues**; wildcard params use single `_` (Dart 3.7+).
