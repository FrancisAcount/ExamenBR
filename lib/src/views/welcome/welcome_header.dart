import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'welcome_common.dart';

/// Bloque 1 — Header compacto con buscador y botón «Ver rutas».
///
/// El buscador filtra en tiempo real las rutas de la sección 5, por eso la
/// consulta se propaga hacia arriba mediante [onQueryChanged].
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onVerRutas,
    required this.onIniciarSesion,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onVerRutas;
  final VoidCallback onIniciarSesion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.surface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < WelcomeBreakpoints.compacto;
              // El ancho necesario para mantener título + buscador + acciones.
              final unaFila = constraints.maxWidth >= 940;

              final titulo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Colegio Maranata',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Servicio de transporte escolar',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              );

              final buscador = _BuscadorCompacto(
                controller: controller,
                onChanged: onQueryChanged,
                onVerRutas: onVerRutas,
              );

              // Botón de acceso al panel de gestión. En móvil se muestra solo
              // el icono para no romper el ancho del buscador.
              // El `Tooltip` mantiene el acceso identificable cuando el móvil
              // oculta la etiqueta y solo muestra el icono.
              final botonSesion = Tooltip(
                message: 'Iniciar Sesión',
                child: OutlinedButton.icon(
                  onPressed: onIniciarSesion,
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: compacto ? const SizedBox.shrink() : const Text('Iniciar Sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.navy,
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    padding: EdgeInsets.symmetric(
                      horizontal: compacto ? 13 : 14,
                      vertical: 13,
                    ),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              );

              final acciones = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WelcomeButton(
                    texto: 'Ver rutas',
                    icon: Icons.map_rounded,
                    color: AppColors.crimson,
                    onPressed: onVerRutas,
                  ),
                  const SizedBox(width: 8),
                  botonSesion,
                ],
              );
              if (unaFila) {
                // No puede ser `const`: `buscador` y `acciones` son widgets de
                // runtime (el buscador es controlado).
                return Row(
                  children: [
                    Expanded(child: titulo),
                    const SizedBox(width: 16),
                    SizedBox(width: 300, child: buscador),
                    const SizedBox(width: 10),
                    acciones,
                  ],
                );
              }

              // En móvil el buscador ocupa el ancho completo y las acciones bajan.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titulo,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: buscador),
                      const SizedBox(width: 10),
                      acciones,
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Campo de búsqueda con la lupa integrada en un cuadro azul.
class _BuscadorCompacto extends StatelessWidget {
  const _BuscadorCompacto({
    required this.controller,
    required this.onChanged,
    required this.onVerRutas,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onVerRutas;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => onVerRutas(),
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 13.5, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar ruta, paradero...',
          hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(5),
            child: Material(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: onVerRutas,
                borderRadius: BorderRadius.circular(9),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(Icons.search_rounded, size: 19, color: Colors.white),
                ),
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 34),
          filled: true,
          fillColor: isDark ? AppColors.darkInputFill : AppColors.background,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.guindo, width: 1.4),
          ),
        ),
      ),
    );
  }
}
