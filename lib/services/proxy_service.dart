class ProxyService {
  static bool _isEnabled = false;
  static String? _proxyHost;
  static int? _proxyPort;

  static bool get isEnabled => _isEnabled;

  static void configure({required String host, required int port}) {
    _proxyHost = host;
    _proxyPort = port;
    _isEnabled = true;
  }

  static void disable() {
    _isEnabled = false;
    _proxyHost = null;
    _proxyPort = null;
  }

  static String? get proxyAddress => _isEnabled && _proxyHost != null ? '$_proxyHost:$_proxyPort' : null;
}
