import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/election_models.dart';
import '../../services/voter_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final Student student;

  const OtpVerificationScreen({super.key, required this.student});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getPhoneNumberMask() {
    final phone = widget.student.phoneNumber;
    if (phone.length < 4) return '••••';
    return '•••• ••• ${phone.substring(phone.length - 4)}';
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 5) return;

    setState(() => _isVerifying = true);
    
    await Future.delayed(const Duration(milliseconds: 800));

    if (ref.read(voterProvider.notifier).verifyOtp(otp)) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/voter/vote');
      }
    } else {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid code. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Themed Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  HSLColor.fromColor(theme.colorScheme.primary).withLightness(isDark ? 0.05 : 0.1).toColor(),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 40, 
                    vertical: isMobile ? 32 : 40
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
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
                      _buildHeaderIcon(),
                      const SizedBox(height: 24),
                      _buildHeader(isDark),
                      const SizedBox(height: 48),
                      _buildOtpInputRow(isDark, theme),
                      const SizedBox(height: 48),
                      _buildVerifyButton(theme, isDark),
                      const SizedBox(height: 24),
                      _buildResendOption(isDark, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.shield_rounded, size: 50, color: Colors.blue),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 5-digit code sent to\n${_getPhoneNumberMask()}',
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

  Widget _buildOtpInputRow(bool isDark, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) => _buildOtpField(index, isDark, theme)),
    );
  }

  Widget _buildOtpField(int index, bool isDark, ThemeData theme) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 65,
          constraints: const BoxConstraints(maxWidth: 55),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNodes[index].hasFocus 
                  ? theme.colorScheme.primary 
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              width: 2,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 4) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                    _handleVerify();
                  }
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isVerifying 
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
            : Text(
                'VERIFY & CONTINUE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildResendOption(bool isDark, ThemeData theme) {
    return TextButton(
      onPressed: () {},
      child: RichText(
        text: TextSpan(
          text: "Didn't receive the code? ",
          style: GoogleFonts.inter(color: isDark ? Colors.white54 : AppColors.textLight, fontSize: 13),
          children: [
            TextSpan(
              text: "Resend",
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
