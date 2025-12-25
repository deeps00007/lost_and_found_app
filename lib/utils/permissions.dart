import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // Request camera and storage permissions
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (await Permission.photos.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  // Request all required permissions at once
  static Future<void> requestAllPermissions() async {
    await requestCameraPermission();
    await requestStoragePermission();
    await requestNotificationPermission();
  }
}
