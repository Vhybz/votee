import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'election_service.dart';
import '../models/election_models.dart';

final electionServiceProvider = Provider((ref) => ElectionService());

final electionTitleProvider = StateProvider<String>((ref) => 'UENR E-Voting System');

final positionsProvider = FutureProvider<List<Position>>((ref) async {
  return ref.watch(electionServiceProvider).getPositions();
});

final candidatesProvider = FutureProvider<List<Candidate>>((ref) async {
  return ref.watch(electionServiceProvider).getAllCandidates();
});

final votersListProvider = FutureProvider<List<Student>>((ref) async {
  return ref.watch(electionServiceProvider).getAllStudents();
});

final electionStatsProvider = StreamProvider<ElectionStats>((ref) async* {
  final service = ref.watch(electionServiceProvider);
  while (true) {
    yield await service.getElectionStats();
    await Future.delayed(const Duration(seconds: 30)); // Refresh stats every 30s
  }
});

final anomalyProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  // Simulate AI Analysis delay
  await Future.delayed(const Duration(seconds: 1));
  return [
    AnomalyAlert(
      id: '1',
      title: 'High-Frequency Voting',
      details: 'Terminal #4 (Great Hall) showing 12 votes/min',
      time: 'Just now',
      severity: AnomalySeverity.high,
    ),
    AnomalyAlert(
      id: '2',
      title: 'Duplicate Session Detected',
      details: 'Index #2045512 attempting concurrent login',
      time: '4 mins ago',
      severity: AnomalySeverity.medium,
    ),
    AnomalyAlert(
      id: '3',
      title: 'Anomalous Turnout Spike',
      details: 'Engineering Dept showing 85% turnout in 10 mins',
      time: '12 mins ago',
      severity: AnomalySeverity.high,
    ),
    AnomalyAlert(
      id: '4',
      title: 'Multiple IP Signatures',
      details: 'Index #2041234 verified from 3 different IPs',
      time: '25 mins ago',
      severity: AnomalySeverity.medium,
    ),
  ];
});
