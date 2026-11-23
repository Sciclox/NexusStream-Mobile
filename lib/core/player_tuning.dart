import 'network_defaults.dart';

class PlayerTuning {
  static const String browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  /// Encabezados HTTP limpios para la solicitud de stream
  static Map<String, String> getHttpHeaders({String? source}) {
    if (source == 'wiwy') {
      return {
        'User-Agent': NetworkDefaults.rangerUserAgent,
      };
    }
    return {
      'User-Agent': browserUserAgent,
    };
  }

  /// Opciones de configuración de bajo nivel para MPV / media_kit
  /// identificadas en libapp.so de NexusStream
  static Map<String, String> getMpvOptions({bool enableHardwareDecoding = true}) {
    return {
      'demuxer-max-bytes': '33554432',       // 32MB de buffer máximo
      'demuxer-max-back-bytes': '16777216',  // 16MB de back buffer
      'demuxer-readahead-secs': '20',        // 20 segundos de readahead
      'demuxer-cache-time': '15',
      'stream-buffer-size': '2097152',       // 2MB buffer inicial
      'network-timeout': '10',
      'cache-pause': 'yes',
      'cache-pause-wait': '2',
      'cache-pause-initial': 'yes',
      'hwdec': enableHardwareDecoding ? 'auto' : 'no',
      'hwdec-codecs': 'all',
      'http-user-agent': NetworkDefaults.rangerUserAgent,
      'user-agent': NetworkDefaults.rangerUserAgent,
    };
  }
}
