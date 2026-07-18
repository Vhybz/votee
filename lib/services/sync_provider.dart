import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'election_provider.dart';
import 'offline_sync_service.dart';

class SyncNotifier extends StateNotifier<DateTime> with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;
  bool _isSyncing = false;

  SyncNotifier(this.ref) : super(DateTime.now()) {
    WidgetsBinding.instance.addObserver(this);
    _startSyncTimer();
    _syncAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAll();
    }
  }

  void _startSyncTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncAll();
    });
  }

  Future<void> _syncAll() async {
    if (!mounted || _isSyncing) return;

    try {
      _isSyncing = true;
      
      // Process offline queue first
      await OfflineSyncService.processQueue();
      
      // Refresh key data sets
      await Future.wait([
        ref.refresh(positionsProvider.future),
        ref.refresh(candidatesProvider.future),
      ]);

      if (mounted) {
        state = DateTime.now(); 
      }
    } catch (e) {
      // Silently ignore sync errors in UI-only mode
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, DateTime>((ref) {
  return SyncNotifier(ref);
});
