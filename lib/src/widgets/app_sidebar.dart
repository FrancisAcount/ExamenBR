import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';

/// Menú lateral azul oscuro institucional con los 7 apartados.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.selectedIndex, required this.onSelected, this.collapsed = false});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Versión compacta (solo iconos) para pantallas pequeñas.
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: collapsed ? 76 : 264,
      color: isDark ? AppColors.darkSidebarBg : AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrand(isDark: isDark),
          Expanded(child: _buildMenu(isDark: isDark)),
          _buildFooter(isDark: isDark),
        ],
      ),
    );
  }

  /// Logotipo + nombre de la institución.
  Widget _buildBrand({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(color: AppColors.guindo, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 24),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maranata', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Transporte Escolar',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMenu({required bool isDark}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: AppMenu.items.length,
      itemBuilder: (context, index) {
        final item = AppMenu.items[index];
        final isSelected = index == selectedIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: isSelected ? AppColors.guindo : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(index),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14, vertical: 13),
                child: Row(
                  mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(
                      item.icon,
                      size: 21,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1)),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      if (isSelected) const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pie de menú con usuario activo.
  Widget _buildFooter({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFF1E293B)),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.guindo,
            child: Text('CM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coordinador', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Administrador', style: TextStyle(color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

