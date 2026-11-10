import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bus_illustration.dart';
import 'welcome_common.dart';
import 'welcome_data.dart';

/// Bloque 4 — Mini carrusel horizontal de beneficios.
///
/// La implementación usa un [PageView] (vista por páginas) controlado con
/// flechas laterales e indicadores, de modo que el desplazamiento nativo del
/// sistema no interfiera con el scroll vertical de la portada.
class WelcomeBenefitsCarousel extends StatefulWidget {
  const WelcomeBenefitsCarousel({super.key, this.items = kWelcomeBenefits});

  final List<WelcomeBenefit> items;

  @override
  State<WelcomeBenefitsCarousel> createState() => _WelcomeBenefitsCarouselState();
}

class _WelcomeBenefitsCarouselState extends State<WelcomeBenefitsCarousel> {
  /// Controlador del carrusel; se reutiliza entre reconstrucciones.
  final PageController _controlador = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Avanza o retrocede una tarjeta dentro del carrusel.
  void _irA(int destino) {
    final total = widget.items.length;
    if (total == 0) return;
    final pagina = destino.clamp(0, total - 1);
    _controlador.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.items.isEmpty) {
      return const WelcomeEmptyState(texto: 'Beneficios no disponibles por ahora.');
    }

    return WelcomeSection(
      child: Column(
        children: [
          Row(
            children: [
              _FlechaCarousel(
                icono: Icons.chevron_left_rounded,
                tooltip: 'Beneficio anterior',
                onPressed: _pagina > 0 ? () => _irA(_pagina - 1) : null,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 118,
                  child: PageView.builder(
                    controller: _controlador,
                    itemCount: widget.items.length,
                    onPageChanged: (i) => setState(() => _pagina = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _TarjetaBeneficio(item: widget.items[i], isDark: isDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FlechaCarousel(
                icono: Icons.chevron_right_rounded,
                tooltip: 'Beneficio siguiente',
                onPressed: _pagina < widget.items.length - 1 ? () => _irA(_pagina + 1) : null,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Indicadores de página (puntos).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: i == _pagina ? 18 : 6,
                  decoration: BoxDecoration(
                    color: i == _pagina ? AppColors.crimson : (isDark ? AppColors.darkBorder : AppColors.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Flecha circular del carrusel; se atenúa cuando no hay destino válido.
class _FlechaCarousel extends StatelessWidget {
  const _FlechaCarousel({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: CircleBorder(side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icono,
              size: 22,
              color: onPressed == null ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted) : (isDark ? Colors.white : AppColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de beneficio: miniatura a la izquierda + titular y descripción.
class _TarjetaBeneficio extends StatelessWidget {
  const _TarjetaBeneficio({required this.item, required this.isDark});

  final WelcomeBenefit item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return WelcomeCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Row(
        children: [
          // Miniatura real del beneficio (ilustración vectorial de la flota).
          SizedBox(
            width: 92,
            child: BusIllustration(scene: item.scene, height: 92, borderRadius: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
