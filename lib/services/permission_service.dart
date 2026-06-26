import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> checkStoragePermission() async {
    if (kDebugMode) {
      print('Checking storage permission');
    }
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    if (kDebugMode) {
      print('Requesting storage permission');
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> openSettings() async {
    if (kDebugMode) {
      print('Opening App Settings');
    }
    await openAppSettings();
  }
}
