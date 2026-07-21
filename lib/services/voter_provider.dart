import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/election_models.dart';
import 'election_service.dart';
import 'election_provider.dart';
import 'sms_service.dart';

final voterProvider = StateNotifierProvider<VoterNotifier, Student?>((ref) {
  return VoterNotifier(ref.watch(electionServiceProvider));
});

class VoterNotifier extends StateNotifier<Student?> {
  final ElectionService _service;
  VoterNotifier(this._service) : super(null);

  Future<Student?> verifyIndex(String indexNumber) async {
    try {
      final student = await _service.getStudentByIndex(indexNumber);
      
      if (student != null) {
        // Trigger server-side OTP generation and SMS delivery
        await _service.generateAndSendOtp(indexNumber);
      }
      
      state = student;
      return student;
    } catch (e) {
      debugPrint('Error during index verification: $e');
      return null;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state == null) return false;
    
    // Server-side verification (Fixed vulnerability: OTP no longer exists on client)
    final isValid = await _service.verifyOtpOnServer(state!.indexNumber, otp);
    return isValid;
  }

  Future<void> resendOtp() async {
    if (state == null) return;
    await _service.generateAndSendOtp(state!.indexNumber);
  }

  Future<bool> finalizeVote(List<Vote> votes) async {
    if (state == null) return false;
    try {
      // 1. Submit the votes
      // The database trigger 'on_vote_cast' handles the status update atomically.
      await _service.castVotes(votes);
      
      // 2. Send SMS confirmation (Fire and forget)
      if (state != null && state!.phoneNumber.isNotEmpty) {
        SmsService.sendVoteConfirmation(state!.phoneNumber, state!.fullName);
      }
      
      logout();
      return true;
    } catch (e) {
      debugPrint('CRITICAL: Vote submission failed: $e');
      return false;
    }
  }

  void logout() {
    state = null;
  }
}
