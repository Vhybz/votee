import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/voter_provider.dart';
import '../../services/election_provider.dart';
import '../../models/election_models.dart';
import '../../services/ip_service.dart';
import '../../services/permission_service.dart';
import 'dart:math' as math;
import 'dart:async';

class IndexVerificationScreen extends ConsumerStatefulWidget {
  const IndexVerificationScreen({super.key});

  @override
  ConsumerState<IndexVerificationScreen> createState() => _IndexVerificationScreenState();
}

class _IndexVerificationScreenState extends ConsumerState<IndexVerificationScreen> with TickerProviderStateMixin {
  final _indexController = TextEditingController();
  late AnimationController _avatarController;
  final List<Offset> _avatarPositions = [];
  final math.Random _random = math.Random();
  bool _isBlacklisted = false;
  bool _isCheckingIp = true;
  Timer? _countdownTimer;
  Duration _timeUntilStart = Duration.zero;
  String? _currentIp;
  static final Set<String> _uniqueIdsVerified = {};
  final Map<String, Color> _positionColors = {};

  @override
  void initState() {
    super.initState();
    _checkIpStatus();
    _startCountdownTimer();
    PermissionService.requestLocationPermission();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    for (int i = 0; i < 50; i++) {
      _avatarPositions.add(Offset(
        _random.nextDouble(),
        _random.nextDouble(),
      ));
    }
  }

  Future<void> _checkIpStatus() async {
    try {
      final ipService = IpService();
      final ip = await ipService.getCurrentIp();
      _currentIp = ip;
      if (ip != null) {
        final isBlacklisted = await ipService.isIpBlacklisted(ip);
        if (mounted) {
          setState(() {
            _isBlacklisted = isBlacklisted;
            _isCheckingIp = false;
          });
        }
      } else {
        if (mounted) setState(() => _isCheckingIp = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingIp = false);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final settings = ref.read(electionSettingsProvider).value;
      if (settings != null && settings.startTime != null) {
        final now = DateTime.now();
        if (now.isBefore(settings.startTime!)) {
          if (mounted) {
            setState(() {
              _timeUntilStart = settings.startTime!.difference(now);
            });
          }
        } else {
          // If the time has passed, we might want to refresh the UI to show the voting form
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _avatarController.dispose();
    _indexController.dispose();
    super.dispose();
  }

  void _handleVerification(String index) async {
    if (index.isEmpty) return;

    final student = await ref.read(voterProvider.notifier).verifyIndex(index);
    if (student != null) {
      // Security Logic: Check for credential stuffing
      _uniqueIdsVerified.add(index);
      if (_uniqueIdsVerified.length > 3) {
        ref.read(electionServiceProvider).reportAnomaly(
          title: 'Possible Credential Stuffing',
          details: 'Device at $_currentIp has attempted to verify ${_uniqueIdsVerified.length} unique index numbers. Latest: $index',
          severity: AnomalySeverity.high,
          ipAddress: _currentIp,
        );
      }

      if (student.hasVoted) {
        if (mounted) {
          _showAlreadyVotedDialog(student);
        }
        return;
      }
      if (mounted) {
        Navigator.pushNamed(
          context, 
          '/voter/confirm',
          arguments: {'student': student},
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Index number not found.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final candidatesAsync = ref.watch(candidatesProvider);
    final candidates = candidatesAsync.value ?? [];
    final settingsAsync = ref.watch(electionSettingsProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final positions = positionsAsync.value ?? [];
    
    final isElectionActive = settingsAsync.value?.isActive ?? false;

    // Build the list of floating items
    final List<Map<String, dynamic>> floatingItems = [];
    
    // Group candidates by position for connecting threads
    final Map<String, List<int>> candidateGroups = {};

    if (candidates.isNotEmpty) {
      for (var i = 0; i < candidates.length; i++) {
        final c = candidates[i];
        final posId = c.positionId;
        
        // Ensure consistent color for each position
        _positionColors.putIfAbsent(posId, () => Colors.primaries[math.Random(posId.hashCode).nextInt(Colors.primaries.length)]);
        
        candidateGroups.putIfAbsent(posId, () => []);
        candidateGroups[posId]!.add(floatingItems.length);
        
        floatingItems.add({'candidate': c, 'isBgi': false});
      }
    }
    
    // Add background visuals
    final bgiCount = size.width < 600 ? 10 : 20;
    final List<String> backgroundImages = [
      'assets/images/bgi/img.png',
      'assets/images/bgi/img_1.png',
      'assets/images/bgi/vote1.jpg',
    ];
    
    for (int i = 0; i < bgiCount; i++) {
      floatingItems.add({
        'path': backgroundImages[i % backgroundImages.length],
        'isBgi': true
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _avatarController,
        builder: (context, _) {
          final isElectionActive = settingsAsync.value?.isActive ?? false;

          // Calculate all positions for this frame
          final List<Offset> currentOffsets = [];
          for (int i = 0; i < floatingItems.length; i++) {
            currentOffsets.add(_calculateAvatarOffset(i, size));
          }

          return Stack(
            children: [
              // 1. Connecting threads (Dashed lines) for candidate groups
              if (isElectionActive)
                CustomPaint(
                  size: size,
                  painter: _ConnectionPainter(
                    groups: candidateGroups,
                    offsets: currentOffsets,
                    colors: _positionColors,
                    candidates: candidates,
                  ),
                ),

              // 2. The Avatars themselves
              ...List.generate(
                floatingItems.length,
                (index) {
                  final item = floatingItems[index];
                  final offset = currentOffsets[index];
                  final candidate = item['isBgi'] ? null : item['candidate'] as Candidate;
                  final Color? categoryColor = candidate != null ? _positionColors[candidate.positionId] : null;

                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: _buildAvatarWidget(
                      size, 
                      candidate, 
                      positions, 
                      item['isBgi'] ? item['path'] : null,
                      categoryColor,
                    ),
                  );
                }
              ),

              // 3. UI Layer (the forms, messages, etc)
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Top spacing to "bring it down a bit"
                      const SizedBox(height: 60), 
                      if (_isCheckingIp)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(100.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_isBlacklisted)
                        _buildClosedBanner('ACCESS DENIED', 'Your device IP address has been restricted from participating in this election due to security policy violations.', 'RavenVote')
                      else
                        settingsAsync.when(
                          data: (settings) {
                            final now = DateTime.now();
                            final isScheduledButNotStarted = settings.startTime != null && now.isBefore(settings.startTime!);
                            final isEnded = settings.endTime != null && now.isAfter(settings.endTime!);
                            
                            String displayTitle = settings.electionTitle;
                            if (displayTitle.contains('UENR')) displayTitle = 'RavenVote';

                            if (!settings.isActive || isScheduledButNotStarted || isEnded) {
                              String title = 'VOTING DISABLED';
                              String message = 'The election is currently not active. Please check back later or contact your administrator.';
                              Widget? extra;

                              if (isScheduledButNotStarted) {
                                title = 'POLLS NOT OPEN';
                                message = 'Voting is scheduled to start on ${DateFormat('MMMM dd, yyyy • hh:mm a').format(settings.startTime!)}';
                                extra = _buildCountdownDisplay();
                              } else if (isEnded) {
                                title = 'POLLS CLOSED';
                                message = 'The voting period for this election has ended.';
                                extra = _buildResultsSummary(positions, candidates);
                              }

                              return _buildClosedBanner(title, message, displayTitle, extra: extra);
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeader(displayTitle),
                                const SizedBox(height: 32),
                                _buildVerificationForm(),
                              ],
                            );
                          },
                          loading: () => const Center(child: Padding(
                            padding: EdgeInsets.all(100.0),
                            child: CircularProgressIndicator(),
                          )),
                          error: (e, s) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader('RavenVote'),
                              const SizedBox(height: 32),
                              _buildVerificationForm(),
                            ],
                          ),
                        ),
                      const SizedBox(height: 60), // Balanced bottom spacing
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _calculateAvatarOffset(int index, Size size) {
    final double t = _avatarController.value;
    final double phaseX = index * 0.7;
    final double phaseY = index * 1.3;
    final double speed = 1.0 + (index % 5) * 0.2;
    
    final double movementX = 0.3 * math.sin(2 * math.pi * t * speed + phaseX);
    final double movementY = 0.3 * math.cos(2 * math.pi * t * speed + phaseY);
    
    double x = (_avatarPositions[index % _avatarPositions.length].dx + movementX) * size.width;
    double y = (_avatarPositions[index % _avatarPositions.length].dy + movementY) * size.height;
    
    x = x % (size.width + 100) - 50;
    y = y % (size.height + 100) - 50;
    
    return Offset(x, y);
  }

  Widget _buildAvatarWidget(Size size, Candidate? candidate, List<Position> positions, String? bgiPath, Color? categoryColor) {
    final theme = Theme.of(context);
    final position = candidate != null ? positions.firstWhere((p) => p.id == candidate.positionId, orElse: () => Position(id: '', title: '')) : null;
    final String defaultBgi = bgiPath ?? 'assets/images/bgi/img.png';
    final avatarSize = candidate != null ? (size.width < 600 ? 120.0 : 180.0) : (size.width < 600 ? 90.0 : 130.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: categoryColor != null ? Border.all(color: categoryColor.withValues(alpha: 0.6), width: 2) : null,
            boxShadow: candidate != null ? [
              BoxShadow(
                color: (categoryColor ?? Colors.black).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ] : null,
          ),
          child: ClipOval(
            child: candidate != null && candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty
                ? Image.network(
                    candidate.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(defaultBgi, fit: BoxFit.cover),
                  )
                : Image.asset(
                    defaultBgi,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (candidate != null && position != null && position.title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              position.title,
              style: const TextStyle(
                fontSize: 9, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(String title) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    
    return Column(
      children: [
        Center(
          child: Tooltip(
            message: 'Admin Access',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onLongPress: () => Navigator.pushNamed(context, '/admin/login'),
                child: CircleAvatar(
                  radius: isMobile ? 30 : 36,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'RavenVote',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: theme.colorScheme.primary,
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: theme.brightness == Brightness.dark ? Colors.white70 : AppColors.textLight,
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'by TechRaven LTD',
          style: GoogleFonts.inter(
            color: theme.brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildClosedBanner(String title, String message, String electionTitle, {Widget? extra}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: EdgeInsets.symmetric(vertical: isMobile ? 20 : 40),
        padding: EdgeInsets.all(isMobile ? AppSpacing.l : AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildElectionInfo(electionTitle),
            const SizedBox(height: 24),
            // Pulsing Lock Icon for "Live Security" feel
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.lock_clock_rounded, 
                    color: (title == 'POLLS CLOSED' ? Colors.orange : Colors.redAccent).withValues(alpha: (value - 0.2).clamp(0.0, 1.0)), 
                    size: 44
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 24 : 28, 
                fontWeight: FontWeight.bold, 
                color: title == 'POLLS CLOSED' ? Colors.orange : Colors.redAccent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 40,
              color: (title == 'POLLS CLOSED' ? Colors.orange : Colors.redAccent).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 16, 
                color: isDark ? Colors.white70 : AppColors.textLight,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (extra != null) ...[
              const SizedBox(height: 32),
              extra,
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionInfo(String title) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCountdownItem(_timeUntilStart.inDays, 'DAYS'),
          _buildCountdownItem(_timeUntilStart.inHours % 24, 'HRS'),
          _buildCountdownItem(_timeUntilStart.inMinutes % 60, 'MINS'),
          _buildCountdownItem(_timeUntilStart.inSeconds % 60, 'SECS'),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSummary(List<Position> positions, List<Candidate> candidates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'ELECTION RESULTS',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.orange,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            _buildTurnoutBadge(),
          ],
        ),
        const SizedBox(height: 16),
        ...positions.take(4).map((pos) {
          final posCandidates = candidates.where((c) => c.positionId == pos.id).toList();
          if (posCandidates.isEmpty) return const SizedBox();
          
          final winner = posCandidates.reduce((a, b) => a.voteCount >= b.voteCount ? a : b);
          final totalVotes = posCandidates.fold(0, (sum, c) => sum + c.voteCount);
          final percentage = totalVotes > 0 ? (winner.voteCount / totalVotes) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: (winner.imageUrl != null && winner.imageUrl!.isNotEmpty)
                      ? NetworkImage(winner.imageUrl!)
                      : null,
                  child: (winner.imageUrl == null || winner.imageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pos.title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(winner.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(percentage * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                    Text('${winner.voteCount} votes', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          );
        }),
        if (positions.length > 4)
          Center(
            child: Text(
              '+ ${positions.length - 4} more positions',
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildTurnoutBadge() {
    return Consumer(
      builder: (context, ref, child) {
        final stats = ref.watch(electionStatsProvider).value;
        if (stats == null) return const SizedBox();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${stats.turnoutPercentage.toStringAsFixed(1)}% TURNOUT',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        );
      },
    );
  }

  Widget _buildVerificationForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Cast Your Vote',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your unique Index Number to begin the verification process.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : AppColors.textLight,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 16 : 24)),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Column(
                children: [
                  TextField(
                    controller: _indexController,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Index Number',
                      hintText: 'e.g., 20000000',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleVerification(_indexController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'VERIFY IDENTITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 16,
                        ),
                      ),
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

  void _showAlreadyVotedDialog(Student student) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');
    final votedAt = student.votedAt?.toLocal() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Already Voted',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our records indicate that a ballot has already been cast using this index number.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Voter Name', student.fullName),
            _buildDetailRow('Date', dateFormat.format(votedAt)),
            _buildDetailRow('Time', timeFormat.format(votedAt)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you believe this is an error, please contact the electoral commission immediately.',
                      style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Icon(Icons.security, color: theme.brightness == Brightness.dark ? Colors.white38 : AppColors.textLight, size: 24),
          const SizedBox(height: 8),
          Text(
            'Secure Multi-Factor Authentication Active',
            style: TextStyle(
              color: theme.brightness == Brightness.dark ? Colors.white38 : AppColors.textLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Powered by TechRaven LTD',
            style: TextStyle(
              color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  final Map<String, List<int>> groups;
  final List<Offset> offsets;
  final Map<String, Color> colors;
  final List<Candidate> candidates;

  _ConnectionPainter({
    required this.groups,
    required this.offsets,
    required this.colors,
    required this.candidates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isMobile = size.width < 600;
    final double avatarRadius = isMobile ? 60.0 : 90.0;

    for (var entry in groups.entries) {
      final color = colors[entry.key] ?? Colors.white;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final indices = entry.value;
      if (indices.length < 2) continue;

      for (int i = 0; i < indices.length; i++) {
        final p1 = offsets[indices[i]] + Offset(avatarRadius, avatarRadius);
        final p2 = offsets[indices[(i + 1) % indices.length]] + Offset(avatarRadius, avatarRadius);

        _drawDashedLine(canvas, p1, p2, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 10;
    const double dashSpace = 10;
    
    double distance = (p2 - p1).distance;
    if (distance == 0) return;
    
    double dx = (p2.dx - p1.dx) / distance;
    double dy = (p2.dy - p1.dy) / distance;
    
    double currentDistance = 0;
    while (currentDistance < distance) {
      canvas.drawLine(
        Offset(p1.dx + dx * currentDistance, p1.dy + dy * currentDistance),
        Offset(p1.dx + dx * math.min(currentDistance + dashWidth, distance), p1.dy + dy * math.min(currentDistance + dashWidth, distance)),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) => true;
}
