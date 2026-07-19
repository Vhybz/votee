import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class IpService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Fetches the current public IP of the device.
  Future<String?> getCurrentIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['ip'];
      }
    } catch (e) {
      debugPrint('Error fetching IP: $e');
    }
    return null;
  }

  /// Checks if the given IP is blacklisted.
  Future<bool> isIpBlacklisted(String ip) async {
    final response = await _client
        .from('blacklisted_ips')
        .select()
        .eq('ip', ip)
        .maybeSingle();
    
    return response != null;
  }

  /// Blacklists an IP.
  Future<void> blacklistIp(String ip, String reason, String adminId) async {
    await _client.from('blacklisted_ips').insert({
      'ip': ip,
      'reason': reason,
      'blacklisted_by': adminId,
    });
  }

  /// Removes an IP from the blacklist.
  Future<void> unblacklistIp(String ip) async {
    await _client.from('blacklisted_ips').delete().eq('ip', ip);
  }

  /// Retrieves all blacklisted IPs.
  Future<List<Map<String, dynamic>>> getBlacklistedIps() async {
    return await _client.from('blacklisted_ips').select();
  }
}
