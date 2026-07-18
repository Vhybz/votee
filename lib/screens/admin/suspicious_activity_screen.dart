import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';

class SuspiciousActivityScreen extends ConsumerWidget {
  const SuspiciousActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
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
                  Text(
                    'Suspicious Activity',
                    style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'AI-powered monitoring of potential voting anomalies',
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildActivityList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('Rapid Votes', '12', Colors.orange),
        _buildStatCard('Duplicate IP', '4', Colors.red),
        _buildStatCard('Failed OTPs', '45', Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: GoogleFonts.oswald(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Anomaly Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    index % 2 == 0 ? Icons.warning_rounded : Icons.info_outline,
                    color: index % 2 == 0 ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                ),
                title: Text(
                  index % 2 == 0 ? 'Multiple votes from same IP' : 'High frequency voting detected',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: const Text('ID: 20001234 • 10.24.51.92'),
                trailing: Text('2 mins ago', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              );
            },
          ),
          const Padding(padding: EdgeInsets.all(12)),
        ],
      ),
    );
  }
}
