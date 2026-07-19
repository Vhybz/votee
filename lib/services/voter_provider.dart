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
      state = student;
      return student;
    } catch (e) {
      return null;
    }
  }

  bool verifyOtp(String otp) {
    if (state != null && state!.otp == otp) {
      return true;
    }
    return false;
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
