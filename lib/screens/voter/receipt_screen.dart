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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                'Vote Cast & Encrypted!',
                style: GoogleFonts.oswald(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your audit-ready digital receipt is ready.',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              
              // Digital Receipt Card
              Card(
                elevation: isDark ? 0 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? Colors.white12 : Colors.transparent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OFFICIAL RECEIPT',
                                style: GoogleFonts.oswald(
                                  color: isDark ? Colors.white : theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'UENR Electoral Commission',
                                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey),
                              ),
                            ],
                          ),
                          const Icon(Icons.shield_outlined, size: 24, color: Colors.blue),
                        ],
                      ),
                      const Divider(height: 32),
                      
                      // QR Code for Audit
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: 'ravenvote://verify/$voteHash',
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildReceiptRow(context, 'Reference', reference),
                      _buildReceiptRow(context, 'Vote Hash', voteHash),
                      _buildReceiptRow(context, 'Status', 'STORED ON LEDGER'),
                      
                      const Divider(height: 32),
                      Text(
                        'This QR code contains your encrypted vote signature. You can use it to verify your vote in the public audit portal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white54 : AppColors.textLight, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('SAVE PDF'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/voter/verify', (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : AppColors.textLight, fontSize: 12)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
