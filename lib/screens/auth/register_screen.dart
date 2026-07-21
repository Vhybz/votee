import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherRankController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedRank;

  final List<String> _ranks = [
    'HOD', 
    'Dean Student', 
    'Technician', 
    'TA', 
    'Lecturer', 
    'Other'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otherRankController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    String rank = _selectedRank ?? '';
    if (rank == 'Other') {
      rank = _otherRankController.text.trim();
    }

    if (firstName.isEmpty || surname.isEmpty || email.isEmpty || password.isEmpty || rank.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Register with Supabase Auth
      final response = await ref.read(authServiceProvider).signUp(
        email, 
        password,
        firstName: firstName,
        surname: surname,
        rank: rank,
      );
      
      if (response.user != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Created', 
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: const Text('Your registration was successful. If this is the first admin account, you can log in immediately. Otherwise, please wait for superAdmin approval.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text('PROCEED TO LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
                  HSLColor.fromColor(theme.colorScheme.primary).withLightness(isDark ? 0.05 : 0.15).toColor(),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(32),
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
                      _buildBranding(isDark),
                      const SizedBox(height: 32),
                      _buildFormHeader(isDark),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\-]')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _surnameController,
                        label: 'Surname',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\-]')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.alternate_email_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number (Optional)',
                        icon: Icons.phone_android_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      _buildRankDropdown(isDark, theme),
                      if (_selectedRank == 'Other') ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _otherRankController,
                          label: 'Specify Rank',
                          icon: Icons.work_outline_rounded,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isDark: isDark,
                        isPassword: true,
                        obscure: _obscurePassword,
                        formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                        toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        isDark: isDark,
                        isPassword: true,
                        obscure: _obscurePassword,
                        formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      ),
                      const SizedBox(height: 40),
                      _buildSubmitButton(theme, isDark),
                      const SizedBox(height: 24),
                      _buildLoginPrompt(isDark),
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

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
            ],
          ),
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/logo/logo.png'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'RavenVote Admin',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Account Enrollment',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Join the electoral management board',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRankDropdown(bool isDark, ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRank,
      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: 'Professional Rank',
        prefixIcon: const Icon(Icons.workspace_premium_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _ranks.map((rank) {
        return DropdownMenuItem(
          value: rank,
          child: Text(rank),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedRank = val;
        });
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword && toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: _isLoading 
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
          : Text(
              'SUBMIT ENROLLMENT',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 14),
            ),
      ),
    );
  }

  Widget _buildLoginPrompt(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade700)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
