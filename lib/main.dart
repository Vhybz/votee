import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/voting_admin_dashboard.dart';
import 'screens/admin/voter_management_screen.dart';
import 'screens/admin/staff_management_screen.dart';
import 'screens/admin/candidate_management_screen.dart';
import 'screens/admin/settings_screen.dart';
import 'screens/admin/suspicious_activity_screen.dart';
import 'screens/admin/live_results_screen.dart';
import 'screens/voter/index_verification_screen.dart';
import 'screens/voter/identity_confirmation_screen.dart';
import 'screens/voter/otp_verification_screen.dart';
import 'screens/voter/voting_screen.dart';
import 'screens/voter/receipt_screen.dart';
import 'services/theme_provider.dart';
import 'services/sync_provider.dart';
import 'core/supabase_config.dart';
import 'services/push_notification_service.dart';
import 'services/offline_sync_service.dart';

import 'screens/auth/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    // 1. Load Environment Variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      try {
        await dotenv.load(fileName: "assets/.env");
      } catch (e) {
        debugPrint('CRITICAL: .env could not be loaded. AI and Cloud features may fail: $e');
      }
    }

    // 2. Unified Supabase Initialization (Optional in UI-Only Mode)
    try {
      await SupabaseConfig.initialize();
      if (kDebugMode) {
        debugPrint('SYSTEM STATUS: Cloud Backend Connected.');
      }
    } catch (e) {
      debugPrint('SUPABASE BYPASS: Operating in UI-Only Mode. ($e)');
      // We don't rethrow here to allow the app to run without a database
    }

    // 3. Initialize Offline Sync Engine (Hive)
    await OfflineSyncService.initialize();

    // 4. Initialize System Tray Notifications (Graceful failure)
    try {
      await PushNotificationService.initialize();
    } catch (e) {
      debugPrint('Push Notification initialization failed: $e');
    }

    runApp(
      const ProviderScope(
        child: RavenVoteApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('CRITICAL INITIALIZATION FAILURE: $e');
    debugPrint('STACK TRACE: $stack');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InitializationErrorScreen(
          errorMessage: e.toString(),
          stackTrace: stack.toString(),
        ),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final String? stackTrace;
  const InitializationErrorScreen({super.key, this.errorMessage, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF003366), // UENR Blue
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 80),
                const SizedBox(height: 32),
                const Text(
                  'Configuration Missing',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 800,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!.contains('minified') 
                            ? 'Technical Error (Minified): $errorMessage\n\nThis usually means Supabase failed to initialize on Web. Check your browser console (F12) for the exact error.'
                            : 'Technical Error: $errorMessage',
                          style: const TextStyle(color: Colors.yellowAccent, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (stackTrace != null) ...[
                          const Divider(color: Colors.white24),
                          Text(
                            stackTrace!,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                            maxLines: 15,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _showManualConfigDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF003366),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ENTER CONFIG MANUALLY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showManualConfigDialog(BuildContext context) {
  final urlController = TextEditingController();
  final keyController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Manual Supabase Config'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Supabase URL', hintText: 'https://xxx.supabase.co'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: keyController,
            decoration: const InputDecoration(labelText: 'Anon Key'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () async {
            if (urlController.text.isNotEmpty && keyController.text.isNotEmpty) {
              try {
                await Supabase.initialize(
                  url: urlController.text.trim(),
                  publishableKey: keyController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Config saved! Please refresh the page.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Initialization failed: $e')),
                  );
                }
              }
            }
          },
          child: const Text('INITIALIZE'),
        ),
      ],
    ),
  );
}

class RavenVoteApp extends ConsumerWidget {
  const RavenVoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    ref.watch(syncProvider);

    // Apply system UI settings
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return MaterialApp(
      title: 'RavenVote - UENR E-Voting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeState.primaryColor),
      darkTheme: AppTheme.getDarkTheme(themeState.primaryColor),
      themeMode: themeState.mode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/voter/confirm') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => IdentityConfirmationScreen(student: args['student']),
          );
        }
        if (settings.name == '/voter/otp') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(student: args['student']),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/voter/verify': (context) => const IndexVerificationScreen(),
        '/voter/vote': (context) => const VotingScreen(),
        '/voter/receipt': (context) => const ReceiptScreen(),
        '/admin/login': (context) => const LoginScreen(),
        '/admin/register': (context) => const RegisterScreen(),
        '/admin': (context) => const VotingAdminDashboard(),
        '/admin/staff': (context) => const StaffManagementScreen(),
        '/admin/voters': (context) => const VoterManagementScreen(),
        '/admin/candidates': (context) => const CandidateManagementScreen(),
        '/admin/results': (context) => const LiveResultsScreen(),
        '/admin/settings': (context) => const SettingsScreen(),
        '/admin/suspicious': (context) => const SuspiciousActivityScreen(),
      },
    );
  }
}
