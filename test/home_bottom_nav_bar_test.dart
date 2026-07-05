import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CherryBottomNavBar hides deferred MVP features', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CherryBottomNavBar(
            selectedIndex: 0,
            onItemSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Give'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Inbox'), findsNothing);
    expect(find.text('Search'), findsNothing);
  });
}
