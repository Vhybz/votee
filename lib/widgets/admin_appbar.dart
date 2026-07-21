import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/sidebar_provider.dart';

class AdminAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final UserAccount? user;
  final List<Widget>? actions;

  const AdminAppBar({
    super.key,
    required this.title,
    this.user,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1100;
    final isExpanded = ref.watch(sidebarExpandedProvider);

    final appBarBg = isDark ? Colors.black : const Color(0xFF1A1A1A);

    return AppBar(
      elevation: 0,
      backgroundColor: appBarBg,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDesktop 
                ? (isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded)
                : Icons.menu_rounded, 
              color: Colors.white, 
              size: 20,
            ),
          ),
          onPressed: () {
            if (isDesktop) {
              ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          if (user != null)
            Text(
              '${user!.firstName} • Admin',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        ...?actions,
        const SizedBox(width: 8),
        _buildNotificationButton(context),
        if (user != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/admin/profile'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white10,
              backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: (user!.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/voter/verify', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('SIGN OUT', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
          tooltip: 'Sign Out',
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}
