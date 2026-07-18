import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class OfflineSyncService {
  static const String queueBoxName = 'sync_queue';
  static const String studentsBoxName = 'students_cache';
  static const String candidatesBoxName = 'candidates_cache';
  static const String votesBoxName = 'votes_cache';
  static const String settingsBoxName = 'app_settings';
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(queueBoxName);
      await Hive.openBox(studentsBoxName);
      await Hive.openBox(candidatesBoxName);
      await Hive.openBox(votesBoxName);
      await Hive.openBox(settingsBoxName);
      
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          processQueue();
        }
      });
      
      processQueue();
    } catch (e) {
      debugPrint('OFFLINE ENGINE WARNING: $e');
    }
  }

  static Future<void> addToQueue({
    required String actionType,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box(queueBoxName);
    final String requestId = '${DateTime.now().millisecondsSinceEpoch}_$actionType';
    
    await box.put(requestId, {
      'type': actionType,
      'payload': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    processQueue();
  }

  static Future<void> processQueue() async {
    // UI-ONLY: Disable actual syncing
    return;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}
