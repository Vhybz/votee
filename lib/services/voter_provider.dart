import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/election_models.dart';
import 'election_service.dart';
import 'election_provider.dart';

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
      await _service.castVotes(votes);
      
      // 2. Mark student as voted (Resilient check)
      try {
        await _service.markStudentAsVoted(state!.id);
      } catch (e) {
        // If this fails, it might be due to RLS or the trigger already handled it.
        // We log it but don't fail the user experience if castVotes succeeded.
        debugPrint('Post-vote status update handled by system or failed: $e');
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
