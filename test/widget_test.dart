// Basic Flutter widget test for PloufPlouf.

import 'package:flutter_test/flutter_test.dart';

import 'package:tirage_equipes/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const PloufPloufApp());

    expect(find.text('PloufPlouf'), findsOneWidget);
    expect(find.text('Équipes'), findsOneWidget);
    expect(find.text('Tirage au sort'), findsOneWidget);
  });
}
