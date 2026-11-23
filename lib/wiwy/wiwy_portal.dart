import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network_defaults.dart';
import '../services/storage_service.dart';

class WiwySession {
  final String devId;
  final String userId;
  final String authToken;
  final String license;
  final DateTime expiresAt;

  WiwySession({
    required this.devId,
    required this.userId,
    required this.authToken,
    required this.license,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class WiwyException implements Exception {
  final String message;
  final int? statusCode;

  WiwyException(this.message, {this.statusCode});

  @override
  String toString() => 'WiwyException: $message (code: $statusCode)';
}

/// Cliente de comunicación con el backend WiwyXuper (infraestructura Magis TV / Tele Latino).
/// Implementado para análisis de seguridad y auditoría de protocolos.
class WiwyPortal {
  final StorageService? _storage;
  final http.Client _client;
  WiwySession? _currentSession;
  String? _activeHost;

  WiwyPortal({StorageService? storage, http.Client? client})
      : _storage = storage,
        _client = client ?? http.Client();

  WiwySession? get currentSession => _currentSession;
  String get activeHost => _activeHost ?? NetworkDefaults.wiwyPortalHost;

  String get devId => _storage?.getDevId() ?? NetworkDefaults.hardcodedDeviceSeed;
  String get defaultUserId => _storage?.getUserId() ?? '978939558';

  void resetSession() {
    _currentSession = null;
    _activeHost = null;
  }

  Map<String, String> _buildHeaders({String? token, String? license}) {
    return {
      'User-Agent': NetworkDefaults.rangerUserAgent,
      'App': NetworkDefaults.msAndroidApp,
      'App-Version': NetworkDefaults.msAndroidVersion,
      'Content-Type': 'application/json; charset=utf-8',
      'dev_id': devId,
      if (token != null) 'Content-Auth': token,
      if (license != null) 'Content-License': license,
    };
  }

  /// Prueba diagnóstica del handshake /api/portalCore/v8/active contra un host específico o el principal
  Future<Map<String, dynamic>> testHandshake({String? customDevId, String? customUserId, String? host}) async {
    final effectiveDevId = customDevId ?? devId;
    final effectiveHost = host ?? activeHost;
    final url = Uri.parse('$effectiveHost/api/portalCore/v8/active');
    final payload = jsonEncode({
      'dev_id': effectiveDevId,
      'portalCode': 'portal200001',
      'sysVersion': '16',
      'app_version': NetworkDefaults.msAndroidVersion,
    });

    try {
      final response = await _client.post(
        url,
        headers: {
          'User-Agent': NetworkDefaults.rangerUserAgent,
          'App': NetworkDefaults.msAndroidApp,
          'App-Version': NetworkDefaults.msAndroidVersion,
          'Content-Type': 'application/json; charset=utf-8',
          'dev_id': effectiveDevId,
        },
        body: payload,
      ).timeout(NetworkDefaults.connectTimeout);

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }

      return {
        'host': effectiveHost,
        'statusCode': response.statusCode,
        'body': decoded,
        'devId': effectiveDevId,
      };
    } catch (e) {
      return {
        'host': effectiveHost,
        'statusCode': 0,
        'error': e.toString(),
        'devId': effectiveDevId,
      };
    }
  }

  /// Diagnóstico completo de todos los nodos del cluster extraídos
  Future<Map<String, Map<String, dynamic>>> testClusterHandshake({String? customDevId, String? customUserId}) async {
    final results = <String, Map<String, dynamic>>{};
    final effectiveDevId = customDevId ?? devId;

    final futures = NetworkDefaults.wiwyClusterHosts.map((host) async {
      final res = await testHandshake(
        customDevId: effectiveDevId,
        customUserId: customUserId,
        host: host,
      );
      results[host] = res;
    });

    await Future.wait(futures);
    return results;
  }

  /// Paso 1: Handshake de activación con failover en el cluster
  Future<WiwySession> activate() async {
    final currentDevId = devId;
    final payload = jsonEncode({
      'dev_id': currentDevId,
      'portalCode': 'portal200001',
      'sysVersion': '16',
      'app_version': NetworkDefaults.msAndroidVersion,
    });

    WiwyException? lastError;

    // Probar nodos del cluster en orden de prioridad
    for (final host in NetworkDefaults.wiwyClusterHosts) {
      try {
        final url = Uri.parse('$host/api/portalCore/v8/active');
        final response = await _client.post(
          url,
          headers: _buildHeaders(),
          body: payload,
        ).timeout(NetworkDefaults.connectTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (data['returnCode'] == 'portal200001' && data['errorMessage'] != null) {
            lastError = WiwyException(
              '${data["errorMessage"]} ($host)',
              statusCode: 200,
            );
            continue;
          }

          final userId = data['userId']?.toString() ?? defaultUserId;
          final token = data['token']?.toString() ?? '';
          final license = data['license']?.toString() ?? '';

          _activeHost = host;
          _currentSession = WiwySession(
            devId: currentDevId,
            userId: userId,
            authToken: token,
            license: license,
            expiresAt: DateTime.now().add(const Duration(hours: 4)),
          );

          return _currentSession!;
        } else {
          lastError = WiwyException(
            'El portal $host rechazó la activación (${response.statusCode})',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        lastError = WiwyException('Error de conexión con $host: $e');
      }
    }

    throw lastError ?? WiwyException('Ningún nodo del cluster Wiwy respondió con éxito');
  }

  /// Paso 2: Obtener catálogo de canales en vivo contra /api/portalCore/v6/getLiveData con failover
  Future<List<Map<String, dynamic>>> getLiveData() async {
    if (_currentSession == null || _currentSession!.isExpired) {
      await activate();
    }

    final targetHosts = [
      activeHost,
      ...NetworkDefaults.wiwyClusterHosts.where((h) => h != activeHost),
    ];

    WiwyException? lastError;

    for (final host in targetHosts) {
      final url = Uri.parse('$host/api/portalCore/v6/getLiveData');
      try {
        final response = await _client.post(
          url,
          headers: _buildHeaders(
            token: _currentSession?.authToken,
            license: _currentSession?.license,
          ),
          body: jsonEncode({
            'userId': _currentSession?.userId ?? defaultUserId,
            'dev_id': devId,
          }),
        ).timeout(NetworkDefaults.receiveTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List items = body['data'] ?? [];
          _activeHost = host;
          return items.cast<Map<String, dynamic>>();
        } else {
          lastError = WiwyException('No se pudo cargar el catálogo de canales desde $host (${response.statusCode})');
        }
      } catch (e) {
        lastError = WiwyException('Error al solicitar canales en vivo desde $host: $e');
      }
    }

    throw lastError ?? WiwyException('Error al consultar canales en vivo en el cluster');
  }
}
