import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AppFeedback {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.surfaceLight,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<bool> confirmDeleteFavorites(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar todos los favoritos?'),
        content: const Text(
          'Esta acción quitará todos los canales guardados en este dispositivo. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Borrar todos'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
