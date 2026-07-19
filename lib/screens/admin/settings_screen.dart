import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/theme_provider.dart';
import '../../services/election_provider.dart';
import '../../services/backup_service.dart';
import '../../models/election_models.dart';
import '../../models/user_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(electionSettingsProvider);
    
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
          title: 'Settings',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/settings',
            onTap: (route) => MenuService.navigate(context, route, '/admin/settings'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/settings',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/settings'),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle(context, 'Appearance'),
                      _buildThemeSetting(context, ref, themeState),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'System Security'),
                      _buildBackupCard(context),

                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Election Window'),
                      settingsAsync.when(
                        data: (settings) => _buildElectionTimingCard(context, ref, settings),
                        loading: () => const Center(child: LinearProgressIndicator()),
                        error: (e, s) => Text('Error loading settings: $e'),
                      ),
    
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'General Parameters'),
                      settingsAsync.when(
                        data: (settings) => Column(
                          children: [
                            _buildSettingTile(
                              context,
                              'Election Title',
                              settings.electionTitle,
                              Icons.edit_note,
                              () => _showEditTitleDialog(context, ref, settings),
                            ),
                            _buildSettingTile(
                              context,
                              'Security & MFA',
                              'SMS OTP Enabled',
                              Icons.security,
                              () {},
                            ),
                            if (user?.role == UserRole.superAdmin) ...[
                              const SizedBox(height: 32),
                              _buildDangerZone(context, ref),
                            ],
                          ],
                        ),
                        loading: () => const SizedBox(),
                        error: (e, s) => const SizedBox(),
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

  Widget _buildBackupCard(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('System Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Export all election data, logs, and student records to a JSON file.', style: TextStyle(fontSize: 11)),
              trailing: _isBackingUp 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    onPressed: _handleManualBackup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('BACKUP NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualBackup() async {
    setState(() => _isBackingUp = true);
    try {
      await BackupService().performFullBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created and downloaded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(BuildContext context, WidgetRef ref, ThemeState state) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Switch between light and dark themes', style: TextStyle(fontSize: 12)),
              trailing: Switch(
                value: state.mode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme(value);
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Primary Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Brand color used throughout the app', style: TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _colorPicker(ref, Colors.black, state.primaryColor, state.mode == ThemeMode.dark),
                  _colorPicker(ref, AppColors.primaryBlue, state.primaryColor, state.mode == ThemeMode.dark),
                  _colorPicker(ref, AppColors.primaryGreen, state.primaryColor, state.mode == ThemeMode.dark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorPicker(WidgetRef ref, Color color, Color currentColor, bool isDark) {
    final bool isSelected = color.toARGB32() == currentColor.toARGB32();
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setPrimaryColor(color),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color == Colors.black && isDark ? Colors.white : color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
        ),
        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildElectionTimingCard(BuildContext context, WidgetRef ref, ElectionSettings settings) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Voting Status', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(settings.isActive ? 'SYSTEM LIVE - Accepting Votes' : 'SYSTEM IDLE - Voting Disabled'),
              trailing: Switch(
                value: settings.isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) async {
                   final updated = settings.copyWith(isActive: val);
                   await ref.read(electionServiceProvider).updateSettings(updated);
                },
              ),
            ),
            const Divider(),
            _buildTimeTile(
              context, 
              'Start Time', 
              settings.startTime != null ? dateFormat.format(settings.startTime!) : 'Not Scheduled',
              Icons.play_circle_outline,
              () => _pickDateTime(context, ref, settings, true),
            ),
            _buildTimeTile(
              context, 
              'End Time', 
              settings.endTime != null ? dateFormat.format(settings.endTime!) : 'Not Scheduled',
              Icons.stop_circle_outlined,
              () => _pickDateTime(context, ref, settings, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(value, style: const TextStyle(fontSize: 12)),
          trailing: TextButton(
            onPressed: onTap, 
            child: const Text('SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(value, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DANGER ZONE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.redAccent.withValues(alpha: 0.05),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.redAccent, width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: const Text('Purge Election Data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            subtitle: const Text('Delete all votes, reset student status, and clear current session.', style: TextStyle(fontSize: 12)),
            onTap: () => _handlePurgeElection(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurgeElection(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe All Election Data?'),
        content: const Text('This will permanently delete all cast votes, reset every student\'s "has voted" status, and clear the current election session. This CANNOT be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('WIPE EVERYTHING'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(electionServiceProvider).purgeElectionData();
      ref.invalidate(electionSettingsProvider);
      ref.invalidate(electionStatsProvider);
      ref.invalidate(votersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System has been completely reset.'))
        );
      }
    }
  }

  Future<void> _pickDateTime(BuildContext context, WidgetRef ref, ElectionSettings settings, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final finalDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        final updated = isStart 
            ? settings.copyWith(startTime: finalDateTime)
            : settings.copyWith(endTime: finalDateTime);
        
        await ref.read(electionServiceProvider).updateSettings(updated);
      }
    }
  }

  Future<void> _showEditTitleDialog(BuildContext context, WidgetRef ref, ElectionSettings settings) async {
    final controller = TextEditingController(text: settings.electionTitle);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Election Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updated = settings.copyWith(electionTitle: controller.text.trim());
                await ref.read(electionServiceProvider).updateSettings(updated);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
