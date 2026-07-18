import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';

class LiveResultsScreen extends ConsumerWidget {
  const LiveResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItems = ref.watch(menuItemsProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          AppSidebar(
            items: menuItems,
            currentRoute: '/admin/results',
            onTap: (route) => MenuService.navigate(context, route, '/admin/results'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 32),
                  Expanded(
                    child: positionsAsync.when(
                      data: (positions) => candidatesAsync.when(
                        data: (candidates) => ListView.builder(
                          itemCount: positions.length,
                          itemBuilder: (context, index) {
                            final pos = positions[index];
                            final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
                            return _buildPositionResults(theme, pos, posCandidates);
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Election Results',
              style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            Text(
              'Real-time tally of all positions and candidates',
              style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('LIVE UPDATE ACTIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionResults(ThemeData theme, Position position, List<Candidate> candidates) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    // Sort candidates by vote count descending
    final sortedCandidates = List<Candidate>.from(candidates)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    
    final totalVotes = candidates.fold(0, (sum, c) => sum + c.voteCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            position.title.toUpperCase(),
            style: GoogleFonts.oswald(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: sortedCandidates.isEmpty 
                ? [const Text('No candidates registered for this position.')]
                : sortedCandidates.map((c) => _buildCandidateResultRow(theme, c, totalVotes)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateResultRow(ThemeData theme, Candidate candidate, int totalVotes) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final percentage = totalVotes > 0 ? (candidate.voteCount / totalVotes) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (isDark ? Colors.white : AppColors.borderGray).withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 20, color: isDark ? Colors.white70 : AppColors.textLight),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidate.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(candidate.slogan, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : AppColors.textLight, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${candidate.voteCount} Votes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white : primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark ? Colors.white12 : AppColors.borderGray.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
