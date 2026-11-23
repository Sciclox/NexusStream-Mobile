import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/network_defaults.dart';
import '../models/playlist.dart';

class AddPlaylistDialog extends StatefulWidget {
  final PlaylistType initialType;

  const AddPlaylistDialog({
    super.key,
    this.initialType = PlaylistType.tv,
  });

  static Future<bool?> show(BuildContext context, {PlaylistType initialType = PlaylistType.tv}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddPlaylistDialog(initialType: initialType),
    );
  }

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  late PlaylistType _selectedType;
  bool _activateImmediately = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _applySuggestion({required String name, required String url, required PlaylistType type}) {
    setState(() {
      _nameController.text = name;
      _urlController.text = url;
      _selectedType = type;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa la URL de la lista.');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _errorMessage = 'La URL debe comenzar con http:// o https://');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final state = AppScope.of(context);
    try {
      final count = await state.addPlaylist(
        name: name.isEmpty ? (_selectedType == PlaylistType.tv ? 'Lista IPTV' : 'Catálogo VOD') : name,
        url: url,
        type: _selectedType,
        activate: _activateImmediately,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Lista agregada con éxito! Se importaron $count ${_selectedType == PlaylistType.tv ? "canales" : "títulos"}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo leer la lista. Verifica que el enlace esté activo y sea accesible.\nError: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y Tipo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedType == PlaylistType.tv ? Icons.live_tv_rounded : Icons.movie_filter_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añadir Lista de Reproducción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Soporta listas M3U, M3U8, enlaces directos y redirecciones',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Selector de Tipo (TV vs VOD)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => setState(() => _selectedType = PlaylistType.tv),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == PlaylistType.tv ? accent.withValues(alpha: 0.2) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedType == PlaylistType.tv ? accent : AppColors.border,
                            width: _selectedType == PlaylistType.tv ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tv,
                              size: 18,
                              color: _selectedType == PlaylistType.tv ? accent : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Canales en Vivo (TV)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedType == PlaylistType.tv ? accent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => setState(() => _selectedType = PlaylistType.vod),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == PlaylistType.vod ? accent.withValues(alpha: 0.2) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedType == PlaylistType.vod ? accent : AppColors.border,
                            width: _selectedType == PlaylistType.vod ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_creation_outlined,
                              size: 18,
                              color: _selectedType == PlaylistType.vod ? accent : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Películas y Series (VOD)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedType == PlaylistType.vod ? accent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre de la Lista
              const Text(
                'Nombre o Etiqueta:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                  controller: _nameController,
                  enabled: !_isLoading,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: _selectedType == PlaylistType.tv ? 'Ej: Canales Latinos, Deportes HD' : 'Ej: Películas de Terror, Series 2024',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // URL de la Lista
              const Text(
                'URL de la Lista M3U / VOD:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                        controller: _urlController,
                        enabled: !_isLoading,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          hintText: 'http://... o https://...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.paste, size: 20),
                    tooltip: 'Pegar del portapapeles',
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              setState(() => _urlController.text = data.text!.trim());
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sugerencias rápidas verificadas
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentBlue),
                  const SizedBox(width: 6),
                  Text(
                    'Listas recomendadas ${_selectedType == PlaylistType.tv ? "TV" : "VOD"} (clic para cargar):',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: NetworkDefaults.curatedPresets
                    .where((p) => _selectedType == PlaylistType.vod ? p.isVod : !p.isVod)
                    .map((preset) {
                  return ActionChip(
                    avatar: Icon(
                      preset.isVod ? Icons.movie_outlined : Icons.live_tv_outlined,
                      size: 14,
                      color: preset.isVerified ? AppColors.accentBlue : AppColors.textMuted,
                    ),
                    label: Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: preset.isVerified ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: preset.isVerified ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: preset.isVerified
                        ? AppColors.accentBlue.withValues(alpha: 0.1)
                        : AppColors.surfaceLight,
                    side: BorderSide(
                      color: preset.isVerified
                          ? AppColors.accentBlue.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                    tooltip: '${preset.description}\nURL: ${preset.url}',
                    onPressed: _isLoading
                        ? null
                        : () => _applySuggestion(
                              name: preset.name,
                              url: preset.url,
                              type: preset.isVod ? PlaylistType.vod : PlaylistType.tv,
                            ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Checkbox activar
              Row(
                children: [
                  Checkbox(
                    value: _activateImmediately,
                    activeColor: accent,
                    onChanged: _isLoading ? null : (val) => setState(() => _activateImmediately = val ?? true),
                  ),
                  const Text(
                    'Activar inmediatamente al guardar',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isLoading ? 'Verificando y Descargando...' : 'Guardar Lista'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
