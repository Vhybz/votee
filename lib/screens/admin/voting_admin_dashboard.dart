import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';

class VotingAdminDashboard extends ConsumerStatefulWidget {
  const VotingAdminDashboard({super.key});

  @override
  ConsumerState<VotingAdminDashboard> createState() => _VotingAdminDashboardState();
}

class _VotingAdminDashboardState extends ConsumerState<VotingAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          AppSidebar(
            items: menuItems,
            currentRoute: '/admin',
            onTap: (route) => MenuService.navigate(context, route, '/admin'),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(user),
                  const SizedBox(height: 32),
                  _buildKPIGrid(),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 1100) {
                        return Column(
                          children: [
                            _buildLiveParticipationChart(),
                            const SizedBox(height: 32),
                            _buildDistributionSection(),
                            const SizedBox(height: 32),
                            _buildRecentActivity(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildLiveParticipationChart(),
                                const SizedBox(height: 32),
                                _buildDistributionSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildRecentActivity(),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(UserAccount? user) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark),
                ),
                Text(
                  'Welcome, ${user?.firstName ?? 'Admin'} • Real-time Monitoring Active',
                  style: GoogleFonts.inter(color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.textLight, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('EXPORT RESULTS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildKPIGrid() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double aspectRatio = 2.0;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
          aspectRatio = 2.5;
        } else if (constraints.maxWidth < 1000) {
          crossAxisCount = 2;
          aspectRatio = 2.0;
        } else {
          crossAxisCount = 4;
          aspectRatio = 1.5;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: aspectRatio,
          children: [
            _buildKPICard('Total Registered', '4,820', Icons.people, theme.colorScheme.primary, '+12% from last year'),
            _buildKPICard('Total Votes Cast', '2,481', Icons.how_to_vote, AppColors.uenrGreen, '51.4% Participation'),
            _buildKPICard('Active Polls', '8', Icons.poll, AppColors.uenrYellow, 'All systems online'),
            _buildKPICard('Time Remaining', '04:12:05', Icons.timer, AppColors.uenrBrown, 'Closing at 5:00 PM'),
          ],
        );
      }
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color, String subtitle) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Expanded(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(color: theme.brightness == Brightness.dark ? Colors.white60 : AppColors.textLight, fontWeight: FontWeight.w500, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveParticipationChart() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Hourly Participation Trend', 
                    style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(8, 100),
                        const FlSpot(9, 450),
                        const FlSpot(10, 800),
                        const FlSpot(11, 1200),
                        const FlSpot(12, 1100),
                        const FlSpot(13, 1400),
                        const FlSpot(14, 1800),
                      ],
                      isCurved: true,
                      color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return Column(
            children: [
              _buildVotesBySchoolCard(),
              const SizedBox(height: 32),
              _buildParticipationByLevelCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVotesBySchoolCard()),
            const SizedBox(width: 32),
            Expanded(child: _buildParticipationByLevelCard()),
          ],
        );
      }
    );
  }

  Widget _buildVotesBySchoolCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votes by School', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(color: theme.colorScheme.primary, value: 40, title: '40%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: AppColors.uenrGreen, value: 30, title: '30%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: AppColors.uenrYellow, value: 20, title: '20%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: AppColors.uenrBrown, value: 10, title: '10%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLegendItem('School of Science', theme.colorScheme.primary),
            _buildLegendItem('School of Engineering', AppColors.uenrGreen),
            _buildLegendItem('School of Agriculture', AppColors.uenrYellow),
            _buildLegendItem('School of Arts', AppColors.uenrBrown),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationByLevelCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Participation by Level', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildLevelBar('Level 400', 0.85, theme.colorScheme.primary),
            _buildLevelBar('Level 300', 0.65, Colors.green),
            _buildLevelBar('Level 200', 0.45, Colors.orange),
            _buildLevelBar('Level 100', 0.30, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label, 
              style: GoogleFonts.inter(fontSize: 12, color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.textLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label, 
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Activity Feed', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildActivityItem('Voter Index #2041 Verified', '2 mins ago', Icons.verified_user, Colors.green),
            _buildActivityItem('Candidate Profile Updated', '15 mins ago', Icons.edit, Colors.blue),
            _buildActivityItem('Anomalous IP Detected', '45 mins ago', Icons.warning_amber_rounded, Colors.red),
            _buildActivityItem('New Bulk Import: 450 Voters', '1 hour ago', Icons.file_upload, Colors.orange),
            _buildActivityItem('Election Countdown Started', '3 hours ago', Icons.timer, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark)),
                Text(time, style: GoogleFonts.inter(color: theme.brightness == Brightness.dark ? Colors.white60 : AppColors.textLight, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
