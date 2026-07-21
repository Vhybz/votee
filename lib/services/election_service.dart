import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/election_models.dart';
import '../core/supabase_config.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class ElectionService {
  final SupabaseClient _client = SupabaseConfig.client;

  // --- Student Operations ---

  Future<Student?> getStudentByIndex(String indexNumber) async {
    final response = await _client
        .from('students')
        .select('id, index_number, full_name, level, class_name, phone_number, academic_school, program, has_voted, voted_at') // Explicitly exclude OTP
        .eq('index_number', indexNumber)
        .maybeSingle();
    
    if (response == null) return null;
    return Student.fromJson(response);
  }

  Future<List<Student>> getAllStudents() async {
    final response = await _client
        .from('students')
        .select()
        .order('full_name');
    
    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<void> registerStudent(Map<String, dynamic> studentData) async {
    await _client.from('students').insert(studentData);
  }

  Future<void> markStudentAsVoted(String studentId) async {
    // The database trigger 'on_vote_cast' handles this automatically during voting.
    // This method allows for manual status updates by admins.
    await _client
        .from('students')
        .update({
          'has_voted': true, 
          'voted_at': DateTime.now().toIso8601String()
        })
        .eq('id', studentId);
  }

  Future<void> bulkImportStudents(List<Map<String, dynamic>> studentsData) async {
    await _client.from('students').insert(studentsData);
  }

  // --- Position & Candidate Operations ---

  Future<List<Position>> getPositions() async {
    final response = await _client
        .from('positions')
        .select()
        .order('order');
    
    return (response as List).map((json) => Position.fromJson(json)).toList();
  }

  Future<List<Candidate>> getAllCandidates() async {
    final response = await _client.from('candidates').select();
    return (response as List).map((json) => Candidate.fromJson(json)).toList();
  }

  Future<void> addCandidate(Candidate candidate) async {
    await _client.from('candidates').insert(candidate.toJson());
  }

  Future<void> updateCandidate(Candidate candidate) async {
    await _client
        .from('candidates')
        .update(candidate.toJson())
        .eq('id', candidate.id);
  }

  Future<void> deleteCandidate(String id) async {
    await _client.from('candidates').delete().eq('id', id);
  }

  Future<void> deleteAllCandidates() async {
    await _client.from('candidates').delete().not('id', 'is', null); 
  }

  Future<void> purgeElectionData() async {
    // 1. Delete all votes
    await _client.from('votes').delete().not('id', 'is', null);
    
    // 2. Reset student voting status
    await _client.from('students').update({
      'has_voted': false,
      'voted_at': null,
    }).not('id', 'is', null);
    
    // 3. Reset election settings
    await updateSettings(ElectionSettings(
      id: 'current_election',
      electionTitle: 'RavenVote by TechRaven LTD',
      isActive: false,
      startTime: null,
      endTime: null,
    ));
  }

  Future<void> addPosition(Position position) async {
    await _client.from('positions').insert(position.toJson());
  }

  Future<void> deletePosition(String id) async {
    await _client.from('positions').delete().eq('id', id);
  }

  Future<void> deleteStudent(String id) async {
    await _client.from('students').delete().eq('id', id);
  }

  /// Verifies OTP on the server via Edge Function to prevent client-side leakage.
  Future<bool> verifyOtpOnServer(String indexNumber, String otp) async {
    try {
      final response = await _client.functions.invoke(
        'verify-otp',
        body: {'index_number': indexNumber, 'otp': otp},
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('OTP Server Verification Failed: $e');
      return false;
    }
  }

  /// Triggers server-side OTP generation and SMS delivery via Edge Function.
  Future<void> generateAndSendOtp(String indexNumber) async {
    try {
      await _client.functions.invoke(
        'generate-otp',
        body: {'index_number': indexNumber},
      );
    } catch (e) {
      debugPrint('OTP Generation/Sending Failed: $e');
    }
  }

  Future<void> reportAnomaly({
    required String title,
    required String details,
    required AnomalySeverity severity,
    String? ipAddress,
  }) async {
    try {
      await _client.from('anomalies').insert({
        'title': title,
        'details': details,
        'severity': severity.name,
        'ip_address': ipAddress,
      });
    } catch (e) {
      debugPrint('Failed to report anomaly: $e');
    }
  }

  Future<String?> uploadCandidateImage(String candidateId, Uint8List bytes, {String ext = 'jpg'}) async {
    final storage = StorageService();
    return await storage.uploadCandidateImage(candidateId, bytes, ext);
  }

  // --- Voting Operations ---

  Future<void> castVotes(List<Vote> votes) async {
    final votesJson = votes.map((v) => v.toJson()).toList();
    await _client.from('votes').insert(votesJson);
  }

  Future<List<Map<String, dynamic>>> getVoteLogs() async {
    final response = await _client
        .from('votes')
        .select('''
          id,
          timestamp,
          students (full_name, index_number),
          candidates (full_name),
          positions (title)
        ''')
        .order('timestamp', ascending: false);
    
    return (response as List).cast<Map<String, dynamic>>();
  }

  // --- Stats & Real-time ---

  Future<ElectionSettings?> getActiveElection() async {
    final response = await _client
        .from('settings')
        .select()
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return ElectionSettings.fromJson(response);
  }

  Future<ElectionSettings> getSettings() async {
    // Try to get active, else get most recently updated
    final active = await getActiveElection();
    if (active != null) return active;

    final response = await _client
        .from('settings')
        .select()
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) {
      return ElectionSettings(id: 'current_election', electionTitle: 'RavenVote by TechRaven LTD');
    }
    return ElectionSettings.fromJson(response);
  }

  Future<List<ElectionSettings>> getAllElections() async {
    final response = await _client
        .from('settings')
        .select()
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => ElectionSettings.fromJson(json)).toList();
  }

  Future<void> deleteElection(String id) async {
    await _client.from('settings').delete().eq('id', id);
  }

  Future<void> updateSettings(ElectionSettings settings) async {
    // If we are activating this one, deactivate others
    if (settings.isActive) {
      await _client.from('settings').update({'is_active': false}).neq('id', settings.id);
    }

    await _client
        .from('settings')
        .upsert(settings.toJson());
  }

  Stream<ElectionSettings> watchSettings() {
    return _client
        .from('settings')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((data) {
          if (data.isEmpty) {
            return ElectionSettings(id: 'current_election', electionTitle: 'RavenVote by TechRaven LTD');
          }
          // Try to find the active one in the stream data
          final active = data.where((json) => json['is_active'] == true).firstOrNull;
          if (active != null) return ElectionSettings.fromJson(active);
          
          return ElectionSettings.fromJson(data.first);
        });
  }

  Stream<List<ElectionSettings>> watchAllElections() {
    return _client
        .from('settings')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => data.map((json) => ElectionSettings.fromJson(json)).toList());
  }

  Future<List<Anomaly>> getAnomalies() async {
    final response = await _client
        .from('anomalies')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) {
      return Anomaly(
        id: json['id'].toString(),
        title: json['title'].toString(),
        details: json['details'].toString(),
        severity: AnomalySeverity.values.byName(json['severity'] ?? 'low'),
        ipAddress: json['ip_address']?.toString(),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      );
    }).toList();
  }

  Stream<List<Candidate>> watchCandidates() {
    return _client
        .from('candidates')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Candidate.fromJson(json)).toList());
  }

  Stream<List<Position>> watchPositions() {
    return _client
        .from('positions')
        .stream(primaryKey: ['id'])
        .order('order', ascending: true)
        .map((data) => data.map((json) => Position.fromJson(json)).toList());
  }

  Future<ElectionStats> getElectionStats() async {
    final settings = await getSettings();
    final students = await getAllStudents();
    final totalVoters = students.length;
    final votedStudents = students.where((s) => s.hasVoted).toList();
    final totalVotesCast = votedStudents.length;

    // Distribution by School
    final Map<String, int> schoolVotes = {};
    for (var student in votedStudents) {
      final school = student.academicSchool.isEmpty ? 'Unknown' : student.academicSchool;
      schoolVotes[school] = (schoolVotes[school] ?? 0) + 1;
    }

    // Participation by Level
    final Map<String, int> levelTotal = {};
    final Map<String, int> levelVoted = {};
    for (var student in students) {
      levelTotal[student.level] = (levelTotal[student.level] ?? 0) + 1;
      if (student.hasVoted) {
        levelVoted[student.level] = (levelVoted[student.level] ?? 0) + 1;
      }
    }

    final Map<String, double> participationByLevel = {};
    levelTotal.forEach((level, total) {
      final voted = levelVoted[level] ?? 0;
      participationByLevel[level] = total > 0 ? (voted / total) : 0.0;
    });

    // Hourly Participation (Real Trend since session start)
    final Map<int, int> hourlyParticipation = {};
    try {
      var query = _client.from('votes').select('timestamp');
      
      if (settings.startTime != null) {
        query = query.gte('timestamp', settings.startTime!.toIso8601String());
      }
      
      final votesResponse = await query;
      
      for (var vote in (votesResponse as List)) {
        final timestamp = DateTime.parse(vote['timestamp'].toString()).toLocal();
        final hour = timestamp.hour;
        hourlyParticipation[hour] = (hourlyParticipation[hour] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Error fetching hourly stats: $e');
    }

    final positionRes = await _client.from('positions').select('id');
    final activePolls = positionRes.length;

    // Calculate time remaining
    Duration remaining = Duration.zero;
    if (settings.isActive && settings.endTime != null) {
      remaining = settings.endTime!.difference(DateTime.now());
      if (remaining.isNegative) remaining = Duration.zero;
    }

    return ElectionStats(
      totalVoters: totalVoters,
      totalVotesCast: totalVotesCast,
      turnoutPercentage: totalVoters > 0 ? (totalVotesCast / totalVoters) * 100 : 0,
      activePolls: activePolls,
      timeRemaining: remaining,
      votesBySchool: schoolVotes,
      participationByLevel: participationByLevel,
      hourlyParticipation: hourlyParticipation,
    );
  }
}
