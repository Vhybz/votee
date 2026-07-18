import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          AppSidebar(
            items: menuItems,
            currentRoute: '/admin/staff',
            onTap: (route) => MenuService.navigate(context, route, '/admin/staff'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(child: _buildUserList(users)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Staff & Admin Management',
          style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          'Approve or manage system administrators and officials',
          style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUserList(List<UserAccount> users) {
    if (users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: user.status == AccountStatus.approved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              child: Icon(
                user.role == UserRole.superAdmin ? Icons.shield : Icons.person,
                color: user.status == AccountStatus.approved ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user.email} • ${user.role.name.toUpperCase()}'),
            trailing: _buildActions(user),
          );
        },
      ),
    );
  }

  Widget _buildActions(UserAccount user) {
    if (user.status == AccountStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _handleApproval(user, AccountStatus.approved),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('APPROVE'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _handleApproval(user, AccountStatus.suspended),
            child: const Text('REJECT'),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user.status == AccountStatus.approved ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.status.name.toUpperCase(),
            style: TextStyle(
              color: user.status == AccountStatus.approved ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {},
        ),
      ],
    );
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
