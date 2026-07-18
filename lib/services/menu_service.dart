import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';
import '../models/user_model.dart';
import 'user_provider.dart';

class MenuService {
  static List<SidebarItem> getMenuItemsForUser(UserAccount user) {
    return [
      SidebarItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin'),
      SidebarItem(icon: Icons.admin_panel_settings, label: 'Staff & Admins', route: '/admin/staff'),
      SidebarItem(icon: Icons.people, label: 'Voter Management', route: '/admin/voters'),
      SidebarItem(icon: Icons.how_to_reg, label: 'Candidates', route: '/admin/candidates'),
      SidebarItem(icon: Icons.poll, label: 'Live Results', route: '/admin/results'),
      SidebarItem(icon: Icons.security_update_warning, label: 'Suspicious Activity', route: '/admin/suspicious'),
      SidebarItem(icon: Icons.settings, label: 'Settings', route: '/admin/settings'),
    ];
  }

  static void navigate(BuildContext context, String route, String currentRoute) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }
}

final menuItemsProvider = Provider<List<SidebarItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return MenuService.getMenuItemsForUser(user);
});
