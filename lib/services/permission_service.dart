import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PermissionService {
  static Future<void> requestLocationPermission() async {
    if (kIsWeb) return; // Permission handler status not implemented on web
    
    final status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      await Permission.locationWhenInUse.request();
    }
  }

  static Future<bool> hasLocationPermission() async {
    if (kIsWeb) return true; // Assume true or handle differently on web
    return await Permission.locationWhenInUse.isGranted;
  }
}
