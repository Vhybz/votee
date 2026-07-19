import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';
import '../services/auth_provider.dart';
import 'auth/password_recovery_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(AppStrings.entryRequiredTitle, AppStrings.entryRequiredMessage);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage(AppStrings.invalidEmailTitle, AppStrings.invalidEmailMessage);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ref.read(authServiceProvider).signIn(email, password);
      
      if (response.user != null) {
        final notifier = ref.read(userProvider.notifier);
        
        UserAccount? userAccount;
        try {
          userAccount = ref.read(userProvider).firstWhere((u) => u.id == response.user!.id);
        } catch (_) {
          await notifier.loadUsers();
          userAccount = ref.read(userProvider).where((u) => u.id == response.user!.id).firstOrNull;
        }

        if (userAccount == null) {
          await GlobalLogout.perform(ref);
          if (mounted) {
            _showMessage(AppStrings.profileMissingTitle, AppStrings.profileMissingMessage);
          }
          return;
        }

        if (userAccount.status == AccountStatus.pending) {
          await GlobalLogout.perform(ref);
          if (mounted) {
            _showMessage(
              AppStrings.approvalPendingTitle, 
              AppStrings.approvalPendingMessage,
              isWarning: true
            );
          }
          return;
        }

        if (userAccount.status == AccountStatus.suspended) {
          await GlobalLogout.perform(ref);
          if (mounted) {
             _showMessage(AppStrings.accountSuspendedTitle, AppStrings.accountSuspendedMessage, isError: true);
          }
          return;
        }

        ref.read(currentUserIdProvider.notifier).state = userAccount.id;

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(AppStrings.loginFailedTitle, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String title, String message, {bool isError = false, bool isWarning = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline),
              color: isError ? Colors.red : (isWarning ? Colors.orange : AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      Color.lerp(theme.colorScheme.primary, Colors.black, 0.6 * _bgAnimationController.value)!,
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF121212) 
                        : Colors.white,
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2), 
                        blurRadius: 40, 
                        offset: const Offset(0, 20)
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(isMobile),
                      const SizedBox(height: 32),
                      _buildHeader(theme, isMobile, isDark),
                      const SizedBox(height: 40),
                      _buildForm(theme, isDark),
                      const SizedBox(height: 40),
                      _buildLoginButton(theme, isDark),
                      const SizedBox(height: 24),
                      _buildFooterLinks(isDark),
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

  Widget _buildLogo(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15),
        ],
      ),
      child: CircleAvatar(
        radius: isMobile ? 40 : 50,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile, bool isDark) {
    return Column(
      children: [
        Text(
          AppStrings.loginTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 26 : 30, 
            fontWeight: FontWeight.w800, 
            color: isDark ? Colors.white : theme.colorScheme.primary,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.loginSubtitle.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white38 : theme.colorScheme.primary.withValues(alpha: 0.5), 
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(
            labelText: "Admin Email",
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: AppStrings.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: _isLoading 
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
            : Text(
                AppStrings.loginButton.toUpperCase(), 
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)
              ),
      ),
    );
  }

  Widget _buildFooterLinks(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen())),
          child: Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade700)),
        ),
        const Text('•', style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/admin/register'),
          child: Text('Request Access', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade700)),
        ),
      ],
    );
  }
}
