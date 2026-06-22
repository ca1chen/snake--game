import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firstcc/app.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FirstCCApp()),
    );
    await tester.pump(); // 让 SplashPage 的 initState 执行
    // 验证 App 能正常渲染
    expect(find.byType(FirstCCApp), findsOneWidget);
  });
}
