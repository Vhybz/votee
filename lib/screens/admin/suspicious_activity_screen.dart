import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/app_footer.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';
import '../../services/ip_service.dart';
import '../../models/election_models.dart';
import '../../widgets/app_error_widget.dart';

class SuspiciousActivityScreen extends ConsumerStatefulWidget {
  const SuspiciousActivityScreen({super.key});

  @override
  ConsumerState<SuspiciousActivityScreen> createState() => _SuspiciousActivityScreenState();
}

class _SuspiciousActivityScreenState extends ConsumerState<SuspiciousActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final anomaliesAsync = ref.watch(anomalyProvider);

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
        appBar: AdminAppBar(
          title: 'Suspicious Activity',
          user: ref.watch(currentUserProvider),
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/suspicious',
            onTap: (route) => MenuService.navigate(context, route, '/admin/suspicious'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/suspicious',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/suspicious'),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      Expanded(
                        child: anomaliesAsync.when(
                          data: (anomalies) => _buildAnomalyList(anomalies),
                          loading: () => Skeletonizer(
                            enabled: true,
                            child: _buildAnomalyList(_fakeAnomalies),
                          ),
                          error: (e, s) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(anomalyProvider)),
                        ),
                      ),
                      const AppFooter(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fraud Detection',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28, 
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Review flagged anomalies and security alerts',
          style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildAnomalyList(List<Anomaly> anomalies) {
    if (anomalies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, size: 64, color: Colors.green.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text('No suspicious activity detected', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const Text('System status is optimal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: anomalies.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final anomaly = anomalies[index];
        final severityColor = _getSeverityColor(anomaly.severity);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
            side: BorderSide(color: severityColor.withValues(alpha: 0.2)),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 20),
            ),
            title: Text(anomaly.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              'Detected at ${anomaly.createdAt.toString().split('.')[0]}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alert Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(anomaly.details, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    if (anomaly.ipAddress != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.lan_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Source IP: ${anomaly.ipAddress}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _handleBlacklist(anomaly.ipAddress!),
                            icon: const Icon(Icons.block, size: 14),
                            label: const Text('BLACKLIST IP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high: return Colors.red;
      case AnomalySeverity.medium: return Colors.orange;
      case AnomalySeverity.low: return Colors.blue;
    }
  }

  Future<void> _handleBlacklist(String ip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blacklist IP Address?'),
        content: Text('Do you want to permanently restrict access from $ip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('CONFIRM BLACKLIST'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final admin = ref.read(currentUserProvider);
      if (admin != null) {
        await ref.read(ipServiceProvider).blacklistIp(ip, 'Suspicious activity detected', admin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IP $ip has been blacklisted.')));
        }
      }
    }
  }

  static final List<Anomaly> _fakeAnomalies = List.generate(3, (index) => Anomaly(
    id: 'fake-$index',
    title: 'Simulated Alert',
    details: 'This is a placeholder for a security event alert.',
    severity: index == 0 ? AnomalySeverity.high : AnomalySeverity.medium,
    createdAt: DateTime.now(),
  ));
}
