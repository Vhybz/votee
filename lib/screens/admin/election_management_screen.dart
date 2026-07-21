import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';
import '../../widgets/app_error_widget.dart';
import '../../models/user_model.dart';

final allElectionsProvider = FutureProvider<List<ElectionSettings>>((ref) async {
  return ref.watch(electionServiceProvider).getAllElections();
});

class ElectionManagementScreen extends ConsumerStatefulWidget {
  const ElectionManagementScreen({super.key});

  @override
  ConsumerState<ElectionManagementScreen> createState() => _ElectionManagementScreenState();
}

class _ElectionManagementScreenState extends ConsumerState<ElectionManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final electionsAsync = ref.watch(allElectionsProvider);
    
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
        appBar: AdminAppBar(title: 'Election Registry', user: user),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/elections',
            onTap: (route) => MenuService.navigate(context, route, '/admin/elections'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/elections',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/elections'),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      Skeletonizer(
                        enabled: electionsAsync.isLoading,
                        child: electionsAsync.when(
                          data: (elections) {
                            var filteredElections = elections;
                            if (_searchQuery.isNotEmpty) {
                              filteredElections = elections.where((e) => e.electionTitle.toLowerCase().contains(_searchQuery)).toList();
                            }
                            return _buildElectionsList(filteredElections);
                          },
                          loading: () => _buildElectionsList(_fakeElections),
                          error: (e, s) => AppErrorWidget(
                            error: e,
                            onRetry: () => ref.invalidate(allElectionsProvider),
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

  static final List<ElectionSettings> _fakeElections = [
    ElectionSettings(
      id: 'e1', 
      electionTitle: 'Sample Election Session Title', 
      isActive: true,
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1)),
    ),
    ElectionSettings(
      id: 'e2', 
      electionTitle: 'Another Scheduled Election', 
      isActive: false,
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by election title...',
          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scheduled Sessions',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage all past, live, and upcoming election sessions',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/initiate'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('NEW SESSION'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ],
    );
  }

  Widget _buildElectionsList(List<ElectionSettings> elections) {
    if (elections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text('No election sessions found.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: elections.map((e) => _buildElectionCard(e)).toList(),
    );
  }

  Widget _buildElectionCard(ElectionSettings election) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user?.role == UserRole.superAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: election.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(
                    election.isActive ? Icons.sensors_rounded : Icons.calendar_today_rounded, 
                    color: election.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        election.electionTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (election.isActive)
                        const Text('LIVE NOW', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))
                      else
                        const Text('SCHEDULED / ARCHIVED', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                ),
                _buildStatusBadge(election),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildTimeInfo('START', election.startTime != null ? dateFormat.format(election.startTime!) : 'N/A'),
                _buildTimeInfo('END', election.endTime != null ? dateFormat.format(election.endTime!) : 'N/A'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSuperAdmin)
                      IconButton(
                        onPressed: () => _handleDeleteElection(election),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        tooltip: 'Delete Session',
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showElectionDetailsDialog(election),
                      style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                      child: const Text('VIEW DETAILS'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showElectionDetailsDialog(ElectionSettings election) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(election.electionTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Status', election.isActive ? 'ACTIVE' : 'INACTIVE', 
                election.isActive ? Colors.green : Colors.grey),
            const SizedBox(height: 16),
            _buildDetailItem('Start Date', election.startTime != null ? dateFormat.format(election.startTime!) : 'Not Set', null),
            _buildDetailItem('Start Time', election.startTime != null ? timeFormat.format(election.startTime!) : '--', null),
            const SizedBox(height: 16),
            _buildDetailItem('End Date', election.endTime != null ? dateFormat.format(election.endTime!) : 'Not Set', null),
            _buildDetailItem('End Time', election.endTime != null ? timeFormat.format(election.endTime!) : '--', null),
            const SizedBox(height: 24),
            if (election.startTime != null && election.endTime != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Total Duration: ${election.endTime!.difference(election.startTime!).inHours} Hours',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          if (!election.isActive)
            ElevatedButton(
              onPressed: () async {
                final updated = election.copyWith(isActive: true);
                await ref.read(electionServiceProvider).updateSettings(updated);
                ref.invalidate(allElectionsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ACTIVATE SESSION'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ElectionSettings election) {
    final now = DateTime.now();
    Color color = Colors.grey;
    String text = 'UNKNOWN';

    if (election.isActive) {
      text = 'LIVE';
      color = Colors.green;
    } else if (election.startTime != null && now.isBefore(election.startTime!)) {
      text = 'UPCOMING';
      color = Colors.blue;
    } else if (election.endTime != null && now.isAfter(election.endTime!)) {
      text = 'COMPLETED';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _handleDeleteElection(ElectionSettings election) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Election?'),
        content: Text('Remove "${election.electionTitle}" permanently? This will NOT delete associated votes or candidates, but the session record will be gone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(electionServiceProvider).deleteElection(election.id);
      ref.invalidate(allElectionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted.')));
      }
    }
  }
}
