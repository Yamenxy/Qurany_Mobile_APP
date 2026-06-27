import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qurany_app/main.dart';

void main() {
  testWidgets('QuranyApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuranyApp(prefs: prefs));
    await tester.pumpAndSettle();
  });
}
