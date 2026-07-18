import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';
import '../services/user_provider.dart';
import '../services/sidebar_provider.dart';
import '../models/user_model.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  SidebarItem({
    required this.icon, 
    required this.label, 
    required this.route,
  });
}

class AppSidebar extends ConsumerWidget {
  final List<SidebarItem> items;
  final String currentRoute;
  final Function(String route)? onTap;

  const AppSidebar({
    super.key,
    required this.items,
    required this.currentRoute,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 260 : 80,
      color: isDark ? Colors.black : const Color(0xFF1A1A1A),
      child: Column(
        children: [
          _buildHeader(theme, isExpanded, ref),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentRoute == item.route;
                return _buildMenuItem(context, item, isSelected, theme, isExpanded);
              },
            ),
          ),
          const Divider(color: Colors.white10),
          _buildUserSection(user, theme, isExpanded),
          _buildLogoutButton(context, ref, theme, isExpanded),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isExpanded, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (isExpanded)
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Image(image: AssetImage('assets/logo/logo.png')),
                  ),
                ),
              IconButton(
                icon: Icon(isExpanded ? Icons.chevron_left : Icons.menu, color: Colors.white),
                onPressed: () => ref.read(sidebarExpandedProvider.notifier).state = !isExpanded,
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Text(
              'RavenVote Admin',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SidebarItem item, bool isSelected, ThemeData theme, bool isExpanded) {
    final primaryColor = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white10 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 12),
        leading: Icon(
          item.icon, 
          color: isSelected ? (primaryColor == Colors.black ? Colors.white : primaryColor) : Colors.white60,
          size: 24,
        ),
        title: isExpanded 
          ? Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
        onTap: () {
          if (onTap != null) onTap!(item.route);
        },
      ),
    );
  }

  Widget _buildUserSection(UserAccount? user, ThemeData theme, bool isExpanded) {
    final primaryColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor == Colors.black ? Colors.white : primaryColor,
            child: Icon(Icons.person, color: primaryColor == Colors.black ? Colors.black : Colors.white, size: 20),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.role.name.toUpperCase() ?? 'ADMIN',
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, ThemeData theme, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () async {
          await GlobalLogout.perform(ref);
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/admin/login');
          }
        },
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 12, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white60, size: 20),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(color: Colors.white60)),
            ],
          ],
        ),
      ),
    );
  }
}
