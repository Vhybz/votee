import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/admin_appbar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';
import '../../core/uuid_utils.dart';

class VoterManagementScreen extends ConsumerStatefulWidget {
  const VoterManagementScreen({super.key});

  @override
  ConsumerState<VoterManagementScreen> createState() => _VoterManagementScreenState();
}

class _VoterManagementScreenState extends ConsumerState<VoterManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isImporting = false;
  String _searchQuery = '';

  final List<String> _schools = ['Science', 'Engineering', 'Agriculture', 'Arts', 'Natural Resources'];
  final List<String> _programs = ['Computer Science', 'Information Technology', 'Mechanical Engineering', 'Electrical Engineering', 'Agriculture', 'Natural Resources'];
  final List<String> _levels = ['100', '200', '300', '400', '500', '600'];
  final List<String> _classes = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleBulkImport(Map<String, String> contextData) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() => _isImporting = true);
      try {
        final files = result.files;
        if (files.isEmpty) throw 'No file selected.';
        
        final file = files.first;
        Uint8List? bytes = file.bytes;
        
        if (bytes == null && file.path != null) {
          bytes = File(file.path!).readAsBytesSync();
        }

        if (bytes == null || bytes.isEmpty) {
          throw 'Could not read file data. The file might be empty or inaccessible.';
        }

        var excel = Excel.decodeBytes(bytes);
        List<Map<String, dynamic>> studentsToImport = [];
        
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;
          
          var rows = sheet.rows;
          if (rows.isEmpty) continue;
          
          // Start from index 1 to skip header row
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;
            
            // Extremely safe cell access
            String getVal(int idx) {
              if (idx >= row.length) return '';
              final cell = row[idx];
              if (cell == null || cell.value == null) return '';
              return cell.value.toString().trim();
            }

            final fullName = getVal(0);
            final indexNumber = getVal(1);
            // Column D is index 3 in the user's spreadsheet
            final phoneNumber = getVal(3).isEmpty ? getVal(2) : getVal(3);
            
            if (indexNumber.isEmpty) continue;
            
            const otp = '12345'; 

            studentsToImport.add({
              'id': UuidUtils.generate(),
              'full_name': fullName.isEmpty ? 'Unknown Student' : fullName,
              'index_number': indexNumber,
              'level': contextData['level'] ?? '100',
              'class_name': contextData['class'] ?? 'A',
              'phone_number': phoneNumber,
              'otp': otp,
              'academic_school': contextData['school'] ?? 'General',
              'program': contextData['program'] ?? 'General',
              'has_voted': false,
            });
          }
        }

        if (studentsToImport.isNotEmpty) {
          await ref.read(electionServiceProvider).bulkImportStudents(studentsToImport);
          ref.invalidate(votersListProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported ${studentsToImport.length} voters successfully'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw 'No valid student records found in the Excel file.';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import Failed: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _showImportSettingsDialog() async {
    String? selectedSchool = _schools.first;
    String? selectedProgram = _programs.first;
    String? selectedLevel = _levels.first;
    String? selectedClass = _classes.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text('Batch Configuration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Configure common attributes for the students in your Excel file.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              _buildDropdownField('Academic School', selectedSchool, _schools, (v) => setDialogState(() => selectedSchool = v)),
              _buildDropdownField('Program', selectedProgram, _programs, (v) => setDialogState(() => selectedProgram = v)),
              _buildDropdownField('Level', selectedLevel, _levels, (v) => setDialogState(() => selectedLevel = v)),
              _buildDropdownField('Class/Group', selectedClass, _classes, (v) => setDialogState(() => selectedClass = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'school': selectedSchool ?? _schools.first,
                'program': selectedProgram ?? _programs.first,
                'level': selectedLevel ?? _levels.first,
                'class': selectedClass ?? _classes.first,
              }),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('PICK EXCEL FILE'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _handleBulkImport(result);
    }
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        isDense: true,
        decoration: InputDecoration(
          labelText: label, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showManualRegistrationDialog() async {
    final nameController = TextEditingController();
    final indexController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedSchool = _schools.first;
    String? selectedProgram = _programs.first;
    String? selectedLevel = _levels.first;
    String? selectedClass = _classes.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text('Voter Registration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormTextField(nameController, 'Full Name', Icons.person_outline, [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))]),
                const SizedBox(height: 16),
                _buildFormTextField(indexController, 'Index Number', Icons.badge_outlined, [FilteringTextInputFormatter.deny(RegExp(r'\s'))]),
                const SizedBox(height: 16),
                _buildFormTextField(phoneController, 'Phone Number', Icons.phone_outlined, [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 24),
                _buildDropdownField('Academic School', selectedSchool, _schools, (v) => setDialogState(() => selectedSchool = v)),
                _buildDropdownField('Program', selectedProgram, _programs, (v) => setDialogState(() => selectedProgram = v)),
                _buildDropdownField('Level', selectedLevel, _levels, (v) => setDialogState(() => selectedLevel = v)),
                _buildDropdownField('Class/Group', selectedClass, _classes, (v) => setDialogState(() => selectedClass = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || indexController.text.isEmpty) return;
                
                final studentData = {
                  'id': UuidUtils.generate(),
                  'full_name': nameController.text.trim(),
                  'index_number': indexController.text.trim(),
                  'level': selectedLevel,
                  'class_name': selectedClass,
                  'phone_number': phoneController.text.trim(),
                  'otp': '12345',
                  'academic_school': selectedSchool,
                  'program': selectedProgram,
                  'has_voted': false,
                };

                await ref.read(electionServiceProvider).registerStudent(studentData);
                ref.invalidate(votersListProvider);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('REGISTER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextField(TextEditingController controller, String label, IconData icon, List<TextInputFormatter> formatters) {
    return TextField(
      controller: controller,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = ref.watch(menuItemsProvider);
    final user = ref.watch(currentUserProvider);
    final votersAsync = ref.watch(votersListProvider);
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
          title: 'Voter Registry',
          user: user,
        ),
        drawer: !isDesktop ? Drawer(
          width: size.width * 0.66,
          child: AppSidebar(
            items: menuItems,
            currentRoute: '/admin/voters',
            onTap: (route) => MenuService.navigate(context, route, '/admin/voters'),
            isDrawer: true,
          ),
        ) : null,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  items: menuItems,
                  currentRoute: '/admin/voters',
                  onTap: (route) => MenuService.navigate(context, route, '/admin/voters'),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 32),
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      Expanded(
                        child: votersAsync.when(
                          data: (voters) => _buildHierarchicalVoterList(theme, voters),
                          loading: () => Skeletonizer(
                            enabled: true,
                            child: _buildHierarchicalVoterList(theme, _fakeVoters),
                          ),
                          error: (err, stack) => Center(child: Text('Error: $err')),
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

  final List<Student> _fakeVoters = List.generate(10, (index) => Student(
    id: 'fake-$index',
    fullName: 'Sample Student Name',
    indexNumber: '12345678',
    level: '100',
    className: 'A',
    phoneNumber: '0240000000',
    academicSchool: 'Science',
    program: 'Computer Science',
    otp: '12345',
    hasVoted: false,
  ));

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
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
              'Student Database',
              style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            Text(
              'Hierarchical view of all registered voters',
              style: GoogleFonts.inter(color: isDark ? Colors.white38 : AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _showImportSettingsDialog,
              icon: _isImporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.cloud_upload_outlined, color: isDark ? Colors.white : theme.colorScheme.primary, size: 18),
              label: Text('BULK IMPORT', style: TextStyle(color: isDark ? Colors.white : theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                side: BorderSide(color: isDark ? Colors.white10 : theme.colorScheme.primary.withValues(alpha: 0.2)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showManualRegistrationDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: const Text('ENROLL VOTER', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
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

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by Name, Index, Program or Level...',
          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildHierarchicalVoterList(ThemeData theme, List<Student> allVoters) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    final filteredVoters = allVoters.where((s) {
      return s.fullName.toLowerCase().contains(_searchQuery) ||
             s.indexNumber.toLowerCase().contains(_searchQuery) ||
             s.academicSchool.toLowerCase().contains(_searchQuery) ||
             s.program.toLowerCase().contains(_searchQuery) ||
             s.level.toLowerCase().contains(_searchQuery) ||
             s.className.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredVoters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text('No voters found matching your search.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    Map<String, Map<String, Map<String, Map<String, List<Student>>>>> hierarchy = {};

    for (var student in filteredVoters) {
      hierarchy.putIfAbsent(student.academicSchool, () => {});
      hierarchy[student.academicSchool]!.putIfAbsent(student.program, () => {});
      hierarchy[student.academicSchool]![student.program]!.putIfAbsent(student.level, () => {});
      hierarchy[student.academicSchool]![student.program]![student.level]!.putIfAbsent(student.className, () => []);
      hierarchy[student.academicSchool]![student.program]![student.level]![student.className]!.add(student);
    }

    return ListView(
      children: hierarchy.entries.map((schoolEntry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            initiallyExpanded: _searchQuery.isNotEmpty,
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Icon(Icons.account_balance_rounded, color: isDark ? Colors.white38 : primaryColor, size: 20),
            title: Text(schoolEntry.key, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${_countStudents(schoolEntry.value)} Students', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 11)),
            children: schoolEntry.value.entries.map((programEntry) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ExpansionTile(
                  initiallyExpanded: _searchQuery.isNotEmpty,
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  leading: const Icon(Icons.school_outlined, size: 18),
                  title: Text(programEntry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  children: programEntry.value.entries.map((levelEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ExpansionTile(
                        initiallyExpanded: _searchQuery.isNotEmpty,
                        leading: const Icon(Icons.layers_outlined, size: 16),
                        title: Text('Level ${levelEntry.key}', style: const TextStyle(fontSize: 13)),
                        children: levelEntry.value.entries.map((classEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ExpansionTile(
                              initiallyExpanded: _searchQuery.isNotEmpty,
                              leading: const Icon(Icons.class_outlined, size: 14),
                              title: Text('Group ${classEntry.key}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              children: classEntry.value.map((student) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.1),
                                    child: Icon(Icons.person, color: isDark ? Colors.white38 : primaryColor, size: 14),
                                  ),
                                  title: Text(student.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('ID: ${student.indexNumber}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusChip(student.hasVoted),
                                      IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note_rounded, size: 18), visualDensity: VisualDensity.compact),
                                      IconButton(
                                        onPressed: () => _handleDeleteStudent(student), 
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), 
                                        visualDensity: VisualDensity.compact
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleDeleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Remove ${student.fullName} (${student.indexNumber}) from the registry?'),
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
      await ref.read(electionServiceProvider).deleteStudent(student.id);
      ref.invalidate(votersListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.fullName} has been removed.'))
        );
      }
    }
  }

  int _countStudents(Map<String, Map<String, Map<String, List<Student>>>> schoolData) {
    int count = 0;
    for (var program in schoolData.values) {
      for (var level in program.values) {
        for (var className in level.values) {
          count += className.length;
        }
      }
    }
    return count;
  }

  Widget _buildStatusChip(bool hasVoted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasVoted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        hasVoted ? 'VOTED' : 'PENDING',
        style: TextStyle(
          color: hasVoted ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
