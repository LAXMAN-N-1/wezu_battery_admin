import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend_admin/main.dart';
import 'package:frontend_admin/router/app_router.dart';

void main() {
  testWidgets('boots app with configured router override', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Test Login Route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test Login Route'), findsOneWidget);
  });
}
