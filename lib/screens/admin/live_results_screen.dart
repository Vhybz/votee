import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/election_provider.dart';
import '../../services/user_provider.dart';
import '../../models/election_models.dart';

class LiveResultsScreen extends ConsumerWidget {
  const LiveResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin');
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AdminAppBar(
          title: 'Live Results',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.5,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/results',
            onTap: (route) => MenuService.navigate(context, route, '/admin/results'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
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
                            data: (candidates) => _buildResultsList(theme, positions, candidates, false),
                            loading: () => _buildResultsList(theme, _fakePositions, _fakeCandidates, true),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                          loading: () => _buildResultsList(theme, _fakePositions, _fakeCandidates, true),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final List<Position> _fakePositions = [
    Position(id: 'p1', title: 'Sample Position Title', order: 0),
    Position(id: 'p2', title: 'Another Sample Position', order: 1),
  ];

  static final List<Candidate> _fakeCandidates = [
    Candidate(id: 'c1', fullName: 'Sample Candidate One', positionId: 'p1', slogan: 'Slogan for the first candidate', voteCount: 150),
    Candidate(id: 'c2', fullName: 'Sample Candidate Two', positionId: 'p1', slogan: 'Another sample slogan', voteCount: 120),
    Candidate(id: 'c3', fullName: 'Sample Candidate Three', positionId: 'p2', slogan: 'Working for you', voteCount: 80),
  ];

  Widget _buildResultsList(ThemeData theme, List<Position> positions, List<Candidate> candidates, bool isLoading) {
    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
          return _buildPositionResults(theme, pos, posCandidates);
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tally Dashboard',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            Text(
              'Real-time tally of all positions and candidates',
              style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
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
                    backgroundImage: (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty)
                        ? NetworkImage(candidate.imageUrl!)
                        : null,
                    child: (candidate.imageUrl == null || candidate.imageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 20, color: isDark ? Colors.white70 : AppColors.textLight)
                        : null,
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
            borderRadius: BorderRadius.zero,
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
