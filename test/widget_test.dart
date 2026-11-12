import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naijamart/app.dart';

void main() {
  testWidgets('NaijaMart app starts', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NaijaMartApp()));
    expect(find.text('NaijaMart'), findsOneWidget);
    expect(find.text('Popular picks'), findsOneWidget);
  });
}
