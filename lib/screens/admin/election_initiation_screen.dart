import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';
import '../../core/uuid_utils.dart';

class ElectionInitiationScreen extends ConsumerStatefulWidget {
  const ElectionInitiationScreen({super.key});

  @override
  ConsumerState<ElectionInitiationScreen> createState() => _ElectionInitiationScreenState();
}

class _ElectionInitiationScreenState extends ConsumerState<ElectionInitiationScreen> {
  final _titleController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  final Set<String> _selectedCandidateIds = {};
  bool _isInitiating = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with current settings if any
    Future.microtask(() {
      final settings = ref.read(electionSettingsProvider).value;
      if (settings != null) {
        _titleController.text = settings.electionTitle;
        _startTime = settings.startTime;
        _endTime = settings.endTime;
      }
      
      // Auto-select all candidates by default
      final candidates = ref.read(candidatesProvider).value ?? [];
      setState(() {
        _selectedCandidateIds.addAll(candidates.map((c) => c.id));
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = dt;
          } else {
            _endTime = dt;
          }
        });
      }
    }
  }

  Future<void> _handleInitiate() async {
    if (_titleController.text.isEmpty || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedCandidateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one aspirant')),
      );
      return;
    }

    setState(() => _isInitiating = true);

    try {
      final settings = ElectionSettings(
        id: UuidUtils.generate(), // New UUID for every new session
        electionTitle: _titleController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        isActive: true,
      );

      await ref.read(electionServiceProvider).updateSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Election Session Created!')),
        );
        Navigator.pushReplacementNamed(context, '/admin/elections');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);
    final positionsAsync = ref.watch(positionsProvider);
    
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
        appBar: AdminAppBar(title: 'Initiate Election', user: user),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/initiate',
            onTap: (route) => MenuService.navigate(context, route, '/admin/initiate'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/initiate',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/initiate'),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Election Session',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSetupCard(theme),
                      const SizedBox(height: 32),
                      
                      Text(
                        'Select Aspirants',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      candidatesAsync.when(
                        data: (candidates) => positionsAsync.when(
                          data: (positions) => _buildCandidateSelectionList(candidates, positions),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text('Error: $e'),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Error: $e'),
                      ),
                      
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _isInitiating ? null : _handleInitiate,
                          icon: _isInitiating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.rocket_launch_rounded),
                          label: Text(
                            _isInitiating ? 'STARTING...' : 'INITIATE LIVE ELECTION',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
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

  Widget _buildSetupCard(ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Election Name (e.g., 2026 SRC ELECTIONS)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 450;
                final children = [
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: ListTile(
                      title: const Text('Start Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      subtitle: Text(_startTime != null ? dateFormat.format(_startTime!) : 'Select Time', style: const TextStyle(fontSize: 11)),
                      leading: const Icon(Icons.play_circle_outline, size: 20),
                      onTap: () => _pickDateTime(true),
                      tileColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  if (!isSmall) const SizedBox(width: 16) else const SizedBox(height: 12),
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: ListTile(
                      title: const Text('End Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      subtitle: Text(_endTime != null ? dateFormat.format(_endTime!) : 'Select Time', style: const TextStyle(fontSize: 11)),
                      leading: const Icon(Icons.stop_circle_outlined, size: 20),
                      onTap: () => _pickDateTime(false),
                      tileColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ];
                
                return isSmall 
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children.map((e) => e is Expanded ? e.child : e).toList()) 
                  : Row(children: children);
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateSelectionList(List<Candidate> candidates, List<Position> positions) {
    return Column(
      children: positions.map((pos) {
        final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
        if (posCandidates.isEmpty) return const SizedBox();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(pos.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ...posCandidates.map((cand) => CheckboxListTile(
              title: Text(cand.fullName),
              subtitle: Text(cand.slogan, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              secondary: CircleAvatar(
                backgroundImage: cand.imageUrl != null ? NetworkImage(cand.imageUrl!) : null,
                child: cand.imageUrl == null ? const Icon(Icons.person) : null,
              ),
              value: _selectedCandidateIds.contains(cand.id),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedCandidateIds.add(cand.id);
                  } else {
                    _selectedCandidateIds.remove(cand.id);
                  }
                });
              },
            )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}
