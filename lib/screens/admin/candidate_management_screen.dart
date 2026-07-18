import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/election_provider.dart';
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
    final positionsAsync = ref.watch(positionsProvider);
    final candidatesAsync = ref.watch(candidatesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          AppSidebar(
            items: menuItems,
            currentRoute: '/admin/candidates',
            onTap: (route) => MenuService.navigate(context, route, '/admin/candidates'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 32),
                  positionsAsync.when(
                    data: (positions) {
                      final candidates = candidatesAsync.value ?? [];
                      return Expanded(
                        child: ListView.builder(
                          itemCount: positions.length,
                          itemBuilder: (context, index) {
                            final pos = positions[index];
                            final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
                            return _buildPositionSection(theme, pos, posCandidates);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final electionTitle = ref.watch(electionTitleProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Candidate Registry',
                    style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined, size: 20),
                    onPressed: _showEditElectionTitleDialog,
                    tooltip: 'Edit Election Title',
                  ),
                ],
              ),
              Text(
                'Current Election: $electionTitle',
                style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _showAddPositionDialog,
              icon: Icon(Icons.add_business_outlined, color: isDark ? Colors.white : primaryColor),
              label: Text('NEW POSITION', style: TextStyle(color: isDark ? Colors.white : primaryColor)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                side: BorderSide(color: isDark ? Colors.white24 : primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showAddCandidateDialog,
              icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
              label: const Text('ADD CANDIDATE', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditElectionTitleDialog() async {
    final controller = TextEditingController(text: ref.read(electionTitleProvider));
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Election Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Election of Course Rep for IT Level 100 D',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(electionTitleProvider.notifier).state = controller.text.trim();
                Navigator.pop(context);
              }
            },
            child: const Text('UPDATE TITLE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPositionDialog() async {
    final titleController = TextEditingController();
    final maxSelectionsController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Position Title (e.g., SRC President)', border: OutlineInputBorder()),
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
            child: const Text('ADD POSITION'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCandidateDialog() async {
    final nameController = TextEditingController();
    final sloganController = TextEditingController();
    final imageController = TextEditingController();
    
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
          title: const Text('Add Candidate/Aspirant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPositionId,
                  decoration: const InputDecoration(labelText: 'Aspiring Position', border: OutlineInputBorder()),
                  items: positions.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPositionId = v),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: sloganController, decoration: const InputDecoration(labelText: 'Slogan', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedPositionId == null) return;
                final candidate = Candidate(
                  id: UuidUtils.generate(),
                  fullName: nameController.text.trim(),
                  positionId: selectedPositionId!,
                  slogan: sloganController.text.trim(),
                  imageUrl: imageController.text.trim(),
                );
                await ref.read(electionServiceProvider).addCandidate(candidate);
                ref.invalidate(candidatesProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ADD CANDIDATE'),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(
                position.title.toUpperCase(),
                style: GoogleFonts.oswald(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Divider()),
              const SizedBox(width: 16),
              Text(
                '${position.maxSelections} Max Selection(s)',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textLight),
              ),
            ],
          ),
        ),
        candidates.isEmpty 
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No candidates registered for this position.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: (isDark ? Colors.white : AppColors.borderGray).withValues(alpha: 0.1),
                          backgroundImage: (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty) 
                            ? NetworkImage(candidate.imageUrl!) 
                            : null,
                          child: (candidate.imageUrl == null || candidate.imageUrl!.isEmpty)
                            ? Icon(Icons.person, color: isDark ? Colors.white70 : AppColors.textLight)
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
                              Text(
                                candidate.slogan,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textLight, fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}
