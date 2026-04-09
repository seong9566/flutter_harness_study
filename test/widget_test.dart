import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_harness_engineering_study/main.dart';

void main() {
  group('MyApp', () {
    testWidgets('앱이 정상적으로 렌더링된다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('MyHomePage가 루트 화면으로 렌더링된다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(MyHomePage), findsOneWidget);
    });
  });

  group('MyHomePage', () {
    testWidgets('앱바 타이틀이 표시된다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('Flutter Demo Home Page'), findsOneWidget);
    });

    testWidgets('초기 카운터 값이 0이다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('안내 문구가 표시된다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(
        find.text('You have pushed the button this many times:'),
        findsOneWidget,
      );
    });

    testWidgets('FAB 버튼이 표시된다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB 탭 시 카운터가 1 증가한다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('FAB 여러 번 탭 시 카운터가 누적 증가한다', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });
  });
}
