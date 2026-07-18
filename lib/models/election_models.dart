class Student {
  final String id;
  final String indexNumber;
  final String fullName;
  final String level;
  final String className;
  final String phoneNumber;
  final String academicSchool;
  final String program;
  final String otp;
  final bool hasVoted;
  final DateTime? votedAt;

  Student({
    required this.id,
    required this.indexNumber,
    required this.fullName,
    required this.level,
    required this.className,
    required this.phoneNumber,
    required this.academicSchool,
    required this.program,
    required this.otp,
    this.hasVoted = false,
    this.votedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      indexNumber: json['index_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      academicSchool: json['academic_school']?.toString() ?? '',
      program: json['program']?.toString() ?? '',
      otp: json['otp']?.toString() ?? '',
      hasVoted: json['has_voted'] == true,
      votedAt: json['voted_at'] != null ? DateTime.tryParse(json['voted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index_number': indexNumber,
      'full_name': fullName,
      'level': level,
      'class_name': className,
      'phone_number': phoneNumber,
      'academic_school': academicSchool,
      'program': program,
      'otp': otp,
      'has_voted': hasVoted,
      'voted_at': votedAt?.toIso8601String(),
    };
  }
}

class Position {
  final String id;
  final String title;
  final int maxSelections;
  final int order;

  Position({
    required this.id,
    required this.title,
    this.maxSelections = 1,
    this.order = 0,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      maxSelections: json['max_selections'] != null ? int.tryParse(json['max_selections'].toString()) ?? 1 : 1,
      order: json['order'] != null ? int.tryParse(json['order'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'max_selections': maxSelections,
      'order': order,
    };
  }
}

class Candidate {
  final String id;
  final String fullName;
  final String positionId;
  final String slogan;
  final String? imageUrl;
  final int voteCount;

  Candidate({
    required this.id,
    required this.fullName,
    required this.positionId,
    required this.slogan,
    this.imageUrl,
    this.voteCount = 0,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      positionId: json['position_id']?.toString() ?? '',
      slogan: json['slogan']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      voteCount: json['vote_count'] != null ? int.tryParse(json['vote_count'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'position_id': positionId,
      'slogan': slogan,
      'image_url': imageUrl,
      'vote_count': voteCount,
    };
  }
}

class Vote {
  final String id;
  final String studentId;
  final String candidateId;
  final String positionId;
  final DateTime timestamp;

  Vote({
    required this.id,
    required this.studentId,
    required this.candidateId,
    required this.positionId,
    required this.timestamp,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      candidateId: json['candidate_id']?.toString() ?? '',
      positionId: json['position_id']?.toString() ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'candidate_id': candidateId,
      'position_id': positionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ElectionStats {
  final int totalVoters;
  final int totalVotesCast;
  final double turnoutPercentage;
  final int activePolls;
  final Duration timeRemaining;

  ElectionStats({
    required this.totalVoters,
    required this.totalVotesCast,
    required this.turnoutPercentage,
    required this.activePolls,
    required this.timeRemaining,
  });
}

class AnomalyAlert {
  final String id;
  final String title;
  final String details;
  final String time;
  final AnomalySeverity severity;

  AnomalyAlert({
    required this.id,
    required this.title,
    required this.details,
    required this.time,
    required this.severity,
  });
}

enum AnomalySeverity { high, medium, low }
