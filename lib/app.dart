import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/editor/entry_editor_screen.dart';
import 'features/entries/list_screen.dart';
import 'theme/app_theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListScreen(),
      routes: [
        GoRoute(
          path: 'entry/new',
          builder: (context, state) => const EntryEditorScreen(),
        ),
        GoRoute(
          path: 'entry/:id',
          builder: (context, state) =>
              EntryEditorScreen(entryId: state.pathParameters['id']),
        ),
      ],
    ),
  ],
);

class RankedApp extends StatelessWidget {
  const RankedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'New Rank',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
