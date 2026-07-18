import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static SupabaseClient? _adminClient;
  
  // Return a dummy client if not initialized to prevent crashes in UI-only mode
  static SupabaseClient get adminClient => _adminClient ?? SupabaseClient('https://mock.supabase.co', 'mock-key');

  static Future<void> initialize() async {
    String url = '';
    String anonKey = '';
    try {
      url = dotenv.env['SUPABASE_URL'] ?? '';
      anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) {
        debugPrint('SupabaseConfig: Missing credentials. Skipping real initialization for UI-only mode.');
        return;
      }

      await Supabase.initialize(
        url: url.trim(),
        publishableKey: anonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      
      final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
      if (serviceKey.isNotEmpty) {
        _adminClient = SupabaseClient(url.trim(), serviceKey);
      }
      
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Supabase Init Warning: $e');
      // In UI-only mode, we swallow this error
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      // Return a dummy client if Supabase isn't initialized
      return SupabaseClient('https://mock.supabase.co', 'mock-key');
    }
  }
}
