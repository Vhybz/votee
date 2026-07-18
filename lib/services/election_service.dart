import '../models/election_models.dart';

class ElectionService {
  // UI-ONLY MOCK DATA
  
  // Student Operations
  Future<Student?> getStudentByIndex(String indexNumber) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (indexNumber == '20001234') {
      return Student(
        id: 'mock-student-id',
        indexNumber: '20001234',
        fullName: 'Emmanuel Kwesi Arthur',
        level: '400',
        className: 'BSc. Computer Science',
        phoneNumber: '0241234567',
        academicSchool: 'Science',
        program: 'Computer Science',
        otp: '12345',
      );
    }
    return null;
  }

  Future<void> markStudentAsVoted(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Position & Candidate Operations
  Future<List<Position>> getPositions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Position(id: 'p1', title: 'SRC President', order: 1),
      Position(id: 'p2', title: 'General Secretary', order: 2),
      Position(id: 'p3', title: 'Financial Secretary', order: 3),
    ];
  }

  Future<List<Candidate>> getAllCandidates() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Candidate(id: 'c1', fullName: 'John Mahama', positionId: 'p1', slogan: 'Resetting Ghana', voteCount: 1240),
      Candidate(id: 'c2', fullName: 'Dr. Bawumia', positionId: 'p1', slogan: 'It is Possible', voteCount: 1100),
      Candidate(id: 'c3', fullName: 'Alice Mensah', positionId: 'p2', slogan: 'Service with Integrity', voteCount: 850),
      Candidate(id: 'c4', fullName: 'Bob Smith', positionId: 'p2', slogan: 'Your Voice Matters', voteCount: 600),
      Candidate(id: 'c5', fullName: 'Charlie Brown', positionId: 'p3', slogan: 'Transparency First', voteCount: 920),
    ];
  }

  // Voting Operations
  Future<void> castVotes(List<Vote> votes) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // Stats
  Future<ElectionStats> getElectionStats() async {
    return ElectionStats(
      totalVoters: 4820,
      totalVotesCast: 2481,
      turnoutPercentage: 51.4,
      activePolls: 3,
      timeRemaining: const Duration(hours: 4, minutes: 12),
    );
  }

  Future<List<Student>> getAllStudents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Student(id: '1', fullName: 'Emmanuel Kwesi Arthur', indexNumber: '20001234', level: '400', className: 'CS-A', phoneNumber: '0241234567', academicSchool: 'Science', program: 'Computer Science', otp: '12345', hasVoted: true),
      Student(id: '2', fullName: 'Alice Ama', indexNumber: '20001235', level: '400', className: 'CS-B', phoneNumber: '0241234568', academicSchool: 'Science', program: 'Computer Science', otp: '12345'),
      Student(id: '3', fullName: 'Bob Kojo', indexNumber: '20001236', level: '300', className: 'IT-A', phoneNumber: '0241234569', academicSchool: 'Science', program: 'Information Technology', otp: '12345'),
      Student(id: '4', fullName: 'Charlie Mensah', indexNumber: '20001237', level: '300', className: 'IT-A', phoneNumber: '0241234570', academicSchool: 'Science', program: 'Information Technology', otp: '12345', hasVoted: true),
      Student(id: '5', fullName: 'David Boateng', indexNumber: '20001238', level: '200', className: 'ME-A', phoneNumber: '0241234571', academicSchool: 'Engineering', program: 'Mechanical Engineering', otp: '12345'),
      Student(id: '6', fullName: 'Eva Osei', indexNumber: '20001239', level: '200', className: 'ME-A', phoneNumber: '0241234572', academicSchool: 'Engineering', program: 'Mechanical Engineering', otp: '12345'),
      Student(id: '7', fullName: 'Frank Appiah', indexNumber: '20001240', level: '100', className: 'EE-A', phoneNumber: '0241234573', academicSchool: 'Engineering', program: 'Electrical Engineering', otp: '12345', hasVoted: true),
      Student(id: '8', fullName: 'Grace Antwi', indexNumber: '20001241', level: '100', className: 'EE-B', phoneNumber: '0241234574', academicSchool: 'Engineering', program: 'Electrical Engineering', otp: '12345'),
    ];
  }

  // Admin: Candidate Registration
  Future<void> addCandidate(Candidate candidate) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Admin: Position Registration
  Future<void> addPosition(Position position) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Admin: Student Registration
  Future<void> registerStudent(Map<String, dynamic> studentData) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Admin: Bulk Import
  Future<void> bulkImportStudents(List<Map<String, dynamic>> studentsData) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
