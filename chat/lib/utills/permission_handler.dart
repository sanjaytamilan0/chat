import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  /// Request all necessary permissions for the app
  static Future<void> requestAllPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Specifically request notification permission
  static Future<PermissionStatus> requestNotificationPermission() async {
    return await Permission.notification.request();
  }

  /// Specifically request camera permission
  static Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// Specifically request microphone permission
  static Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }
}
