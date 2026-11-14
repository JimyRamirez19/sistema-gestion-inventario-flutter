import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/app_colors.dart';

/// Pantalla definitiva de inicio de sesión de Inventario Pro.
/// Integra la identidad visual corporativa (degradados en Slate, acentos en Teal),
/// validación de formulario, botón para alternar visibilidad de contraseña y manejo
/// reactivo del estado de autenticación mediante [AuthController].
class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({super.key, required this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    // Cerrar teclado
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      await widget.authController.iniciarSesion(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedBuilder(
                animation: widget.authController,
                builder: (context, _) {
                  final auth = widget.authController;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner Superior con Identidad Visual (Slate Gradient)
                      _buildHeaderBanner(),
                      const SizedBox(height: 24),

                      // Tarjeta de Formulario
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.cardBorder, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Ingreso de Usuario',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ingrese sus credenciales registradas para autenticarse con JWT.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Alerta de error si las credenciales fallan
                                if (auth.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: const TextStyle(
                                              color: Color(0xFF991B1B),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => auth.limpiarError(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Campo de Correo Electrónico
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    hintText: 'ej. admin@inventario.com',
                                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El correo electrónico es obligatorio';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Ingrese un formato de correo válido (ej. usuario@dominio.com)';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) {
                                    if (auth.errorMessage != null) auth.limpiarError();
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo de Contraseña con alternancia Mostrar/Ocultar
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La contraseña es obligatoria';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) {
                                    if (auth.errorMessage != null) auth.limpiarError();
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Botón de Inicio de Sesión
                                ElevatedButton(
                                  onPressed: auth.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Iniciar Sesión',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pie de página con información de seguridad
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 14, color: AppColors.accent),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Autenticación Segura mediante JWT y FastAPI',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ELECTIVA PROFESIONAL I • PARCIAL II',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.lock_person_outlined, color: AppColors.accentLight, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.inventory_2, color: AppColors.accentLight, size: 26),
              SizedBox(width: 10),
              Text(
                'Inventario Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistema de Gestión Comercial con Autenticación JWT',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
