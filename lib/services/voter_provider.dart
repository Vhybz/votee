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
      // 1. Check for test fallback
      if (indexNumber == '20001234') {
        final student = Student(
          id: 'test-voter-id',
          indexNumber: '20001234',
          fullName: 'Emmanuel Kwesi Arthur',
          level: '400',
          className: 'BSc. Computer Science',
          phoneNumber: '0241234567',
          academicSchool: 'Science',
          program: 'Computer Science',
          otp: '12345',
        );
        state = student;
        return student;
      }

      // 2. Query actual database
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
      // Bypass database for test user
      if (state!.id == 'test-voter-id') {
        await Future.delayed(const Duration(seconds: 1));
        logout();
        return true;
      }

      await _service.castVotes(votes);
      await _service.markStudentAsVoted(state!.id);
      logout();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    state = null;
  }
}
