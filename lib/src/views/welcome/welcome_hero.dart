import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bus_illustration.dart';
import 'welcome_common.dart';

/// Bloque 2 — Banner de bienvenida dividido en dos columnas.
///
/// Izquierda: distintivo rosado, titular y texto. Derecha: ilustración del bus
/// escolar con estudiantes. En pantallas estrechas las columnas se apilan.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key, required this.onVerRutas, required this.onSolicitar});

  final VoidCallback onVerRutas;
  final VoidCallback onSolicitar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WelcomeSection(
      espaciadoSuperior: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          // Dos columnas a partir de 860 px; por debajo se apilan.
          final dosColumnas = ancho >= 860;

          final ilustracion = BusIllustration(
            scene: BusScene.estudiantes,
            // La imagen acompaña la altura del texto cuando hay dos columnas.
            height: dosColumnas ? 210 : (ancho >= 560 ? 180 : 150),
            borderRadius: 14,
          );

          return Container(
            padding: EdgeInsets.all(dosColumnas ? 20 : 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: dosColumnas
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _textos(onVerRutas, onSolicitar, compacto: false, isDark: isDark)),
                      const SizedBox(width: 22),
                      Expanded(flex: 4, child: ilustracion),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _textos(onVerRutas, onSolicitar, compacto: true, isDark: isDark),
                      const SizedBox(height: 14),
                      ilustracion,
                    ],
                  ),
          );
        },
      ),
    );
  }

  /// Columna de texto: distintivo + titular + descripción + acciones.
  Widget _textos(VoidCallback onVerRutas, VoidCallback onSolicitar, {required bool compacto, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const WelcomeBadge(
          texto: 'Bienvenido',
          icon: Icons.star_rounded,
          color: AppColors.rosado,
        ),
        const SizedBox(height: 12),
        Text(
          '¡Bienvenidos al transporte escolar Maranata!',
          style: TextStyle(
            fontSize: compacto ? 21 : 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.18,
            color: isDark ? Colors.white : AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Servicio seguro, puntual y monitorizado para acompañar a nuestros '
          'estudiantes en cada recorrido.',
          style: TextStyle(fontSize: 13.5, height: 1.5, color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            WelcomeButton(
              texto: 'Ver rutas',
              icon: Icons.map_rounded,
              color: AppColors.navy,
              onPressed: onVerRutas,
            ),
            WelcomeButton(
              texto: 'Solicitar transporte',
              icon: Icons.mail_outline_rounded,
              color: AppColors.crimson,
              onPressed: onSolicitar,
            ),
          ],
        ),
      ],
    );
  }
}
