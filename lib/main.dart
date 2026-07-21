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
import 'screens/admin/profile_screen.dart';
import 'screens/admin/election_initiation_screen.dart';
import 'screens/admin/election_management_screen.dart';
import 'screens/admin/vote_log_screen.dart';
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
import 'services/user_provider.dart';
import 'services/menu_service.dart';
import 'services/ip_service.dart';
import 'widgets/admin_appbar.dart';
import 'widgets/app_sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom Error Widget for Production-level crash reporting
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFF003366),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'UI Rendering Error: ${details.exception}',
          style: const TextStyle(color: Colors.yellow, fontSize: 12, fontFamily: 'monospace'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

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
      body: SafeArea(
        child: Container(
          color: const Color(0xFF003366), // Primary Blue
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
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('ENTER CONFIG MANUALLY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
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

    // System UI logic is now handled in builder to respond to theme changes
    return MaterialApp(
      title: 'RavenVote by TechRaven LTD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeState.primaryColor),
      darkTheme: AppTheme.getDarkTheme(themeState.primaryColor),
      themeMode: themeState.mode,
      builder: (context, child) {
        // Ensure system overlays match the current theme
        final bool isDarkMode = themeState.mode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
            // Use a solid, theme-appropriate color for the navigation bar to ensure it is always "detected"
            systemNavigationBarColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
            systemNavigationBarDividerColor: isDarkMode ? Colors.white10 : Colors.black12,
            systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );
        // Explicitly enabling top and bottom overlays ensures the system bars are treated as distinct areas
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
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
        '/admin/blacklist': (context) => const BlacklistManagementScreen(),
        '/admin/profile': (context) => const ProfileScreen(),
        '/admin/initiate': (context) => const ElectionInitiationScreen(),
        '/admin/elections': (context) => const ElectionManagementScreen(),
        '/admin/logs': (context) => const VoteLogScreen(),
      },
    );
  }
}

class BlacklistManagementScreen extends ConsumerStatefulWidget {
  const BlacklistManagementScreen({super.key});

  @override
  ConsumerState<BlacklistManagementScreen> createState() => _BlacklistManagementScreenState();
}

class _BlacklistManagementScreenState extends ConsumerState<BlacklistManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin');
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AdminAppBar(title: 'IP Blacklist', user: user),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/blacklist',
            onTap: (route) => MenuService.navigate(context, route, '/admin/blacklist'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/blacklist',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/blacklist'),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blacklist Management', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Manage IP addresses restricted from voting', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 32),
                      _buildAddIpCard(),
                      const SizedBox(height: 32),
                      _buildBlacklistTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddIpCard() {
    final ipController = TextEditingController();
    final reasonController = TextEditingController();
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual Blacklist', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: isDesktop ? 200 : double.infinity,
                  child: TextField(
                    controller: ipController, 
                    decoration: const InputDecoration(labelText: 'IP Address', border: OutlineInputBorder())
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 300 : double.infinity,
                  child: TextField(
                    controller: reasonController, 
                    decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())
                  ),
                ),
                SizedBox(
                  width: isDesktop ? null : double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (ipController.text.isEmpty) return;
                      final admin = ref.read(currentUserProvider);
                      if (admin == null) return;
                      await IpService().blacklistIp(ipController.text.trim(), reasonController.text, admin.id);
                      setState(() {});
                    },
                    child: const Text('BLACKLIST'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlacklistTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: IpService().getBlacklistedIps(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final ips = snapshot.data!;
        
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Current Blacklist', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (ips.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: Text('No IPs currently blacklisted.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ips.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = ips[index];
                    return ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(item['ip'], style: const TextStyle(fontFamily: 'monospace')),
                      subtitle: Text(item['reason'] ?? 'No reason provided'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await IpService().unblacklistIp(item['ip']);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
