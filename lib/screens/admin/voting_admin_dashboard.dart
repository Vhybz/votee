import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';
import '../../models/user_model.dart';
import '../../models/election_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/app_footer.dart';
import '../../services/report_service.dart';
import '../../services/backup_service.dart';
import '../../widgets/app_error_widget.dart';
import 'dart:math' as math;

class VotingAdminDashboard extends ConsumerStatefulWidget {
  const VotingAdminDashboard({super.key});

  @override
  ConsumerState<VotingAdminDashboard> createState() => _VotingAdminDashboardState();
}

class _VotingAdminDashboardState extends ConsumerState<VotingAdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Silent Automated Backup trigger on admin login/dashboard access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackupService().autoBackupIfRequired();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(electionStatsProvider);
    final anomaliesAsync = ref.watch(anomalyProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Stay on dashboard, or do nothing
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AdminAppBar(
          title: 'Command Center',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin',
            onTap: (route) => MenuService.navigate(context, route, '/admin'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin',
                  onTap: (route) => MenuService.navigate(context, route, '/admin'),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(user),
                      const SizedBox(height: 32),
                      Skeletonizer(
                        enabled: statsAsync.isLoading,
                        child: statsAsync.when(
                          data: (stats) => _buildDashboardContent(stats, anomaliesAsync, isDesktop),
                          loading: () => _buildDashboardContent(_fakeStats, const AsyncValue.loading(), isDesktop),
                          error: (err, stack) => AppErrorWidget(
                            error: err, 
                            stackTrace: stack,
                            onRetry: () => ref.invalidate(electionStatsProvider),
                          ),
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

  final _fakeStats = ElectionStats(
    totalVoters: 5000,
    totalVotesCast: 1200,
    turnoutPercentage: 24.5,
    activePolls: 8,
    timeRemaining: const Duration(hours: 4, minutes: 20),
    votesBySchool: {'Science': 300, 'Engineering': 250, 'Arts': 200},
    participationByLevel: {'100': 0.4, '200': 0.3, '300': 0.5},
    hourlyParticipation: {8: 10, 9: 50, 10: 120, 11: 200},
  );

  Widget _buildDashboardContent(ElectionStats stats, AsyncValue<List<Anomaly>> anomaliesAsync, bool isDesktop) {
    return Column(
      children: [
        _buildKPIGrid(stats),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1100) {
              return Column(
                children: [
                  _buildLiveParticipationChart(stats),
                  const SizedBox(height: 32),
                  _buildDistributionSection(stats),
                  const SizedBox(height: 32),
                  anomaliesAsync.when(
                    data: (anomalies) => _buildRecentActivity(anomalies),
                    loading: () => _buildRecentActivity([]),
                    error: (e, s) => const SizedBox(),
                  ),
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
                      _buildLiveParticipationChart(stats),
                      const SizedBox(height: 32),
                      _buildDistributionSection(stats),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: anomaliesAsync.when(
                    data: (anomalies) => _buildRecentActivity(anomalies),
                    loading: () => _buildRecentActivity([]),
                    error: (e, s) => const SizedBox(),
                  ),
                ),
              ],
            );
          }
        ),
      ],
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
                  'Overview',
                  style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textDark),
                ),
                Text(
                  'Live telemetry from all polling stations',
                  style: GoogleFonts.inter(color: theme.brightness == Brightness.dark ? Colors.white38 : AppColors.textLight, fontSize: 13),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/admin/initiate'),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: const Text('SETUP', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final stats = ref.read(electionStatsProvider).value;
                    final positions = ref.read(positionsProvider).value;
                    final candidates = ref.read(candidatesProvider).value;
                    final settings = ref.read(electionSettingsProvider).value;

                    if (stats == null || positions == null || candidates == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please wait for data to load before certifying.')),
                      );
                      return;
                    }

                    await ReportService.generateElectionReport(
                      title: settings?.electionTitle ?? 'RavenVote Election',
                      positions: positions,
                      candidates: candidates,
                      stats: stats,
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('CERTIFY', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildKPIGrid(ElectionStats stats) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 140,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildKPICard('REGISTRY', stats.totalVoters.toString(), Icons.people_outline_rounded, theme.colorScheme.primary, 'Total Students'),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/admin/logs'),
              child: _buildKPICard('BALLOTS', stats.totalVotesCast.toString(), Icons.how_to_vote_rounded, AppColors.primaryGreen, '${stats.turnoutPercentage.toStringAsFixed(1)}% Turnout'),
            ),
            _buildKPICard('POLLS', stats.activePolls.toString(), Icons.analytics_outlined, AppColors.primaryYellow, 'Live Positions'),
            _buildKPICard('TIMER', "${stats.timeRemaining.inHours.toString().padLeft(2, '0')}:${(stats.timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(stats.timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}", Icons.timer_outlined, AppColors.primaryBrown, 'System Lockdown'),
          ],
        );
      }
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: isDark ? Colors.white38 : AppColors.textLight, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveParticipationChart(ElectionStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Convert hourlyParticipation Map to sorted spots
    final List<FlSpot> spots = [];
    if (stats.hourlyParticipation.isEmpty) {
      // Show empty trend if no data
      spots.add(const FlSpot(0, 0));
    } else {
      final sortedHours = stats.hourlyParticipation.keys.toList()..sort();
      for (var hour in sortedHours) {
        spots.add(FlSpot(hour.toDouble(), stats.hourlyParticipation[hour]!.toDouble()));
      }
    }

    final maxY = stats.hourlyParticipation.isEmpty 
        ? 10.0 
        : (stats.hourlyParticipation.values.reduce(math.max).toDouble() * 1.2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Participation Trend', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Real-time hourly vote ingestion',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('SECURE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 20),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 23,
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 4 != 0) return const SizedBox();
                            return Text('${value.toInt()}h', style: const TextStyle(color: Colors.grey, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
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
    );
  }

  Widget _buildDistributionSection(ElectionStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return Column(
            children: [
              _buildVotesBySchoolCard(stats),
              const SizedBox(height: 32),
              _buildParticipationByLevelCard(stats),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVotesBySchoolCard(stats)),
            const SizedBox(width: 32),
            Expanded(child: _buildParticipationByLevelCard(stats)),
          ],
        );
      }
    );
  }

  Widget _buildVotesBySchoolCard(ElectionStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalVotes = stats.votesBySchool.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voting Distribution', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Aggregated by School', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            if (stats.votesBySchool.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No data available'),
              ))
            else ...[
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: stats.votesBySchool.entries.map((entry) {
                      final index = stats.votesBySchool.keys.toList().indexOf(entry.key);
                      final colors = [theme.colorScheme.primary, AppColors.primaryGreen, AppColors.primaryYellow, AppColors.primaryBrown, Colors.purple, Colors.orange];
                      return PieChartSectionData(
                        color: colors[index % colors.length], 
                        value: entry.value.toDouble(), 
                        radius: 45, 
                        showTitle: false
                      );
                    }).toList(),
                    sectionsSpace: 8,
                    centerSpaceRadius: 60,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ...stats.votesBySchool.entries.map((entry) {
                final index = stats.votesBySchool.keys.toList().indexOf(entry.key);
                final colors = [theme.colorScheme.primary, AppColors.primaryGreen, AppColors.primaryYellow, AppColors.primaryBrown, Colors.purple, Colors.orange];
                final percentage = totalVotes > 0 ? (entry.value / totalVotes * 100).toStringAsFixed(1) : '0';
                return _buildLegendItem(entry.key, colors[index % colors.length], '$percentage%');
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationByLevelCard(ElectionStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Participation', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Aggregated by Academic Level', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            if (stats.participationByLevel.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No data available'),
              ))
            else
              ...stats.participationByLevel.entries.map((entry) {
                 final colors = [theme.colorScheme.primary, Colors.green, Colors.orange, Colors.purple, Colors.blue];
                 final index = stats.participationByLevel.keys.toList().indexOf(entry.key);
                 return _buildLevelBar('Level ${entry.key}', entry.value, colors[index % colors.length]);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label, 
              style: GoogleFonts.inter(fontSize: 12, color: theme.brightness == Brightness.dark ? Colors.white60 : AppColors.textLight, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLevelBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label, 
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text('${(value * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
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

  Widget _buildRecentActivity(List<Anomaly> anomalies) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security Feed', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Real-time anomaly monitoring', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            if (anomalies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No anomalies detected.', style: TextStyle(fontSize: 12, color: Colors.grey))),
              )
            else
              ...anomalies.take(5).map((a) => _buildActivityItem(
                a.title, 
                a.time, 
                a.severity == AnomalySeverity.high ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded, 
                a.severity == AnomalySeverity.high ? Colors.red : Colors.orange
              )),
            if (anomalies.length > 5)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin/suspicious'), 
                  child: const Text('VIEW ALL AUDITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0))
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textDark)
                ),
                Text(time, style: GoogleFonts.inter(color: isDark ? Colors.white24 : AppColors.textLight, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
