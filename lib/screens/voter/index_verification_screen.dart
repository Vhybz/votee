import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/voter_provider.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';
import 'dart:math' as math;

class IndexVerificationScreen extends ConsumerStatefulWidget {
  const IndexVerificationScreen({super.key});

  @override
  ConsumerState<IndexVerificationScreen> createState() => _IndexVerificationScreenState();
}

class _IndexVerificationScreenState extends ConsumerState<IndexVerificationScreen> with TickerProviderStateMixin {
  final _indexController = TextEditingController();
  late AnimationController _avatarController;
  final List<Offset> _avatarPositions = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _avatarPositions.add(Offset(
        _random.nextDouble(),
        _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _indexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final candidatesAsync = ref.watch(candidatesProvider);
    final candidates = candidatesAsync.value ?? [];
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Floating Avatars
          ...List.generate(
            candidates.isNotEmpty ? math.min(candidates.length, 15) : 8, 
            (index) => _buildFloatingAvatar(index, size, candidates.isNotEmpty ? candidates[index % candidates.length] : null)
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildLiveStats(),
                  const SizedBox(height: 32),
                  _buildVerificationForm(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final electionTitle = ref.watch(electionTitleProvider);
    
    return Row(
      children: [
        GestureDetector(
          onLongPress: () => Navigator.pushNamed(context, '/admin/login'),
          child: const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/logo/logo.png'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded( // Added Expanded to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RavenVote',
                style: GoogleFonts.oswald(
                  color: theme.colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                electionTitle,
                style: GoogleFonts.inter(
                  color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStats() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Turnout', '64.2%', Icons.pie_chart_outline),
                _buildStatItem('Total Votes', '2,481', Icons.how_to_vote),
                _buildStatItem('Time Left', '04:12:05', Icons.timer_outlined),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.642,
                backgroundColor: AppColors.borderGray,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.oswald(
            color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.brightness == Brightness.dark ? Colors.white60 : AppColors.textLight,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationForm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast Your Vote',
          style: GoogleFonts.oswald(
            color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your unique Index Number to begin the verification process.',
          style: GoogleFonts.inter(
            color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.textLight,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _indexController,
                  decoration: const InputDecoration(
                    labelText: 'Index Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final index = _indexController.text.trim();
                      if (index.isEmpty) return;

                      final student = await ref.read(voterProvider.notifier).verifyIndex(index);
                      if (student != null) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context, 
                            '/voter/confirm',
                            arguments: {'student': student},
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Index number not found.')),
                          );
                        }
                      }
                    },
                    child: Text(
                      'VERIFY IDENTITY',
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Icon(Icons.security, color: theme.brightness == Brightness.dark ? Colors.white38 : AppColors.textLight, size: 24),
          const SizedBox(height: 8),
          Text(
            'Secure Multi-Factor Authentication Active',
            style: TextStyle(
              color: theme.brightness == Brightness.dark ? Colors.white38 : AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAvatar(int index, Size size, Candidate? candidate) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _avatarController,
      builder: (context, child) {
        final double t = _avatarController.value;
        // More fluid and varied movement
        final double x = (_avatarPositions[index].dx + 0.12 * math.sin(2 * math.pi * t + index)) * size.width;
        final double y = (_avatarPositions[index].dy + 0.12 * math.cos(2 * math.pi * t + index)) * size.height;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: 0.15,
            child: CircleAvatar(
              radius: 25 + (index % 4) * 10,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: (candidate?.imageUrl != null && candidate!.imageUrl!.isNotEmpty)
                  ? NetworkImage(candidate.imageUrl!)
                  : null,
              child: (candidate?.imageUrl == null || candidate!.imageUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
