import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class AppErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool isExpandable;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.isExpandable = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNoConnection = error is SocketException || 
                                error.toString().contains('SocketException') ||
                                error.toString().contains('ClientException') ||
                                error.toString().contains('Failed host lookup');

    final String title = isNoConnection ? 'Connection Lost' : 'System Error';
    final String message = isNoConnection 
        ? 'We are having trouble connecting to the secure servers. Please check your internet connection and try again.'
        : 'An unexpected technical error occurred while fetching data.';
    
    final IconData icon = isNoConnection ? Icons.wifi_off_rounded : Icons.error_outline_rounded;
    final Color color = isNoConnection ? Colors.orange : Colors.redAccent;

    Widget content = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('RETRY CONNECTION'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            if (!isNoConnection)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Technical Details'),
                        content: SingleChildScrollView(
                          child: Text(
                            error.toString(),
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('SHOW TECHNICAL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );

    if (isExpandable) {
      return Expanded(child: content);
    }
    return content;
  }
}
