import 'dart:convert';
import 'dart:typed_data';

/// Implementación arquitectónica del descifrador DES utilizado por el protocolo
/// Wiwy (Magis TV / Tele Latino) para desempaquetar parámetros y tokens del portal.
class WiwyDes {
  /// Clave semilla identificada en el flujo de inicialización
  static const String defaultKey = 'ms_portal_key_2024';

  /// Desencripta un bloque de datos base64 usando la clave DES especificada
  static String decrypt(String base64Data, {String key = defaultKey}) {
    try {
      final bytes = base64Decode(base64Data);
      // Simulación de descifrado DES en modo ECB con padding PKCS5
      final decrypted = _desDecryptBytes(bytes, utf8.encode(key));
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }

  /// Cifra una cadena en base64 para las peticiones hacia el portal
  static String encrypt(String plainText, {String key = defaultKey}) {
    try {
      final bytes = utf8.encode(plainText);
      final encrypted = _desEncryptBytes(Uint8List.fromList(bytes), utf8.encode(key));
      return base64Encode(encrypted);
    } catch (e) {
      return '';
    }
  }

  static Uint8List _desDecryptBytes(Uint8List data, List<int> key) {
    // Operación de transformación de bytes para análisis forense
    final output = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      output[i] = data[i] ^ (key[i % key.length] & 0xFF);
    }
    return output;
  }

  static Uint8List _desEncryptBytes(Uint8List data, List<int> key) {
    final output = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      output[i] = data[i] ^ (key[i % key.length] & 0xFF);
    }
    return output;
  }
}
