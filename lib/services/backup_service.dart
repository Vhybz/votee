import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../core/supabase_config.dart';

class BackupService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Performs a complete system snapshot and returns it as a JSON string.
  Future<String> createSnapshot() async {
    try {
      final students = await _client.from('students').select();
      final candidates = await _client.from('candidates').select();
      final positions = await _client.from('positions').select();
      final votes = await _client.from('votes').select();
      final settings = await _client.from('settings').select();
      final anomalies = await _client.from('anomalies').select();

      final snapshot = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'data': {
          'students': students,
          'candidates': candidates,
          'positions': positions,
          'votes': votes,
          'settings': settings,
          'anomalies': anomalies,
        }
      };

      return jsonEncode(snapshot);
    } catch (e) {
      debugPrint('Backup Error: $e');
      rethrow;
    }
  }

  /// Saves a snapshot to Supabase Storage and triggers a local download.
  Future<void> performFullBackup({bool silent = false}) async {
    try {
      final jsonString = await createSnapshot();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'backup_$timestamp.json';

      // 1. Upload to Supabase Storage (Automated Cloud Backup)
      try {
        final bytes = utf8.encode(jsonString);
        await _client.storage.from('backups').uploadBinary(
          'snapshots/$fileName',
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(contentType: 'application/json'),
        );
        debugPrint('Cloud Backup Success: $fileName');
      } catch (e) {
        debugPrint('Cloud Backup failed (Storage bucket might not exist): $e');
        // We continue even if cloud upload fails to allow local download
      }

      // 2. Local Download (Manual download triggered by user)
      if (!silent) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(utf8.encode(jsonString)),
          filename: fileName,
        );
      }
    } catch (e) {
      if (!silent) rethrow;
    }
  }

  /// Automatically triggers a silent backup if the last one was more than 1 hour ago.
  /// (Simplified logic for the app)
  Future<void> autoBackupIfRequired() async {
    // In a real app, you'd store the last_backup_time in SharedPreferences
    // For this implementation, we trigger it once per session when the admin logs in.
    await performFullBackup(silent: true);
  }
}
