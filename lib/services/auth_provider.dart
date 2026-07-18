import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'user_provider.dart';
import 'election_provider.dart';
import 'voter_provider.dart';
import 'notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class GlobalLogout {
  static Future<void> perform(WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).signOut();
      ref.read(currentUserIdProvider.notifier).state = null;
      ref.read(sessionUserProfileProvider.notifier).state = null;
      _invalidateAll(ref);
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  static Future<void> performFromProvider(Ref ref) async {
    try {
      await ref.read(authServiceProvider).signOut();
      ref.read(currentUserIdProvider.notifier).state = null;
      ref.read(sessionUserProfileProvider.notifier).state = null;
      _invalidateAll(ref);
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  static void _invalidateAll(dynamic ref) {
    ref.invalidate(userProvider);
    ref.invalidate(voterProvider);
    ref.invalidate(positionsProvider);
    ref.invalidate(candidatesProvider);
    ref.invalidate(electionStatsProvider);
    ref.invalidate(notificationProvider);
  }
}
