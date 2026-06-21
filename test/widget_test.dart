import 'package:flutter_test/flutter_test.dart';
import 'package:firstcc/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const FirstCCApp());
    // 验证 App 能正常渲染
    expect(find.byType(FirstCCApp), findsOneWidget);
  });
}
