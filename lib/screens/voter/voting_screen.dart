import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/election_models.dart';
import '../../services/voter_provider.dart';
import '../../services/election_provider.dart';

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  int _currentPositionIndex = 0;
  bool _isReviewMode = false;
  final Map<String, List<String>> _selections = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);

    return positionsAsync.when(
      data: (positions) => candidatesAsync.when(
        data: (candidates) {
          if (positions.isEmpty) {
            return const Scaffold(body: Center(child: Text('No active positions found.')));
          }

          final currentPosition = positions[_currentPositionIndex];
          final positionCandidates = candidates.where((c) => c.positionId == currentPosition.id).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text(_isReviewMode ? 'Review Your Vote' : 'RavenVote Election'),
              centerTitle: true,
              leading: _isReviewMode 
                ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isReviewMode = false))
                : null,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (!_isReviewMode) _buildProgressHeader(theme, positions),
                  Expanded(
                    child: _isReviewMode 
                      ? _buildReviewSummary(theme, positions, candidates)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentPosition.title,
                                style: GoogleFonts.oswald(
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Select ${currentPosition.maxSelections} candidate${currentPosition.maxSelections > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white70 : AppColors.textLight,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ...positionCandidates.map((candidate) => _buildCandidateCard(candidate, positions)),
                            ],
                          ),
                        ),
                  ),
                  _buildNavigationFooter(theme, positions),
                ],
              ),
            ),
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error loading candidates: $e'))),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading positions: $e'))),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, List<Position> positions) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: isDark ? theme.cardTheme.color : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentPositionIndex + 1} of ${positions.length}',
                style: GoogleFonts.inter(color: isDark ? Colors.white60 : AppColors.textLight, fontWeight: FontWeight.w500),
              ),
              Text(
                '${((_currentPositionIndex + 1) / positions.length * 100).toInt()}% Complete',
                style: GoogleFonts.oswald(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentPositionIndex + 1) / positions.length,
              backgroundColor: isDark ? Colors.white10 : AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(ThemeData theme, List<Position> positions, List<Candidate> candidates) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vote Summary',
            style: GoogleFonts.oswald(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your selections before final submission.',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : AppColors.textLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ...positions.map((pos) {
            final selectedIds = _selections[pos.id] ?? [];
            final selectedCandidates = candidates.where((c) => selectedIds.contains(c.id)).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pos.title,
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _currentPositionIndex = positions.indexOf(pos);
                            _isReviewMode = false;
                          }),
                          child: const Text('CHANGE'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (selectedCandidates.isEmpty)
                      const Text('No candidate selected', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic))
                    else
                      ...selectedCandidates.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: (c.imageUrl != null && c.imageUrl!.isNotEmpty) ? NetworkImage(c.imageUrl!) : null,
                              child: (c.imageUrl == null || c.imageUrl!.isEmpty) ? const Icon(Icons.person, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              c.fullName,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate, List<Position> positions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selections[candidate.positionId]?.contains(candidate.id) ?? false;
    final highlightColor = isDark ? Colors.white : theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          final currentSelections = _selections[candidate.positionId] ?? [];
          if (isSelected) {
            currentSelections.remove(candidate.id);
          } else {
            if (currentSelections.length < positions[_currentPositionIndex].maxSelections) {
              currentSelections.add(candidate.id);
            } else if (positions[_currentPositionIndex].maxSelections == 1) {
              currentSelections.clear();
              currentSelections.add(candidate.id);
            }
          }
          _selections[candidate.positionId] = currentSelections;
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(
            color: isSelected ? highlightColor : (isDark ? Colors.white12 : AppColors.borderGray), 
            width: isSelected ? 2 : 1
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.borderGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                  image: (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty) 
                    ? DecorationImage(image: NetworkImage(candidate.imageUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: (candidate.imageUrl == null || candidate.imageUrl!.isEmpty)
                  ? Icon(Icons.person, color: isDark ? Colors.white30 : AppColors.textLight, size: 40)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.fullName,
                      style: GoogleFonts.oswald(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '"${candidate.slogan}"',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white60 : AppColors.textLight,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: highlightColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationFooter(ThemeData theme, List<Position> positions) {
    final isDark = theme.brightness == Brightness.dark;
    final bool isLast = _currentPositionIndex == positions.length - 1;
    final bool canGoNext = (_selections[positions[_currentPositionIndex].id]?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentPositionIndex > 0 || _isReviewMode) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  if (_isReviewMode) {
                    _isReviewMode = false;
                  } else {
                    _currentPositionIndex--;
                  }
                }),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white24 : AppColors.borderGray),
                ),
                child: Text('BACK', style: GoogleFonts.oswald()),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (canGoNext || _isReviewMode)
                ? () async {
                    if (_isReviewMode) {
                      _submitFinalVote();
                    } else if (isLast) {
                      setState(() => _isReviewMode = true);
                    } else {
                      setState(() => _currentPositionIndex++);
                    }
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isReviewMode || isLast) ? Colors.green : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isReviewMode ? 'SUBMIT VOTE' : (isLast ? 'REVIEW VOTE' : 'NEXT POSITION'),
                style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFinalVote() async {
    final student = ref.read(voterProvider);
    if (student == null) return;

    final List<Vote> votesToCast = [];
    _selections.forEach((posId, candIds) {
      for (var candId in candIds) {
        votesToCast.add(Vote(
          id: '',
          studentId: student.id,
          candidateId: candId,
          positionId: posId,
          timestamp: DateTime.now(),
        ));
      }
    });

    final success = await ref.read(voterProvider.notifier).finalizeVote(votesToCast);
    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/voter/receipt');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please try again.')),
        );
      }
    }
  }
}
