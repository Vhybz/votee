import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../widgets/app_footer.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isSaving = false;
  Uint8List? _newPhotoBytes;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _firstNameController.text = user.firstName;
      _surnameController.text = user.surname;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _newPhotoBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = user.photoUrl;

      if (_newPhotoBytes != null && _pickedFile != null) {
        photoUrl = await ref.read(userServiceProvider).uploadProfilePicture(
          user.id,
          _newPhotoBytes!,
          ext: _pickedFile!.name.split('.').last,
        );
      }

      final updatedUser = user.copyWith(
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        photoUrl: photoUrl,
      );

      await ref.read(userServiceProvider).updateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        appBar: AdminAppBar(title: 'My Profile', user: user),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/profile',
            onTap: (route) => MenuService.navigate(context, route, '/admin/profile'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/profile',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/profile'),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Settings',
                            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          _buildProfileCard(user, theme),
                          const AppFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserAccount? user, ThemeData theme) {
    if (user == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _newPhotoBytes != null 
                        ? MemoryImage(_newPhotoBytes!) as ImageProvider
                        : (user.photoUrl != null && user.photoUrl!.isNotEmpty 
                            ? NetworkImage(user.photoUrl!) as ImageProvider
                            : null),
                    child: (_newPhotoBytes == null && (user.photoUrl == null || user.photoUrl!.isEmpty))
                        ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton.small(
                      heroTag: 'pick_image',
                      onPressed: _pickImage,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              icon: Icons.person_outline,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\-]')),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _surnameController,
              label: 'Surname',
              icon: Icons.person_outline,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\-]')),
              ],
            ),
            const SizedBox(height: 24),
            // Rank is disabled
            TextField(
              enabled: false,
              controller: TextEditingController(text: user.rank ?? 'Staff'),
              decoration: const InputDecoration(
                labelText: 'Professional Rank',
                prefixIcon: Icon(Icons.workspace_premium_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Email is disabled
            TextField(
              enabled: false,
              controller: TextEditingController(text: user.email),
              decoration: const InputDecoration(
                labelText: 'Email Address (Cannot be changed)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
