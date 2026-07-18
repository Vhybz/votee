import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
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

  Future<void> _showImportSettingsDialog() async {
    String? selectedSchool = _schools.first;
    String? selectedProgram = _programs.first;
    String? selectedLevel = _levels.first;
    String? selectedClass = _classes.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Import Settings', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select context for the Excel import. These will be applied to all voters in the file.'),
              const SizedBox(height: 20),
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
                'school': selectedSchool!,
                'program': selectedProgram!,
                'level': selectedLevel!,
                'class': selectedClass!,
              }),
              child: const Text('SELECT EXCEL FILE'),
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _handleBulkImport(Map<String, String> contextData) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() => _isImporting = true);
      try {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        List<Map<String, dynamic>> studentsToImport = [];
        
        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows ?? [];
          if (rows.isEmpty) continue;
          
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;
            
            final fullName = row[0]?.value?.toString() ?? '';
            final indexNumber = row[1]?.value?.toString() ?? '';
            // If row has more columns, we could use them, but contextData overrides or provides defaults
            final phoneNumber = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
            
            if (indexNumber.isEmpty) continue;
            
            final otp = (10000 + math.Random().nextInt(90000)).toString();

            studentsToImport.add({
              'id': UuidUtils.generate(),
              'full_name': fullName,
              'index_number': indexNumber,
              'level': contextData['level'],
              'class_name': contextData['class'],
              'phone_number': phoneNumber,
              'otp': otp,
              'academic_school': contextData['school'],
              'program': contextData['program'],
              'has_voted': false,
            });
          }
        }

        if (studentsToImport.isNotEmpty) {
          await ref.read(electionServiceProvider).bulkImportStudents(studentsToImport);
          ref.invalidate(votersListProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully imported ${studentsToImport.length} voters into ${contextData['program']} Level ${contextData['level']}.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing voters: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    }
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
          title: Text('Manual Voter Registration', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: indexController, decoration: const InputDecoration(labelText: 'Index Number', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                const SizedBox(height: 16),
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
                  'otp': (10000 + math.Random().nextInt(90000)).toString(),
                  'academic_school': selectedSchool,
                  'program': selectedProgram,
                  'has_voted': false,
                };

                await ref.read(electionServiceProvider).registerStudent(studentData);
                ref.invalidate(votersListProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('REGISTER VOTER'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItems = ref.watch(menuItemsProvider);
    final votersAsync = ref.watch(votersListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          AppSidebar(
            items: menuItems,
            currentRoute: '/admin/voters',
            onTap: (route) => MenuService.navigate(context, route, '/admin/voters'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voter Management',
              style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            Text(
              'Manage voters grouped by Department, Program, Level, and Class',
              style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _showImportSettingsDialog,
              icon: _isImporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.file_upload_outlined, color: isDark ? Colors.white : theme.colorScheme.primary),
              label: Text('BULK IMPORT (EXCEL)', style: TextStyle(color: isDark ? Colors.white : theme.colorScheme.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                side: BorderSide(color: isDark ? Colors.white24 : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showManualRegistrationDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('MANUAL REGISTRATION', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Search by School, Program, Level, Class, Name or Index Number...',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
            prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchicalVoterList(ThemeData theme, List<Student> allVoters) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    // 1. Filter voters based on search query
    final filteredVoters = allVoters.where((s) {
      return s.fullName.toLowerCase().contains(_searchQuery) ||
             s.indexNumber.toLowerCase().contains(_searchQuery) ||
             s.academicSchool.toLowerCase().contains(_searchQuery) ||
             s.program.toLowerCase().contains(_searchQuery) ||
             s.level.toLowerCase().contains(_searchQuery) ||
             s.className.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredVoters.isEmpty) {
      return const Center(child: Text('No voters found matching your search.'));
    }

    // 2. Group hierarchically
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            initiallyExpanded: _searchQuery.isNotEmpty,
            leading: Icon(Icons.account_balance, color: isDark ? Colors.white70 : primaryColor),
            title: Text(schoolEntry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${_countStudents(schoolEntry.value)} Students', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
            children: schoolEntry.value.entries.map((programEntry) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ExpansionTile(
                  initiallyExpanded: _searchQuery.isNotEmpty,
                  leading: const Icon(Icons.school_outlined, size: 20),
                  title: Text(programEntry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: programEntry.value.entries.map((levelEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ExpansionTile(
                        initiallyExpanded: _searchQuery.isNotEmpty,
                        leading: const Icon(Icons.layers_outlined, size: 18),
                        title: Text('Level ${levelEntry.key}'),
                        children: levelEntry.value.entries.map((classEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: ExpansionTile(
                              initiallyExpanded: _searchQuery.isNotEmpty,
                              leading: const Icon(Icons.class_outlined, size: 16),
                              title: Text('Class: ${classEntry.key}'),
                              children: classEntry.value.map((student) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.1),
                                    child: Icon(Icons.person, color: isDark ? Colors.white : primaryColor, size: 16),
                                  ),
                                  title: Text(student.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  subtitle: Text('Index: ${student.indexNumber}', style: const TextStyle(fontSize: 11)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusChip(student.hasVoted),
                                      IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18)),
                                      IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: hasVoted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        hasVoted ? 'VOTED' : 'PENDING',
        style: TextStyle(
          color: hasVoted ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
