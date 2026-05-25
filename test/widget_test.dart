import 'package:flutter_test/flutter_test.dart';

import 'package:interflex/main.dart';

void main() {
  testWidgets('shows login screen with create account option', (tester) async {
    await tester.pumpWidget(const InterFlexApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('New user? Create an account'), findsOneWidget);

    await tester.tap(find.text('New user? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Country national ID number'), findsOneWidget);
  });
}
