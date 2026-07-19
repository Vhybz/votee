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
  final String? electionId;

  Position({
    required this.id,
    required this.title,
    this.maxSelections = 1,
    this.order = 0,
    this.electionId,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      maxSelections: json['max_selections'] != null ? int.tryParse(json['max_selections'].toString()) ?? 1 : 1,
      order: json['order'] != null ? int.tryParse(json['order'].toString()) ?? 0 : 0,
      electionId: json['election_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'title': title,
      'max_selections': maxSelections,
      'order': order,
    };
    if (electionId != null) map['election_id'] = electionId!;
    return map;
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

  Candidate copyWith({
    String? fullName,
    String? positionId,
    String? slogan,
    String? imageUrl,
    int? voteCount,
  }) {
    return Candidate(
      id: id,
      fullName: fullName ?? this.fullName,
      positionId: positionId ?? this.positionId,
      slogan: slogan ?? this.slogan,
      imageUrl: imageUrl ?? this.imageUrl,
      voteCount: voteCount ?? this.voteCount,
    );
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
    final Map<String, dynamic> data = {
      'student_id': studentId,
      'candidate_id': candidateId,
      'position_id': positionId,
      'timestamp': timestamp.toIso8601String(),
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}

class ElectionStats {
  final int totalVoters;
  final int totalVotesCast;
  final double turnoutPercentage;
  final int activePolls;
  final Duration timeRemaining;
  final Map<String, int> votesBySchool;
  final Map<String, double> participationByLevel;
  final Map<int, int> hourlyParticipation; // Hour (0-23) -> Vote Count

  ElectionStats({
    required this.totalVoters,
    required this.totalVotesCast,
    required this.turnoutPercentage,
    required this.activePolls,
    required this.timeRemaining,
    required this.votesBySchool,
    required this.participationByLevel,
    required this.hourlyParticipation,
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

class ElectionSettings {
  final String id;
  final String electionTitle;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;

  ElectionSettings({
    required this.id,
    required this.electionTitle,
    this.startTime,
    this.endTime,
    this.isActive = false,
  });

  factory ElectionSettings.fromJson(Map<String, dynamic> json) {
    return ElectionSettings(
      id: json['id']?.toString() ?? '',
      electionTitle: json['election_title']?.toString() ?? 'RavenVote by TechRaven LTD',
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'].toString()) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'].toString()) : null,
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_title': electionTitle,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive,
    };
  }

  ElectionSettings copyWith({
    String? electionTitle,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
  }) {
    return ElectionSettings(
      id: id,
      electionTitle: electionTitle ?? this.electionTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}
