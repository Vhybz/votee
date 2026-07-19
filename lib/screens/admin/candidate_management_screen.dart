import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/election_provider.dart';
import '../../services/user_provider.dart';
import '../../models/election_models.dart';
import '../../core/uuid_utils.dart';

class CandidateManagementScreen extends ConsumerStatefulWidget {
  const CandidateManagementScreen({super.key});

  @override
  ConsumerState<CandidateManagementScreen> createState() => _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends ConsumerState<CandidateManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);
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
          title: 'Candidate Registry',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.5,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/candidates',
            onTap: (route) => MenuService.navigate(context, route, '/admin/candidates'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/candidates',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/candidates'),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 32),
                      Skeletonizer(
                        enabled: positionsAsync.isLoading,
                        child: positionsAsync.when(
                          data: (positions) {
                            final isLoading = positionsAsync.isLoading;
                            final effectivePositions = positions.isEmpty && isLoading ? _fakePositions : positions;
                            final candidates = candidatesAsync.value ?? (isLoading ? _fakeCandidates : []);
                            
                            if (effectivePositions.isEmpty && !isLoading) {
                              return _buildEmptyState(isDesktop);
                            }
                            return Expanded(
                              child: ListView.builder(
                                itemCount: effectivePositions.length,
                                itemBuilder: (context, index) {
                                  final pos = effectivePositions[index];
                                  final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
                                  return _buildPositionSection(theme, pos, posCandidates);
                                },
                              ),
                            );
                          },
                          loading: () => Expanded(
                            child: ListView.builder(
                              itemCount: _fakePositions.length,
                              itemBuilder: (context, index) {
                                final pos = _fakePositions[index];
                                final posCandidates = _fakeCandidates.where((c) => c.positionId == pos.id).toList();
                                return _buildPositionSection(theme, pos, posCandidates);
                              },
                            ),
                          ),
                          error: (e, _) => Center(child: Text('Error: $e')),
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

  static final List<Position> _fakePositions = [
    Position(id: 'p1', title: 'Sample Position Title', order: 0),
  ];

  static final List<Candidate> _fakeCandidates = [
    Candidate(id: 'c1', fullName: 'Sample Candidate Name', positionId: 'p1', slogan: 'This is a sample slogan for the candidate.'),
    Candidate(id: 'c2', fullName: 'Sample Candidate Name 2', positionId: 'p1', slogan: 'This is another sample slogan.'),
  ];

  Widget _buildEmptyState(bool isDesktop) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text('No electoral positions defined yet.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddPositionDialog,
              child: const Text('CREATE FIRST POSITION'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final settingsAsync = ref.watch(electionSettingsProvider);
    final electionTitle = settingsAsync.value?.electionTitle ?? 'RavenVote';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aspirants Registry',
              style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            Text(
              'Current Election: $electionTitle',
              style: GoogleFonts.inter(color: isDark ? Colors.white38 : AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => _handleDeleteAllCandidates(),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
              label: const Text('PURGE ALL', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                side: const BorderSide(color: Colors.redAccent, width: 1),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showAddPositionDialog,
              icon: Icon(Icons.add_business_rounded, color: isDark ? Colors.white : primaryColor, size: 18),
              label: Text('NEW POSITION', style: TextStyle(color: isDark ? Colors.white : primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                side: BorderSide(color: isDark ? Colors.white10 : primaryColor.withValues(alpha: 0.2)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddCandidateDialog,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              label: const Text('ADD ASPIRANT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddPositionDialog() async {
    final titleController = TextEditingController();
    final maxSelectionsController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('New Electoral Position', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title (e.g., SRC President)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxSelectionsController,
              decoration: const InputDecoration(labelText: 'Max Selections', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final position = Position(
                id: UuidUtils.generate(),
                title: titleController.text.trim(),
                maxSelections: int.tryParse(maxSelectionsController.text) ?? 1,
              );
              await ref.read(electionServiceProvider).addPosition(position);
              ref.invalidate(positionsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCandidateDialog() async {
    final nameController = TextEditingController();
    final sloganController = TextEditingController();
    XFile? pickedImage;
    Uint8List? imageBytes;
    
    final positions = ref.read(positionsProvider).value ?? [];
    if (positions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a position first.')));
      return;
    }

    String? selectedPositionId = positions.first.id;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text('Enroll Aspirant', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPositionId,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Target Position', 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: positions.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPositionId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController, 
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(controller: sloganController, decoration: const InputDecoration(labelText: 'Campaign Slogan', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                
                // Image Picker Section
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setDialogState(() {
                        pickedImage = image;
                        imageBytes = bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('Tap to select portrait', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedPositionId == null) return;
                
                final candidateId = UuidUtils.generate();
                String? imageUrl;
                
                if (imageBytes != null) {
                  imageUrl = await ref.read(electionServiceProvider).uploadCandidateImage(
                    candidateId, 
                    imageBytes!,
                    ext: pickedImage!.name.split('.').last,
                  );
                }

                final candidate = Candidate(
                  id: candidateId,
                  fullName: nameController.text.trim(),
                  positionId: selectedPositionId!,
                  slogan: sloganController.text.trim(),
                  imageUrl: imageUrl,
                );
                await ref.read(electionServiceProvider).addCandidate(candidate);
                ref.invalidate(candidatesProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ENROLL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionSection(ThemeData theme, Position position, List<Candidate> candidates) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  position.title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white38 : primaryColor,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _handleDeletePosition(position),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                tooltip: 'Delete Position',
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 16),
              const Expanded(child: Divider()),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${position.maxSelections} SELECT',
                  style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        candidates.isEmpty 
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: const Center(child: Text('No aspirants registered for this position.', style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 800 ? 1 : (MediaQuery.of(context).size.width < 1400 ? 2 : 3),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 3.2,
              ),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return _buildCandidateCard(candidate, isDark, primaryColor);
              },
            ),
      ],
    );
  }

  Widget _buildCandidateCard(Candidate candidate, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.zero,
              image: (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty) 
                ? DecorationImage(image: NetworkImage(candidate.imageUrl!), fit: BoxFit.cover) 
                : null,
            ),
            child: (candidate.imageUrl == null || candidate.imageUrl!.isEmpty)
              ? Icon(Icons.person_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 36)
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  candidate.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.slogan,
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCandidateDialog(candidate);
              } else if (value == 'delete') {
                _handleDeleteCandidate(candidate);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete Aspirant', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCandidateDialog(Candidate candidate) async {
    final nameController = TextEditingController(text: candidate.fullName);
    final sloganController = TextEditingController(text: candidate.slogan);
    XFile? pickedImage;
    Uint8List? imageBytes;
    
    final positions = ref.read(positionsProvider).value ?? [];
    String? selectedPositionId = candidate.positionId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text('Edit Aspirant', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPositionId,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Target Position', 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: positions.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPositionId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController, 
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(controller: sloganController, decoration: const InputDecoration(labelText: 'Campaign Slogan', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                
                // Image Picker Section
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setDialogState(() {
                        pickedImage = image;
                        imageBytes = bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        )
                      : (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.zero,
                            child: Image.network(candidate.imageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Tap to change portrait', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedPositionId == null) return;
                
                String? imageUrl = candidate.imageUrl;
                
                if (imageBytes != null) {
                  imageUrl = await ref.read(electionServiceProvider).uploadCandidateImage(
                    candidate.id, 
                    imageBytes!,
                    ext: pickedImage!.name.split('.').last,
                  );
                }

                final updatedCandidate = candidate.copyWith(
                  fullName: nameController.text.trim(),
                  positionId: selectedPositionId!,
                  slogan: sloganController.text.trim(),
                  imageUrl: imageUrl,
                );
                await ref.read(electionServiceProvider).updateCandidate(updatedCandidate);
                ref.invalidate(candidatesProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE CHANGES'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteCandidate(Candidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Aspirant'),
        content: Text('Are you sure you want to remove ${candidate.fullName} from the election? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(electionServiceProvider).deleteCandidate(candidate.id);
      ref.invalidate(candidatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${candidate.fullName} has been removed.'))
        );
      }
    }
  }

  Future<void> _handleDeleteAllCandidates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purge All Aspirants'),
        content: const Text('Are you sure you want to delete ALL registered aspirants permanently? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(electionServiceProvider).deleteAllCandidates();
      ref.invalidate(candidatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All aspirants have been removed.'))
        );
      }
    }
  }

  Future<void> _handleDeletePosition(Position position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Position'),
        content: Text('Delete "${position.title}" and all its aspirants? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(electionServiceProvider).deletePosition(position.id);
      ref.invalidate(positionsProvider);
      ref.invalidate(candidatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Position "${position.title}" removed.'))
        );
      }
    }
  }
}
