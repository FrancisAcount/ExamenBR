import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bus_illustration.dart';
import 'welcome_common.dart';

/// Bloque 3 — Servicios: tarjeta azul ancha + dos tarjetas blancas apiladas.
///
/// Izquierda: «Tu colegio, a un viaje seguro de distancia» con la imagen del
/// bus en carretera. Derecha: dos tarjetas apiladas («Rutas» y «Turnos»).
class WelcomeServices extends StatelessWidget {
  const WelcomeServices({
    super.key,
    required this.onVerRutas,
    required this.onSolicitar,
  });

  final VoidCallback onVerRutas;
  final VoidCallback onSolicitar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WelcomeSection(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Por debajo de 980 px las tarjetas laterales bajan bajo la azul.
          final apilado = constraints.maxWidth < WelcomeBreakpoints.mediano;
          final tarjetaAzul = _TarjetaAzul(onVerRutas: onVerRutas, onSolicitar: onSolicitar, isDark: isDark);
          final laterales = _TarjetasLaterales(onVerRutas: onVerRutas, onSolicitar: onSolicitar, isDark: isDark);

          if (apilado) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tarjetaAzul, const SizedBox(height: 14), laterales],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: tarjetaAzul),
              const SizedBox(width: 14),
              Expanded(flex: 1, child: laterales),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta institucional azul (#1E3A8A) con la imagen del bus en carretera.
class _TarjetaAzul extends StatelessWidget {
  const _TarjetaAzul({required this.onVerRutas, required this.onSolicitar, required this.isDark});

  final VoidCallback onVerRutas;
  final VoidCallback onSolicitar;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const WelcomeBadge(
            texto: 'Seguro y puntual',
            icon: Icons.verified_rounded,
            color: Colors.white,
            compacto: true,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu colegio, a un viaje seguro de distancia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conduce nuestras rutas, horarios y paraderos con monitoreo en tiempo '
            'real, operación organizada y confiable.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          const BusIllustration(scene: BusScene.carretera, height: 150, borderRadius: 14),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Botón blanco: invierte los colores de la referencia sobre fondo azul.
              FilledButton.icon(
                onPressed: onVerRutas,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('Ver rutas'),
              ),
              OutlinedButton.icon(
                onPressed: onSolicitar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: const Text('Solicitar transporte'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Columna derecha: «Rutas» y «Turnos», una sobre otra.
class _TarjetasLaterales extends StatelessWidget {
  const _TarjetasLaterales({required this.onVerRutas, required this.onSolicitar, required this.isDark});

  final VoidCallback onVerRutas;
  final VoidCallback onSolicitar;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TarjetaDato(
          etiqueta: 'Rutas',
          valor: '3',
          sufijo: 'rutas',
          icono: Icons.location_on_rounded,
          colorIcono: AppColors.crimson,
          tintIcono: AppColors.rosadoLight,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _TarjetaDato(
          etiqueta: 'Turnos',
          valor: 'Mañana - Tarde',
          icono: Icons.groups_rounded,
          colorIcono: AppColors.rosado,
          tintIcono: AppColors.rosadoLight,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Tarjeta blanca con icono a la derecha y dato destacado a la izquierda.
///
/// Con [sufijo] el valor se muestra en grande y el sufijo a su lado
/// (referencia: «3 rutas»); sin él, el valor ocupa todo el ancho disponible.
class _TarjetaDato extends StatelessWidget {
  const _TarjetaDato({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.colorIcono,
    required this.tintIcono,
    this.sufijo,
    required this.isDark,
  });

  final String etiqueta;
  final String valor;
  final String? sufijo;
  final IconData icono;
  final Color colorIcono;
  final Color tintIcono;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return WelcomeCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                if (sufijo == null)
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        valor,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          sufijo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Icono de la referencia dentro de un cuadro tintado.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: tintIcono, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Icon(icono, size: 24, color: colorIcono),
          ),
        ],
      ),
    );
  }
}

