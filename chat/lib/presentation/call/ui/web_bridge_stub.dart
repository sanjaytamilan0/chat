/// This is the mobile/desktop version of the bridge.
/// It always returns true because we don't need to check for external JS scripts on native platforms.
Future<bool> checkIrisExists() async {
  return true;
}
