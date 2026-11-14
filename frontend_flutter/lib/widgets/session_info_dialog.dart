import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/app_colors.dart';

/// Modal informativo con los datos del usuario autenticado y el estado seguro del JWT.
/// Cumple con el Requisito 4.6 del taller (información de sesión y logout seguro).
class SessionInfoDialog extends StatelessWidget {
  final AuthController authController;

  const SessionInfoDialog({super.key, required this.authController});

  /// Muestra el modal en el contexto provisto.
  static Future<void> show(BuildContext context, AuthController authController) {
    return showDialog(
      context: context,
      builder: (context) => SessionInfoDialog(authController: authController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = authController.usuarioActual;
    final nombre = usuario?.nombre ?? authController.nombreUsuario ?? 'Administrador';
    final email = usuario?.email ?? authController.emailUsuario ?? 'admin@inventario.com';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.accentLight, size: 24),
            SizedBox(width: 10),
            Text(
              'Información de Sesión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Avatar y datos principales
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.person,
                      size: 38,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Estado de sesión
            const Text(
              'Estado de Autenticación:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Sesión activa con JWT',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Indicador de almacenamiento seguro
            const Text(
              'Seguridad Local:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_clock_outlined, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token JWT almacenado y cifrado en almacenamiento seguro del sistema (Keystore / Keychain). Las credenciales nunca se guardan en texto plano.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: authController.isLoading
              ? null
              : () async {
                  Navigator.of(context).pop(); // Cerrar el diálogo
                  await authController.cerrarSesion();
                },
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Cerrar Sesión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

