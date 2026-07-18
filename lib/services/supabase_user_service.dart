import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/uuid_utils.dart';

class SupabaseUserService {
  // UI-ONLY MOCK DATA PERSISTENCE
  static List<UserAccount> _mockUsers = [
    UserAccount(
      id: 'mock-admin-id',
      firstName: 'System',
      surname: 'Administrator',
      email: 'admin@ravenvote.com',
      role: UserRole.superAdmin,
      status: AccountStatus.approved,
    ),
    UserAccount(
      id: 'mock-official-id',
      firstName: 'Election',
      surname: 'Official',
      email: 'official@uenr.edu.gh',
      role: UserRole.electionOfficial,
      status: AccountStatus.approved,
    ),
  ];

  Future<List<UserAccount>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUsers.where((u) => !u.isDeleted).toList();
  }

  Future<void> addUser(UserAccount account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUsers.add(account);
  }

  Future<void> updateUser(UserAccount account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == account.id);
    if (index != -1) {
      _mockUsers[index] = account;
    }
  }

  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _mockUsers[index];
      // Minimal implementation for mock
      _mockUsers[index] = user.copyWith(
        firstName: fields['first_name'],
        surname: fields['surname'],
        status: fields['status'] != null ? AccountStatus.values.byName(fields['status']) : null,
        role: fields['role'] != null ? UserRole.values.byName(fields['role']) : null,
      );
    }
  }

  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == id);
    if (index != -1) {
      _mockUsers[index] = _mockUsers[index].copyWith(isDeleted: true);
    }
  }

  Future<void> hardDeleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUsers.removeWhere((u) => u.id == id);
  }

  Future<UserAccount?> getUserById(String id) async {
    return _mockUsers.where((u) => u.id == id).firstOrNull;
  }

  Future<UserAccount?> getCurrentUser() async {
    return getUserById('mock-admin-id');
  }

  Future<bool> checkPhoneExists(String phone) async {
    return false;
  }

  Future<String?> uploadProfilePicture(String userId, Uint8List bytes) async {
    return null;
  }

  Stream<UserAccount?> streamUser(String id) async* {
    yield await getUserById(id);
  }

  Stream<List<UserAccount>> watchUsers() async* {
    while(true) {
      yield await getUsers();
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // Mock method for registration
  Future<void> requestAccess({
    required String firstName,
    required String surname,
    required String email,
    required String phone,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final newUser = UserAccount(
      id: UuidUtils.generate(),
      firstName: firstName,
      surname: surname,
      email: email,
      role: UserRole.admin,
      status: AccountStatus.pending,
    );
    _mockUsers.add(newUser);
  }
}
