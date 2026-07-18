import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'supabase_user_service.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  final SupabaseUserService service;
  final Ref ref;
  StreamSubscription? _subscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserNotifier(this.service, this.ref) : super([]) {
    _init();
  }

  void _init() {
    _startSubscription();
  }

  void _startSubscription() {
    _subscription?.cancel();
    _subscription = service.watchUsers().listen((users) {
      state = users;
      final currentId = ref.read(currentUserIdProvider);
      if (currentId != null) {
        final me = users.where((u) => u.id == currentId).firstOrNull;
        if (me != null) {
          ref.read(sessionUserProfileProvider.notifier).state = me;
        }
      }
    }, onError: (e) {
      debugPrint('User Stream Error: $e');
    });
  }

  Future<void> loadUsers({bool silent = false}) async {
    if (_isLoading) return;
    try {
      if (!silent) _isLoading = true;
      final allUsers = await service.getUsers();
      state = allUsers;
    } catch (e) {
      debugPrint('Load Users Error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addAccount(UserAccount account) async {
    await service.addUser(account);
    state = [...state, account];
  }

  Future<void> updateProfile(String userId, {String? firstName, String? surname}) async {
    final user = state.where((u) => u.id == userId).firstOrNull;
    if (user != null) {
      final updatedUser = user.copyWith(firstName: firstName, surname: surname);
      await service.updateUser(updatedUser);
    }
  }

  Future<void> deleteUser(String userId) async {
    await service.deleteUser(userId);
    state = state.where((u) => u.id != userId).toList();
  }
}

final userServiceProvider = Provider<SupabaseUserService>((ref) {
  return SupabaseUserService();
});

final currentUserIdProvider = StateProvider<String?>((ref) => null);
final sessionUserProfileProvider = StateProvider<UserAccount?>((ref) => null);

final currentUserProvider = Provider<UserAccount?>((ref) {
  final currentId = ref.watch(currentUserIdProvider);
  if (currentId == null) return null;
  final sessionUser = ref.watch(sessionUserProfileProvider);
  if (sessionUser != null) return sessionUser;
  try {
    return ref.watch(userProvider).firstWhere((u) => u.id == currentId);
  } catch (_) {
    return null;
  }
});

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier(ref.watch(userServiceProvider), ref);
});
