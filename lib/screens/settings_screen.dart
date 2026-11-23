import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/accent_theme.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/seasonal_theme.dart';
import '../models/playlist.dart';
import '../services/vpn_service.dart';
import '../state/app_state.dart';
import '../widgets/add_playlist_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _devIdController;
  late final TextEditingController _userIdController;
  late final TextEditingController _m3uUrlController;
  late final TextEditingController _vodUrlController;
  bool _isInitialized = false;
  bool _isTesting = false;
  bool _isLoadingM3u = false;
  bool _isLoadingVod = false;
  String? _loadingSuggestionUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final state = AppScope.of(context);
      _devIdController = TextEditingController(text: state.devId);
      _userIdController = TextEditingController(text: state.userId);
      _m3uUrlController = TextEditingController(text: state.customM3uUrl);
      _vodUrlController = TextEditingController(text: state.customVodUrl);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _devIdController.dispose();
    _userIdController.dispose();
    _m3uUrlController.dispose();
    _vodUrlController.dispose();
    super.dispose();
  }

  String _generateRandomDevId() {
    final rand = Random();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _testConnection() async {
    final state = AppScope.of(context);
    setState(() => _isTesting = true);

    final clusterRes = await state.testClusterHandshake(
      devId: _devIdController.text.trim(),
      userId: _userIdController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isTesting = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.neonGreen, size: 24),
            SizedBox(width: 10),
            Text(
              'Diagnóstico de Cluster Wiwy',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resultados del handshake en los 4 nodos extraídos del APK:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: clusterRes.entries.map((entry) {
                      final host = entry.key;
                      final data = entry.value;
                      final code = data['statusCode'] ?? 0;
                      final isOk = code == 200;
                      final body = data['body'] != null
                          ? (data['body'] is Map || data['body'] is List
                              ? const JsonEncoder.withIndent('  ').convert(data['body'])
                              : data['body'].toString())
                          : (data['error'] ?? 'Sin respuesta');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOk ? AppColors.neonGreen.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOk ? Icons.check_circle : Icons.error_outline,
                                  size: 16,
                                  color: isOk ? AppColors.neonGreen : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    host,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isOk ? AppColors.neonGreen : AppColors.error).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'HTTP $code',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOk ? AppColors.neonGreen : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              body,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nota técnica: El mensaje "版本已停止使用" confirma respuesta activa del protocolo Wiwy en el nodo.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Ajustes',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // --- SECCIÓN: IDENTIDAD DEL DISPOSITIVO (AUDITORÍA WIWY) ---
        _buildSectionHeader('Identidad del Dispositivo (dev_id & user_id)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configura los identificadores de hardware y usuario que se envían en las cabeceras HTTP hacia el portal WiwyXuper.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Campo dev_id
                const Text(
                  'Device ID (dev_id - Hash MD5 de Hardware):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _devIdController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: 'Ej: 1798e621bbde68b9cf944375d862af41',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.shuffle, size: 20),
                      tooltip: 'Generar dev_id aleatorio de 32 caracteres',
                      onPressed: () {
                        final newId = _generateRandomDevId();
                        setState(() => _devIdController.text = newId);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copiar al portapapeles',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _devIdController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device ID copiado al portapapeles.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Campo user_id
                const Text(
                  'User ID (user_id - Cuenta de usuario):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _userIdController,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Ej: 978939558',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botones de acción
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Guardar Identidad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        await state.updateDeviceIdentity(
                          devId: _devIdController.text.trim(),
                          userId: _userIdController.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Identidad guardada en almacenamiento persistente.'),
                            ),
                          );
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check, size: 16),
                      label: const Text('Probar Handshake en Vivo'),
                      onPressed: _isTesting ? null : _testConnection,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restablecer Original'),
                      onPressed: () async {
                        await state.resetDeviceIdentity();
                        setState(() {
                          _devIdController.text = state.devId;
                          _userIdController.text = state.userId;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Valores restablecidos por defecto.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN: GESTOR DE MÚLTIPLES LISTAS ---
        _buildSectionHeader('Gestor de Múltiples Listas (Live TV & VOD)'),
        _buildPlaylistManagerCard(context, state, accent),
        const SizedBox(height: 24),

        // --- SECCIÓN: FUENTE DE CONTENIDO & LISTA IPTV ---
        _buildSectionHeader('Fuente de contenido y Lista IPTV'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usar portal WiwyXuper'),
                  subtitle: const Text(
                    'Activa canales y renueva credenciales desde el equipo, sin emulador ni pasos manuales.',
                  ),
                  activeThumbColor: accent,
                  value: state.useWiwy,
                  onChanged: (val) => state.setUseWiwy(val),
                ),
                const Divider(height: 24, color: AppColors.border),

                const Text(
                  'Lista de Reproducción IPTV (M3U / M3U8):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingresa el enlace de tu lista remota (proveedor IPTV, enlace M3U Plus o archivo web). Dejar en blanco para usar la lista abierta por defecto.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _m3uUrlController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: 'https://ejemplo.com/lista.m3u o get.php?...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.paste, size: 20),
                      tooltip: 'Pegar del portapapeles',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          setState(() => _m3uUrlController.text = data.text!.trim());
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Limpiar campo',
                      onPressed: () {
                        setState(() => _m3uUrlController.clear());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: _isLoadingM3u
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.cloud_download_rounded, size: 16),
                      label: Text(_isLoadingM3u ? 'Cargando lista...' : 'Guardar y Cargar Lista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isLoadingM3u
                          ? null
                          : () async {
                              final url = _m3uUrlController.text.trim();
                              if (url.isNotEmpty &&
                                  !url.startsWith('http://') &&
                                  !url.startsWith('https://')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('La URL debe comenzar con http:// o https://'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoadingM3u = true);
                              try {
                                final count = await state.setCustomM3uPlaylist(url);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        url.isEmpty
                                            ? 'Lista restablecida a canales por defecto ($count canales).'
                                            : '¡Lista IPTV cargada con éxito! ($count canales importados)',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cargar la lista M3U: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoadingM3u = false);
                              }
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restablecer IPTV-Org'),
                      onPressed: _isLoadingM3u
                          ? null
                          : () async {
                              setState(() {
                                _m3uUrlController.clear();
                                _isLoadingM3u = true;
                              });
                              try {
                                await state.resetCustomM3uPlaylist();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Se ha restablecido la lista pública (${state.channels.length} canales).',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al restablecer: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoadingM3u = false);
                              }
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar Canales'),
                      onPressed: _isLoadingM3u
                          ? null
                          : () async {
                              setState(() => _isLoadingM3u = true);
                              await state.loadChannels(forceRefresh: true);
                              if (mounted) setState(() => _isLoadingM3u = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Catálogo actualizado (${state.channels.length} canales disponibles).'),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
                if (state.customM3uUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.neonGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lista activa: ${state.customM3uUrl} (${state.channels.length} canales)',
                          style: const TextStyle(fontSize: 12, color: AppColors.neonGreen),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN: CATÁLOGO VOD (PELÍCULAS & SERIES) ---
        _buildSectionHeader('Catálogo VOD (Películas y Series)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lista de Películas y Series (M3U / Bit.ly / URL):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingresa el enlace de tu lista VOD (soporta enlaces directos, listas bit.ly, archivos .m3u con películas, series y carátulas).',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _vodUrlController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: 'http://bit.ly/FilmesdeTerror1 o url vod...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.paste, size: 20),
                      tooltip: 'Pegar del portapapeles',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          setState(() => _vodUrlController.text = data.text!.trim());
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Limpiar campo',
                      onPressed: () {
                        setState(() => _vodUrlController.clear());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: _isLoadingVod
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.movie_filter_rounded, size: 16),
                      label: Text(_isLoadingVod ? 'Cargando catálogo...' : 'Guardar y Cargar VOD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isLoadingVod
                          ? null
                          : () async {
                              final url = _vodUrlController.text.trim();
                              if (url.isNotEmpty &&
                                  !url.startsWith('http://') &&
                                  !url.startsWith('https://')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('La URL debe comenzar con http:// o https://'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoadingVod = true);
                              try {
                                final count = await state.setCustomVodPlaylist(url);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        url.isEmpty
                                            ? 'Catálogo VOD restablecido al contenido por defecto.'
                                            : '¡Catálogo VOD cargado con éxito! ($count títulos importados)',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cargar catálogo VOD: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoadingVod = false);
                              }
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restablecer Catálogo Original'),
                      onPressed: _isLoadingVod
                          ? null
                          : () async {
                              setState(() {
                                _vodUrlController.clear();
                                _isLoadingVod = true;
                              });
                              try {
                                await state.resetCustomVodPlaylist();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Se ha restablecido el catálogo VOD demostrativo original.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al restablecer: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoadingVod = false);
                              }
                            },
                    ),
                  ],
                ),
                if (state.customVodUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.neonGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Catálogo VOD activo: ${state.customVodUrl}',
                          style: const TextStyle(fontSize: 12, color: AppColors.neonGreen),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN: VPN & TÚNEL ---
        _buildSectionHeader('Túnel OpenVPN y Red'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (state.vpnStatus == VpnStatus.connected ? AppColors.neonGreen : accent).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        state.vpnStatus == VpnStatus.connected ? Icons.vpn_lock : Icons.vpn_key_outlined,
                        color: state.vpnStatus == VpnStatus.connected ? AppColors.neonGreen : accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Servidor: ${state.vpnService.currentServer}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.vpnStatus == VpnStatus.connected
                                ? 'Túnel seguro activo (cifrado OpenVPN 443)'
                                : (state.vpnStatus == VpnStatus.connecting
                                    ? 'Estableciendo túnel OpenVPN...'
                                    : 'Desconectado - Tráfico directo'),
                            style: TextStyle(
                              fontSize: 12,
                              color: state.vpnStatus == VpnStatus.connected
                                  ? AppColors.neonGreen
                                  : (state.vpnStatus == VpnStatus.connecting ? AppColors.warning : AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => state.toggleVpn(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.vpnStatus == VpnStatus.connected ? AppColors.error : accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        state.vpnStatus == VpnStatus.connected ? 'Desconectar' : 'Conectar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                const Text(
                  'Perfil de Servidor OpenVPN (SoftEther):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Auto-Failover (Recomendado)', style: TextStyle(fontSize: 11)),
                      selected: state.vpnService.selectedProfile == VpnProfile.auto,
                      selectedColor: accent.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        if (selected) state.setVpnProfile(VpnProfile.auto);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Servidor 194 (default.ovpn :443)', style: TextStyle(fontSize: 11)),
                      selected: state.vpnService.selectedProfile == VpnProfile.primary194,
                      selectedColor: accent.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        if (selected) state.setVpnProfile(VpnProfile.primary194);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Servidor 206 (vpnok.ovpn :443)', style: TextStyle(fontSize: 11)),
                      selected: state.vpnService.selectedProfile == VpnProfile.backup206,
                      selectedColor: accent.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        if (selected) state.setVpnProfile(VpnProfile.backup206);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Los perfiles OpenVPN SoftEther (public-vpn-194 y public-vpn-206 en puerto 443 TCP) permiten evadir bloqueos de proveedores ISP en transmisiones en vivo.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN: PERSONALIZACIÓN ---
        _buildSectionHeader('Personalización'),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de Color de Énfasis
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Color de Énfasis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AccentTheme.options.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final opt = AccentTheme.options[index];
                    final isSelected = opt.name == state.accent.name;

                    return GestureDetector(
                      onTap: () => state.setAccent(opt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? opt.color.withValues(alpha: 0.2) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? opt.color : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              opt.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? opt.color : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 16, color: AppColors.border),

              // Selector de Fondo de Pantalla (Temas de temporada)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Fondo de Pantalla / Temporada',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SeasonalTheme.themes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final t = SeasonalTheme.themes[index];
                    final isSelected = t.id == state.currentTheme.id;

                    return ChoiceChip(
                      label: Text(t.label),
                      selected: isSelected,
                      selectedColor: accent.withValues(alpha: 0.25),
                      onSelected: (_) => state.setWallpaper(t),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN: ACERCA DE ---
        _buildSectionHeader('Acerca de NexusStream'),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NexusStream v1.0.0 (Build 16)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  'NexusStream es un reproductor IPTV multiplataforma construido con Flutter. La lista de canales abiertos proviene del proyecto abierto IPTV-Org.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPlaylistManagerCard(BuildContext context, AppState state, Color accent) {
    final playlists = state.savedPlaylists;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.playlist_play_rounded, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listas de Reproducción Guardadas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Guarda tus listas de Live TV y VOD y cámbialas cuando desees.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => AddPlaylistDialog.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir Lista', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            if (playlists.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textMuted, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No tienes listas adicionales guardadas. Pulsa "Añadir Lista" para ingresar tu enlace M3U/VOD, o agrega una de las listas verificadas de abajo.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final pl = playlists[index];
                  final isActive = pl.isActive;
                  final isTv = pl.type == PlaylistType.tv;

                  return Container(
                    decoration: BoxDecoration(
                      color: isActive ? accent.withValues(alpha: 0.1) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? accent : AppColors.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isTv ? AppColors.neonGreen : Colors.purpleAccent).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isTv ? Icons.live_tv_rounded : Icons.movie_filter_rounded,
                          color: isTv ? AppColors.neonGreen : Colors.purpleAccent,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              pl.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isTv ? AppColors.neonGreen : Colors.purpleAccent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTv ? 'LIVE TV' : 'VOD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isTv ? AppColors.neonGreen : Colors.purpleAccent,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            pl.url,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pl.itemCount} ${isTv ? "canales" : "títulos"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? accent : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isActive)
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                await state.activatePlaylist(pl.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lista "${pl.name}" activada.')),
                                  );
                                }
                              },
                              child: const Text('Activar', style: TextStyle(fontSize: 11)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                            tooltip: 'Refrescar contenido',
                            onPressed: () async {
                              final count = await state.refreshPlaylist(pl.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lista "${pl.name}" actualizada ($count elementos).')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            tooltip: 'Eliminar lista',
                            onPressed: () async {
                              await state.deletePlaylist(pl.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lista "${pl.name}" eliminada.')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Sugerencias verificadas para añadir con 1 clic
            const Text(
              'Listas recomendadas y verificadas (1 clic para añadir a tus listas):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionButton(
                  context,
                  state,
                  accent,
                  name: 'Live Canales Global (2,020)',
                  url: 'http://bit.ly/2D8ZHyz',
                  type: PlaylistType.tv,
                  icon: Icons.tv,
                ),
                _buildSuggestionButton(
                  context,
                  state,
                  accent,
                  name: 'Películas Terror (396 VOD)',
                  url: 'http://bit.ly/FilmesdeTerror1',
                  type: PlaylistType.vod,
                  icon: Icons.movie,
                ),
                _buildSuggestionButton(
                  context,
                  state,
                  accent,
                  name: 'CR Filmes VOD',
                  url: 'http://bit.ly/CR-FILMES',
                  type: PlaylistType.vod,
                  icon: Icons.video_library,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionButton(
    BuildContext context,
    AppState state,
    Color accent, {
    required String name,
    required String url,
    required PlaylistType type,
    required IconData icon,
  }) {
    final alreadyAdded = state.savedPlaylists.any((p) => p.url == url);
    final isLoadingThis = _loadingSuggestionUrl == url;

    return ActionChip(
      avatar: isLoadingThis
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              alreadyAdded ? Icons.check_circle : icon,
              size: 14,
              color: alreadyAdded ? AppColors.neonGreen : accent,
            ),
      label: Text(
        alreadyAdded ? '$name (Agregada)' : '+ $name',
        style: TextStyle(
          fontSize: 11,
          fontWeight: alreadyAdded ? FontWeight.bold : FontWeight.normal,
          color: alreadyAdded ? AppColors.neonGreen : AppColors.textPrimary,
        ),
      ),
      onPressed: alreadyAdded || isLoadingThis
          ? null
          : () async {
              setState(() => _loadingSuggestionUrl = url);
              try {
                final count = await state.addPlaylist(
                  name: name,
                  url: url,
                  type: type,
                  activate: false,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡Lista "$name" agregada ($count ${type == PlaylistType.tv ? "canales" : "títulos"})!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al agregar lista: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _loadingSuggestionUrl = null);
              }
            },
    );
  }
}
