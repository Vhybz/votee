import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_config.dart';

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Uploads a profile picture for a user to the 'avatars' bucket.
  Future<String?> uploadProfilePicture(String userId, Uint8List fileBytes, String extension) async {
    try {
      final fileName = '$userId.${extension.replaceAll('.', '')}';
      final path = 'profiles/$fileName';

      // Bypass compile-time type check for Uint8List vs File
      await (_client.storage.from('avatars') as dynamic).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/*'),
      );

      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Uploads a candidate image to the 'candidates' bucket.
  Future<String?> uploadCandidateImage(String candidateId, Uint8List fileBytes, String extension) async {
    try {
      final fileName = '$candidateId.${extension.replaceAll('.', '')}';
      final path = 'photos/$fileName';

      // Bypass compile-time type check for Uint8List vs File
      await (_client.storage.from('candidates') as dynamic).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/*'),
      );

      return _client.storage.from('candidates').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading candidate image: $e');
      return null;
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
