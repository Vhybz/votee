import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmsService {
  static String get _apiKey => const String.fromEnvironment('ARKESEL_API_KEY', defaultValue: '')
      .isEmpty ? (dotenv.env['ARKESEL_API_KEY'] ?? '') : const String.fromEnvironment('ARKESEL_API_KEY');
  
  static String get _senderId => const String.fromEnvironment('ARKESEL_SENDER_ID', defaultValue: '')
      .isEmpty ? (dotenv.env['ARKESEL_SENDER_ID'] ?? 'RavenVote') : const String.fromEnvironment('ARKESEL_SENDER_ID');

  static Future<bool> _sendSms(String to, String message) async {
    if (_apiKey.isEmpty) {
      debugPrint('SIMULATED SMS to $to: $message');
      return true;
    }

    String formattedPhone = to.trim().replaceAll(RegExp(r'\s+'), '');
    if (formattedPhone.startsWith('0') && formattedPhone.length == 10) {
      formattedPhone = '233${formattedPhone.substring(1)}';
    }

    try {
      final v2Url = Uri.parse('https://sms.arkesel.com/api/v2/sms/send');
      final response = await http.post(
        v2Url,
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: '{"sender":"$_senderId","recipients":["$formattedPhone"],"message":"${message.replaceAll('"', '\\"')}"}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('SMS Exception: $e');
      return false;
    }
  }

  static Future<void> sendVoteConfirmation(String phone, String name) async {
    final message = 'Hello $name, your vote in the RavenVote Election has been successfully cast. Thank you for participating!';
    await _sendSms(phone, message);
  }

  static Future<void> sendOtp(String phone, String otp) async {
    final message = 'Your RavenVote verification code is: $otp. Please enter it to verify your identity.';
    await _sendSms(phone, message);
  }
}
