import 'package:flutter_test/flutter_test.dart';
import 'package:vote_z/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RavenVoteApp()));

    // Verify that splash text exists
    expect(find.text('RavenVote'), findsOneWidget);
  });
}
