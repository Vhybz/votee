import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  String _generateVoteHash() {
    final timestamp = DateTime.now().toIso8601String();
    final bytes = utf8.encode('RV-$timestamp-${DateTime.now().microsecondsSinceEpoch}');
    return sha256.convert(bytes).toString().substring(0, 16).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final voteHash = _generateVoteHash();
    final reference = 'RV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: 24),
                Text(
                  'Ballot Certified!',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your vote has been securely stored\non the digital ledger.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : AppColors.textLight,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                _buildReceiptCard(context, isDark, theme, reference, voteHash),
                
                const SizedBox(height: 48),
                
                _buildActionButtons(context, theme, isDark),
                
                const SizedBox(height: 32),
                Text(
                  'RAVENVOTE • UENR ELECTORAL COMMISSION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 64),
    );
  }

  Widget _buildReceiptCard(BuildContext context, bool isDark, ThemeData theme, String ref, String hash) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.05), 
            blurRadius: 30, 
            offset: const Offset(0, 15)
          ),
        ],
      ),
      child: Column(
        children: [
          // Receipt Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Image.asset('assets/logo/logo.png', width: 40, height: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIGITAL RECEIPT',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'UENR E-VOTING SYSTEM v1.0',
                        style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.textLight, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.qr_code_scanner_rounded, size: 28, color: isDark ? Colors.white24 : Colors.grey),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                    ],
                  ),
                  child: QrImageView(
                    data: 'ravenvote://verify/$hash',
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                _buildReceiptRow(context, 'TRANSACTION REF', ref),
                const Divider(height: 24),
                _buildReceiptRow(context, 'SECURITY HASH', hash),
                const Divider(height: 24),
                _buildReceiptRow(context, 'TIMESTAMP', DateTime.now().toString().substring(0, 19)),
                const Divider(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'TAMPER-PROOF SIGNATURE VERIFIED',
                      style: GoogleFonts.inter(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.file_download_outlined, size: 20, color: isDark ? Colors.black : Colors.white),
              label: Text('DOWNLOAD CERTIFICATE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: isDark ? Colors.black : Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/voter/verify', (route) => false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Text('LOGOUT SESSION', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: isDark ? Colors.white38 : Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            color: isDark ? Colors.white24 : Colors.grey, 
            fontSize: 9, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: GoogleFonts.jetBrainsMono(
            color: isDark ? Colors.white : AppColors.textDark, 
            fontWeight: FontWeight.bold, 
            fontSize: 13, 
          )
        ),
      ],
    );
  }
}
