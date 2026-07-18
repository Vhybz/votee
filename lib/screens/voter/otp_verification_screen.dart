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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
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
                'Verify Your Account',
                style: GoogleFonts.oswald(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A 5-digit verification code has been sent to your registered phone number ending in ${_getPhoneNumberMask()}.',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) => _buildOtpField(index)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final otp = _controllers.map((c) => c.text).join();
                    if (ref.read(voterProvider.notifier).verifyOtp(otp)) {
                      Navigator.pushReplacementNamed(context, '/voter/vote');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid OTP. Please try again.')),
                      );
                    }
                  },
                  child: Text(
                    'VERIFY & CONTINUE',
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't receive the code? ",
                      style: GoogleFonts.inter(color: isDark ? Colors.white54 : AppColors.textLight),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 60,
      height: 70,
      child: Card(
        margin: EdgeInsets.zero,
        child: Center(
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: GoogleFonts.oswald(
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
              if (value.isNotEmpty && index < 4) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        ),
      ),
    );
  }
}
