import 'dart:js' as js;

/// This is the web-specific version of the bridge.
/// It uses dart:js to check the browser's global scope.
Future<bool> checkIrisExists() async {
  try {
    return js.context.hasProperty('IrisVideo') || js.context.hasProperty('createIrisApiEngine') || js.context.hasProperty('AgoraRTC');
  } catch (e) {
    return false;
  }
}
