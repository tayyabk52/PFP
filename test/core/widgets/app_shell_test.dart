import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfc_app/core/widgets/app_shell.dart';
import 'package:pfc_app/core/widgets/sidebar_nav.dart';
import 'package:pfc_app/core/widgets/bottom_nav.dart';

Widget buildShell({required double width, bool isAdmin = false}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppShell(
          isAdmin: isAdmin,
          child: const SizedBox(key: Key('content')),
        ),
      ),
    ),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('shows SidebarNav on desktop (>1024px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 1200));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
    });

    testWidgets('shows collapsed SidebarNav on tablet (600-1024px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 800));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
      expect(find.byType(ListTile), findsNothing);  // collapsed shows IconButtons
    });

    testWidgets('shows PfcBottomNav on mobile (<600px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 400));
      expect(find.byType(PfcBottomNav), findsOneWidget);
      expect(find.byType(SidebarNav), findsNothing);
    });

    testWidgets('always renders child content', (tester) async {
      await tester.pumpWidget(buildShell(width: 1200));
      expect(find.byKey(const Key('content')), findsOneWidget);
    });

    testWidgets('renders child content on tablet', (tester) async {
      await tester.pumpWidget(buildShell(width: 800));
      expect(find.byKey(const Key('content')), findsOneWidget);
    });

    testWidgets('renders child content on mobile', (tester) async {
      await tester.pumpWidget(buildShell(width: 400));
      expect(find.byKey(const Key('content')), findsOneWidget);
    });

    testWidgets('passes isAdmin flag to SidebarNav on desktop', (tester) async {
      await tester.pumpWidget(buildShell(width: 1200, isAdmin: true));
      final sidebar = tester.widget<SidebarNav>(find.byType(SidebarNav));
      expect(sidebar.isAdmin, isTrue);
    });

    testWidgets('passes isAdmin flag to PfcBottomNav on mobile', (tester) async {
      await tester.pumpWidget(buildShell(width: 400, isAdmin: true));
      final bottomNav = tester.widget<PfcBottomNav>(find.byType(PfcBottomNav));
      expect(bottomNav.isAdmin, isTrue);
    });

    testWidgets('exactly 600px shows SidebarNav (tablet boundary)', (tester) async {
      await tester.pumpWidget(buildShell(width: 600));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
    });

    testWidgets('exactly 1024px shows collapsed SidebarNav (desktop boundary)', (tester) async {
      await tester.pumpWidget(buildShell(width: 1024));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
    });
  });
}
