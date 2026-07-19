import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../models/election_models.dart';
import '../../services/election_provider.dart';
import '../../services/ip_service.dart';

class SuspiciousActivityScreen extends ConsumerStatefulWidget {
  const SuspiciousActivityScreen({super.key});

  @override
  ConsumerState<SuspiciousActivityScreen> createState() => _SuspiciousActivityScreenState();
}

class _SuspiciousActivityScreenState extends ConsumerState<SuspiciousActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItems = ref.watch(menuItemsProvider);
    final anomaliesAsync = ref.watch(anomalyProvider);
    final user = ref.watch(currentUserProvider);
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
          title: 'Security Monitor',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.5,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      Skeletonizer(
                        enabled: anomaliesAsync.isLoading,
                        child: anomaliesAsync.when(
                          data: (anomalies) => Column(
                            children: [
                              _buildStatsGrid(anomalies.isEmpty && anomaliesAsync.isLoading ? _fakeAnomalies : anomalies),
                              const SizedBox(height: 32),
                              _buildAnomalyLog(isDark, anomalies.isEmpty && anomaliesAsync.isLoading ? _fakeAnomalies : anomalies),
                            ],
                          ),
                          loading: () => Column(
                            children: [
                              _buildStatsGrid(_fakeAnomalies),
                              const SizedBox(height: 32),
                              _buildAnomalyLog(isDark, _fakeAnomalies),
                            ],
                          ),
                          error: (err, stack) => Center(child: Text('Error loading security logs: $err')),
                        ),
                      ),
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

  static final List<AnomalyAlert> _fakeAnomalies = List.generate(3, (index) => AnomalyAlert(
    id: 'fake-$index',
    title: 'Sample Security Alert',
    details: 'This is a sample description of a potential security anomaly detected by the system.',
    time: '2 mins ago',
    severity: index == 0 ? AnomalySeverity.high : AnomalySeverity.medium,
  ));

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fraud Detection',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Monitoring potential voting anomalies and system breaches',
              style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('SYSTEM SECURE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<AnomalyAlert> alerts) {
    final highCount = alerts.where((a) => a.severity == AnomalySeverity.high).length;
    final mediumCount = alerts.where((a) => a.severity == AnomalySeverity.medium).length;
    final lowCount = alerts.where((a) => a.severity == AnomalySeverity.low).length;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 3.0,
      children: [
        _buildStatCard('High Severity', highCount.toString(), Colors.red, Icons.gpp_bad),
        _buildStatCard('Medium Severity', mediumCount.toString(), Colors.orange, Icons.warning_amber_rounded),
        _buildStatCard('Informational', lowCount.toString(), Colors.blue, Icons.info_outline),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
                  Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyLog(bool isDark, List<AnomalyAlert> alerts) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anomaly Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton.icon(
                  onPressed: () => ref.invalidate(anomalyProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('REFRESH', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (alerts.isEmpty)
             const Padding(
               padding: EdgeInsets.all(48.0),
               child: Center(child: Text('No anomalies detected. System is clean.')),
             )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final color = _getSeverityColor(alert.severity);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(
                      _getSeverityIcon(alert.severity),
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      const SizedBox(width: 12),
                      _buildSeverityBadge(alert.severity),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(alert.details, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(alert.time, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showAlertDetails(alert),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high: return Colors.red;
      case AnomalySeverity.medium: return Colors.orange;
      case AnomalySeverity.low: return Colors.blue;
    }
  }

  IconData _getSeverityIcon(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high: return Icons.gpp_bad;
      case AnomalySeverity.medium: return Icons.warning_amber_rounded;
      case AnomalySeverity.low: return Icons.info_outline;
    }
  }

  Widget _buildSeverityBadge(AnomalySeverity severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAlertDetails(AnomalyAlert alert) {
    // Try to extract IP from details if possible (e.g. "10.24.51.92")
    final ipMatch = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b').firstMatch(alert.details);
    final detectedIp = ipMatch?.group(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${alert.time}'),
            const SizedBox(height: 12),
            Text(alert.details),
            const SizedBox(height: 16),
            const Text('AI Recommendation:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('The system recommends flagging this ID for secondary audit before certifying results.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS')),
          if (detectedIp != null)
            ElevatedButton.icon(
              onPressed: () async {
                final admin = ref.read(currentUserProvider);
                if (admin != null) {
                  await IpService().blacklistIp(detectedIp, 'Anomalous activity: ${alert.title}', admin.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IP $detectedIp Blacklisted')));
                  }
                }
              },
              icon: const Icon(Icons.block, size: 18),
              label: const Text('BLACKLIST IP'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('FLAG FOR AUDIT')),
        ],
      ),
    );
  }
}
