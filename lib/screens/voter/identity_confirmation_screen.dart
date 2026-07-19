import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/election_models.dart';
import '../../services/election_provider.dart';

class IdentityConfirmationScreen extends ConsumerWidget {
  final Student student;

  const IdentityConfirmationScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  HSLColor.fromColor(theme.colorScheme.primary).withLightness(isDark ? 0.05 : 0.15).toColor(),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderIcon(theme),
                      const SizedBox(height: 24),
                      _buildHeader(isDark, theme),
                      const SizedBox(height: 32),
                      _buildDetailsList(context, isDark, theme),
                      const SizedBox(height: 40),
                      _buildActionButtons(context, isDark, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.how_to_reg_rounded, size: 50, color: Colors.green),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Column(
      children: [
        _buildElectionBadge(theme, isDark),
        const SizedBox(height: 16),
        Text(
          'Confirm Identity',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify that these are your registered details.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white70 : AppColors.textLight,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildElectionBadge(ThemeData theme, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(electionSettingsProvider).value;
        if (settings == null) return const SizedBox();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            settings.electionTitle.toUpperCase(),
            style: GoogleFonts.inter(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsList(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Full Name', student.fullName, Icons.person_outline),
          const Divider(height: 32),
          _buildInfoRow(context, 'Index Number', student.indexNumber, Icons.badge_outlined),
          const Divider(height: 32),
          _buildInfoRow(context, 'Program', student.program, Icons.school_outlined),
          const Divider(height: 32),
          _buildInfoRow(context, 'Academic Level', 'Level ${student.level}', Icons.layers_outlined),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/voter/otp',
                arguments: {'student': student},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.green,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'YES, PROCEED',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'GO BACK',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white54 : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? Colors.white : primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : AppColors.textLight,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
