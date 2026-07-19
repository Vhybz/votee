import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
  bool _isSubmitting = false;
  final Map<String, List<String>> _selections = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);

    final isLoading = positionsAsync.isLoading || candidatesAsync.isLoading;

    return Skeletonizer(
      enabled: isLoading,
      child: positionsAsync.when(
        data: (positions) => candidatesAsync.when(
          data: (candidates) {
            final effectivePositions = positions.isEmpty && isLoading ? _fakePositions : positions;
            final effectiveCandidates = candidates.isEmpty && isLoading ? _fakeCandidates : candidates;

            if (effectivePositions.isEmpty) {
              return const Scaffold(body: Center(child: Text('No active positions found.')));
            }

            final currentPosition = effectivePositions[_currentPositionIndex];
            final positionCandidates = effectiveCandidates.where((c) => c.positionId == currentPosition.id).toList();

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  _isReviewMode ? 'REVIEW BALLOT' : 'BALLOT CASTING',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: isDark ? Colors.white : AppColors.textDark,
                leading: _isReviewMode 
                  ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => setState(() => _isReviewMode = false))
                  : null,
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    if (!_isReviewMode) _buildProgressHeader(theme, effectivePositions),
                    Expanded(
                      child: _isReviewMode 
                        ? _buildReviewSummary(theme, effectivePositions, effectiveCandidates)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: positionCandidates.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentPosition.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: isDark ? Colors.white : AppColors.textDark,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        positionCandidates.length == 1 
                                          ? 'Single aspirant found. Vote Yes or No.'
                                          : 'Select ${currentPosition.maxSelections} candidate${currentPosition.maxSelections > 1 ? 's' : ''}',
                                        style: GoogleFonts.inter(
                                          color: isDark ? Colors.white60 : AppColors.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final candidate = positionCandidates[index - 1];
                              if (positionCandidates.length == 1) {
                                return _buildSingleCandidateVoting(candidate, effectivePositions);
                              }
                              
                              return _buildCandidateCard(candidate, effectivePositions);
                            },
                          ),
                    ),
                    _buildNavigationFooter(theme, effectivePositions),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox(), // Handled by Skeletonizer
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        ),
        loading: () => const SizedBox(), // Handled by Skeletonizer
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }

  final List<Position> _fakePositions = [
    Position(id: 'p1', title: 'Sample Position Title', order: 0),
  ];

  final List<Candidate> _fakeCandidates = [
    Candidate(id: 'c1', fullName: 'Sample Candidate Name', positionId: 'p1', slogan: 'This is a sample slogan for the candidate.'),
    Candidate(id: 'c2', fullName: 'Sample Candidate Name 2', positionId: 'p1', slogan: 'This is another sample slogan.'),
  ];

  Widget _buildProgressHeader(ThemeData theme, List<Position> positions) {
    final isDark = theme.brightness == Brightness.dark;
    final double progress = (_currentPositionIndex + 1) / positions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POSITION ${_currentPositionIndex + 1} OF ${positions.length}',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : AppColors.textLight, 
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  color: theme.colorScheme.primary, 
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(ThemeData theme, List<Position> positions, List<Candidate> candidates) {
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Ballot Review',
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify your selections before casting your final vote.',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white60 : AppColors.textLight,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        ...positions.map((pos) {
          final selectedIds = _selections[pos.id] ?? [];
          
          final actualSelection = selectedIds.where((id) => !id.startsWith('NO_')).toList();
          final isRejected = selectedIds.any((id) => id.startsWith('NO_'));
          
          final selectedCandidates = candidates.where((c) => actualSelection.contains(c.id)).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pos.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _currentPositionIndex = positions.indexOf(pos);
                          _isReviewMode = false;
                        }),
                        child: const Text('CHANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (actualSelection.isEmpty && !isRejected)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text('Skipped / No Selection', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                else if (isRejected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text('REJECTED CANDIDATE (NO)', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ...selectedCandidates.map((c) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: (c.imageUrl != null && c.imageUrl!.isNotEmpty) ? NetworkImage(c.imageUrl!) : null,
                      child: (c.imageUrl == null || c.imageUrl!.isEmpty) ? const Icon(Icons.person, size: 20) : null,
                    ),
                    title: Text(
                      c.fullName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                  )),
                const SizedBox(height: 8),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSingleCandidateVoting(Candidate candidate, List<Position> positions) {
    final selections = _selections[candidate.positionId] ?? [];
    final isYes = selections.contains(candidate.id);
    final isNo = selections.contains('NO_${candidate.id}');

    return Column(
      children: [
        _buildCandidateCard(candidate, positions, forceHideSelection: true),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildDecisionButton(
                label: 'YES',
                icon: Icons.check_circle_outline_rounded,
                activeColor: Colors.green,
                isSelected: isYes,
                onTap: () {
                  setState(() {
                    _selections[candidate.positionId] = [candidate.id];
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDecisionButton(
                label: 'NO',
                icon: Icons.cancel_outlined,
                activeColor: Colors.redAccent,
                isSelected: isNo,
                onTap: () {
                  setState(() {
                    _selections[candidate.positionId] = ['NO_${candidate.id}'];
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionButton({
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.1) 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate, List<Position> positions, {bool forceHideSelection = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selections[candidate.positionId]?.contains(candidate.id) ?? false;
    final highlightColor = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? highlightColor.withValues(alpha: 0.15) : highlightColor.withValues(alpha: 0.05))
            : (isDark ? const Color(0xFF121212) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? highlightColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)), 
          width: isSelected ? 2 : 1
        ),
        boxShadow: isSelected ? [
          BoxShadow(color: highlightColor.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : AppColors.borderGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                    image: (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty) 
                      ? DecorationImage(image: NetworkImage(candidate.imageUrl!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: (candidate.imageUrl == null || candidate.imageUrl!.isEmpty)
                    ? Icon(Icons.person_rounded, color: isDark ? Colors.white24 : AppColors.textLight, size: 32)
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        candidate.slogan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white38 : AppColors.textLight,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!forceHideSelection)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? highlightColor : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected ? highlightColor.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: isSelected 
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
                        )
                      : null,
                  ),
              ],
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.05), blurRadius: 20, offset: const Offset(0, -5)),
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
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: isDark ? Colors.white10 : AppColors.borderGray),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('BACK', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0, color: isDark ? Colors.white : theme.colorScheme.primary)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (canGoNext || _isReviewMode) && !_isSubmitting
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
                backgroundColor: (_isReviewMode || isLast) ? Colors.green : (isDark ? Colors.white : theme.colorScheme.primary),
                foregroundColor: (_isReviewMode || isLast) ? Colors.white : (isDark ? Colors.black : Colors.white),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _isReviewMode ? 'CAST FINAL BALLOT' : (isLast ? 'REVIEW BALLOT' : 'NEXT POSITION'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
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
        // Only cast actual candidate votes (filter out 'NO_' prefixed rejection votes)
        if (!candId.startsWith('NO_')) {
          votesToCast.add(Vote(
            id: '',
            studentId: student.id,
            candidateId: candId,
            positionId: posId,
            timestamp: DateTime.now(),
          ));
        }
      }
    });

    setState(() => _isSubmitting = true);

    final success = await ref.read(voterProvider.notifier).finalizeVote(votesToCast);
    
    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/voter/receipt');
      }
    } else {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Submission failed. Please check your connection.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
