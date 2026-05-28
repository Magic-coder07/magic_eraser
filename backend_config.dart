import 'dart:io';

/// Resolves the local backend address for the active platform.
///
/// Android emulator: `http://10.0.2.2:5000`
/// iOS simulator: `http://127.0.0.1:5000`
/// Physical Android devices must use the host machine LAN IP with port `:5000`.
class BackendConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.184:5000';
    }
    if (Platform.isIOS) {
      return 'http://127.0.0.1:5000';
    }
    return 'http://127.0.0.1:5000';
  }
}
