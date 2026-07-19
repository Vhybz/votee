import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/supabase_config.dart';
import 'storage_service.dart';

class SupabaseUserService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Retrieves all users from the public.users table.
  Future<List<UserAccount>> getUsers() async {
    final response = await _client
        .from('users')
        .select()
        .eq('is_deleted', false);
    
    return (response as List).map((json) => UserAccount.fromJson(json)).toList();
  }

  /// Updates a user's full profile.
  Future<void> updateUser(UserAccount account) async {
    await _client
        .from('users')
        .update(account.toJson())
        .eq('id', account.id);
  }

  /// Updates specific fields of a user.
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    await _client
        .from('users')
        .update(fields)
        .eq('id', userId);
  }

  /// Soft deletes a user.
  Future<void> deleteUser(String id) async {
    await _client
        .from('users')
        .update({'is_deleted': true})
        .eq('id', id);
  }

  /// Hard deletes a user from the database.
  Future<void> hardDeleteUser(String id) async {
    await _client
        .from('users')
        .delete()
        .eq('id', id);
  }

  /// Retrieves a user by their ID.
  Future<UserAccount?> getUserById(String id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return UserAccount.fromJson(response);
  }

  /// Retrieves the currently authenticated user's account profile.
  Future<UserAccount?> getCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return await getUserById(userId);
  }

  /// Uploads a profile picture and updates the user's photo_url.
  Future<String?> uploadProfilePicture(String userId, Uint8List bytes, {String ext = 'jpg'}) async {
    final storage = StorageService();
    final url = await storage.uploadProfilePicture(userId, bytes, ext);
    if (url != null) {
      await updateUserFields(userId, {'photo_url': url});
    }
    return url;
  }

  /// Streams a single user's data.
  Stream<UserAccount?> streamUser(String id) {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isEmpty ? null : UserAccount.fromJson(data.first));
  }

  /// Watch all users for real-time updates.
  Stream<List<UserAccount>> watchUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((data) => data.map((json) => UserAccount.fromJson(json)).toList());
  }

  /// Adds a new user account to the database.
  Future<void> addUser(UserAccount account) async {
    await _client.from('users').insert(account.toJson());
  }

  /// Method for registration (Request Access).
  Future<void> requestAccess({
    required String firstName,
    required String surname,
    required String email,
    required String phone,
  }) async {
    // In a real production system, this would likely trigger a signUp flow 
    // or insert into a manual review table. 
    // For now we keep it as a placeholder to satisfy the UI.
    await Future.delayed(const Duration(seconds: 1));
  }
}
