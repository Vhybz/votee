import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'election_service.dart';
import '../models/election_models.dart';

final electionServiceProvider = Provider((ref) => ElectionService());

final electionTitleProvider = StateProvider<String>((ref) => 'UENR E-Voting System');

final electionSettingsProvider = StreamProvider<ElectionSettings>((ref) {
  return ref.watch(electionServiceProvider).watchSettings();
});

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
  return ref.watch(electionServiceProvider).getAnomalies();
});
