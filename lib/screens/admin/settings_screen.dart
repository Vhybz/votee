import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItems = ref.watch(menuItemsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
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
                    'Settings',
                    style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Appearance'),
                  _buildThemeSetting(context, ref, themeState),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Election Parameters'),
                  _buildSettingTile(
                    context,
                    'Election Name',
                    'RavenVote - UENR SRC Elections 2024',
                    Icons.edit_note,
                    () {},
                  ),
                  _buildSettingTile(
                    context,
                    'Voting Start/End Times',
                    '08:00 AM - 05:00 PM',
                    Icons.timer_outlined,
                    () {},
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Security'),
                  _buildSettingTile(
                    context,
                    'MFA Method',
                    'SMS OTP',
                    Icons.security,
                    () {},
                  ),
                  _buildSettingTile(
                    context,
                    'Audit Log Retention',
                    '90 Days',
                    Icons.history,
                    () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          color: theme.colorScheme.primary == Colors.black && theme.brightness == Brightness.dark ? Colors.white70 : theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(BuildContext context, WidgetRef ref, ThemeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark themes'),
              trailing: Switch(
                value: state.mode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme(value);
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Primary Color'),
              subtitle: const Text('Change the brand color used throughout the app'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _colorPicker(ref, Colors.black, state.primaryColor, state.mode == ThemeMode.dark),
                  _colorPicker(ref, AppColors.uenrBlue, state.primaryColor, state.mode == ThemeMode.dark),
                  _colorPicker(ref, AppColors.uenrGreen, state.primaryColor, state.mode == ThemeMode.dark),
                  _colorPicker(ref, Colors.deepPurple, state.primaryColor, state.mode == ThemeMode.dark),
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color == Colors.black && isDark ? Colors.white : color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: isSelected ? [const BoxShadow(blurRadius: 4, color: Colors.black26)] : null,
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDark ? Colors.white70 : theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
