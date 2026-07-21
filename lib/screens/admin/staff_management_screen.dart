import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/app_footer.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final users = ref.watch(userProvider);
    final user = ref.watch(currentUserProvider);
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
          title: 'Staff Management',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.5,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/staff',
            onTap: (route) => MenuService.navigate(context, route, '/admin/staff'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/staff',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/staff'),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      Expanded(
                        child: Skeletonizer(
                          enabled: users.isEmpty,
                          child: _buildUserList(users.isEmpty ? _fakeUsers : users),
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

  static final List<UserAccount> _fakeUsers = List.generate(5, (index) => UserAccount(
    id: 'fake-$index',
    firstName: 'Sample',
    surname: 'Admin',
    email: 'admin$index@example.com',
    role: UserRole.admin,
    status: AccountStatus.approved,
    createdAt: DateTime.now(),
  ));

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Personnel',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28, 
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Manage administrative roles and access levels',
          style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildUserList(List<UserAccount> users) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    UserAccount? rootAdmin;
    if (users.isNotEmpty) {
      rootAdmin = users.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final user = users[index];
        final isRoot = rootAdmin?.id == user.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: user.status == AccountStatus.approved ? Colors.green.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: user.status == AccountStatus.approved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? Icon(
                                user.role == UserRole.superAdmin ? Icons.shield : Icons.person,
                                color: user.status == AccountStatus.approved ? Colors.green : Colors.orange,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    if (isRoot)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                          child: const Icon(Icons.star, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            user.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.rank != null && user.rank!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.rank!,
                                style: TextStyle(fontSize: 8, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (isRoot)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('FOUNDER', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildActions(user, isRoot),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(UserAccount targetUser, bool isRoot) {
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;

    if (targetUser.status == AccountStatus.pending) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => _handleApproval(targetUser, AccountStatus.approved),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: const Text('APPROVE'),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => _handleApproval(targetUser, AccountStatus.suspended),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: const Text('REJECT'),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: targetUser.status == AccountStatus.approved ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            targetUser.status.name.toUpperCase(),
            style: TextStyle(
              color: targetUser.status == AccountStatus.approved ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
        if (isSuperAdmin && targetUser.id != currentUser?.id && !isRoot) ...[
          PopupMenuButton<dynamic>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text('ROLE: ${targetUser.role.name.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              ...UserRole.values.where((r) => r != targetUser.role).map((role) {
                return PopupMenuItem(
                  onTap: () => _handleRoleChange(targetUser, role),
                  child: Text('Set as ${role.name.toUpperCase()}', style: const TextStyle(fontSize: 13)),
                );
              }),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () => _handleDeleteUser(targetUser),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Remove Staff', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ] else
          const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleDeleteUser(UserAccount user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff Member'),
        content: Text('Are you sure you want to remove ${user.name} from the system? This will revoke all access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userServiceProvider).deleteUser(user.id);
      // userProvider (StateNotifier) automatically handles the state update if implemented
      // or we can refresh manually
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} removed.')),
        );
      }
    }
  }

  Future<void> _handleRoleChange(UserAccount user, UserRole newRole) async {
    if (user.role == newRole) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text('Change ${user.name}\'s role to ${newRole.name.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedUser = user.copyWith(role: newRole);
      await ref.read(userServiceProvider).updateUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} is now an ${newRole.name.toUpperCase()}')),
        );
      }
    }
  }

  Future<void> _handleApproval(UserAccount user, AccountStatus newStatus) async {
    final updatedUser = user.copyWith(status: newStatus);
    await ref.read(userServiceProvider).updateUser(updatedUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account ${newStatus.name}')),
      );
    }
  }
}
