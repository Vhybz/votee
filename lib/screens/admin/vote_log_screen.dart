import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';

class VoteLogScreen extends ConsumerStatefulWidget {
  const VoteLogScreen({super.key});

  @override
  ConsumerState<VoteLogScreen> createState() => _VoteLogScreenState();
}

class _VoteLogScreenState extends ConsumerState<VoteLogScreen> {
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
        appBar: AdminAppBar(title: 'Audit Trail', user: user),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/logs',
            onTap: (route) => MenuService.navigate(context, route, '/admin/logs'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/logs',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/logs'),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: ref.read(electionServiceProvider).getVoteLogs(),
                          builder: (context, snapshot) {
                            final isLoading = snapshot.connectionState == ConnectionState.waiting;
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            
                            var logs = snapshot.data ?? (isLoading ? _fakeLogs : []);
                            
                            // Apply filtering if search query is not empty
                            if (_searchQuery.isNotEmpty && !isLoading) {
                              logs = logs.where((log) {
                                final student = log['students'] as Map<String, dynamic>?;
                                final name = (student?['full_name'] ?? '').toString().toLowerCase();
                                final index = (student?['index_number'] ?? '').toString().toLowerCase();
                                return name.contains(_searchQuery) || index.contains(_searchQuery);
                              }).toList();
                            }

                            if (logs.isEmpty && !isLoading) {
                              return const Center(child: Text('No matching records found.'));
                            }
                            return Skeletonizer(
                              enabled: isLoading,
                              child: _buildLogsTable(logs),
                            );
                          },
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

  final List<Map<String, dynamic>> _fakeLogs = List.generate(10, (index) => {
    'timestamp': DateTime.now().toIso8601String(),
    'students': {'full_name': 'Sample Student Name', 'index_number': '12345678'},
    'candidates': {'full_name': 'Sample Candidate'},
    'positions': {'title': 'Sample Position'},
  });

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
          hintText: 'Search by student name or index number...',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voting Audit Log',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Real-time transaction history of all cast ballots',
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLogsTable(List<Map<String, dynamic>> logs) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView.separated(
        itemCount: logs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          final timestamp = DateTime.parse(log['timestamp']).toLocal();
          final student = log['students'] as Map<String, dynamic>?;
          final candidate = log['candidates'] as Map<String, dynamic>?;
          final position = log['positions'] as Map<String, dynamic>?;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.history_toggle_off_rounded, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  student?['full_name'] ?? 'Unknown Student',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${student?['index_number'] ?? 'N/A'})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12),
                  children: [
                    const TextSpan(text: 'Voted for '),
                    TextSpan(
                      text: candidate?['full_name'] ?? 'Candidate',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' for '),
                    TextSpan(
                      text: position?['title'] ?? 'Position',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm:ss a').format(timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
