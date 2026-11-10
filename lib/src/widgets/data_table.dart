import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tabla simulada con encabezado oscuro y filas alternadas.
/// Todas las columnas tienen el mismo peso, así cabecera y filas quedan alineadas.
class DataTableSim extends StatelessWidget {
  const DataTableSim({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ancho mínimo para mantener proporciones legibles en pantallas grandes.
    // `IntrinsicWidth` acota el ancho en un scroll horizontal (si no, `stretch`
    // pediría un ancho infinito y el layout falla).
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 820),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSidebarBg : AppColors.sidebarBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: headers
                    .map((h) => Expanded(child: Text(h.toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.textOnDark))))
                    .toList(),
              ),
            ),
            for (int i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: i.isEven ? (isDark ? AppColors.darkSurface : AppColors.surface) : (isDark ? AppColors.darkRowAlt : AppColors.rowAlt),
                child: Row(
                  children: rows[i]
                      .map((cell) => Expanded(child: Align(alignment: Alignment.centerLeft, child: cell)))
                      .toList(),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
