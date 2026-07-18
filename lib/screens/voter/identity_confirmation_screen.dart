import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/election_models.dart';

class IdentityConfirmationScreen extends ConsumerWidget {
  final Student student;

  const IdentityConfirmationScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Identity'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm Your Identity',
                style: GoogleFonts.oswald(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please ensure the details below match your registration information.',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoRow(context, 'Full Name', student.fullName, Icons.person_outline),
                      const Divider(height: 32),
                      _buildInfoRow(context, 'Index Number', student.indexNumber, Icons.badge_outlined),
                      const Divider(height: 32),
                      _buildInfoRow(context, 'Program', student.program, Icons.school_outlined),
                      const Divider(height: 32),
                      _buildInfoRow(context, 'Level / Class', '${student.level} - ${student.className}', Icons.layers_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      '/voter/otp',
                      arguments: {'student': student},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'YES, THIS IS ME',
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'NOT MY DETAILS',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white54 : AppColors.uenrBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDark ? Colors.white : primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white60 : AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.oswald(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 16,
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
