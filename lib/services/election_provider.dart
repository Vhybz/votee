import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'election_service.dart';
import '../models/election_models.dart';

final electionServiceProvider = Provider((ref) => ElectionService());

final electionTitleProvider = StateProvider<String>((ref) => 'RavenVote by TechRaven LTD');

final electionSettingsProvider = StreamProvider<ElectionSettings>((ref) {
  return ref.watch(electionServiceProvider).watchSettings();
});

final allElectionsProvider = StreamProvider<List<ElectionSettings>>((ref) {
  return ref.watch(electionServiceProvider).watchAllElections();
});

final positionsProvider = StreamProvider<List<Position>>((ref) {
  return ref.watch(electionServiceProvider).watchPositions();
});

final candidatesProvider = StreamProvider<List<Candidate>>((ref) {
  return ref.watch(electionServiceProvider).watchCandidates();
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

final anomalyProvider = FutureProvider<List<Anomaly>>((ref) async {
  return ref.watch(electionServiceProvider).getAnomalies();
});
