import 'package:flutter/material.dart';

/// Un apartado del menú lateral.
class MenuItem {
  const MenuItem({required this.label, required this.icon, required this.title, required this.subtitle});

  final String label;
  final IconData icon;
  final String title; // Título mostrado en la cabecera central
  final String subtitle; // Descripción bajo el título
}

/// Catálogo central de los módulos de la aplicación.
///
/// El índice 0 es «Bienvenida» y se corresponde con `HomeScreen._views[0]`; el
/// botón «Iniciar Sesión» de la portada salta al índice 1 («Panel de Inicio»).
class AppMenu {
  AppMenu._();

  static const List<MenuItem> items = [
    // Bienvenida: acceso al módulo dentro del panel, con su cabecera de marca.
    MenuItem(label: 'Bienvenida', icon: Icons.waving_hand_rounded, title: 'Bienvenida', subtitle: 'Información institucional del servicio de transporte'),
    MenuItem(label: 'Panel de Inicio', icon: Icons.dashboard_rounded, title: 'Panel de Inicio', subtitle: 'Resumen operativo de flota y estudiantes'),
    MenuItem(label: 'Rutas y Monitoreo', icon: Icons.map_rounded, title: 'Rutas y Monitoreo', subtitle: 'Monitoreo en vivo de 50 buses con mapa'),
    MenuItem(label: 'Gestión de Flota', icon: Icons.directions_bus_rounded, title: 'Gestión de Flota', subtitle: 'Autobuses, placas y estado mecánico'),
    MenuItem(label: 'Conductores y Personal', icon: Icons.badge_rounded, title: 'Conductores y Personal', subtitle: 'Fichas técnicas de choferes y asistentes'),
    MenuItem(label: 'Registro de Estudiantes', icon: Icons.school_rounded, title: 'Registro de Estudiantes', subtitle: 'Alumnos asignados a cada ruta'),
    MenuItem(label: 'Alertas y Seguridad', icon: Icons.warning_amber_rounded, title: 'Alertas y Seguridad', subtitle: 'Bitácora de retrasos y emergencias'),
    MenuItem(label: 'Reportes', icon: Icons.assessment_rounded, title: 'Reportes', subtitle: 'Informes de viajes, buses, estudiantes y operación'),
    MenuItem(label: 'Galería', icon: Icons.photo_library_rounded, title: 'Galería', subtitle: 'Fotos reales de nuestra flota de 18 asientos'),
    MenuItem(label: 'Configuración', icon: Icons.settings_rounded, title: 'Configuración', subtitle: 'Ajustes generales del sistema y perfil'),
    MenuItem(label: 'Modo Conductor', icon: Icons.satellite_alt_rounded, title: 'Modo Conductor', subtitle: 'GPS en tiempo real desde el celular del chofer'),
  ];

  /// Index → MenuItem (con fallback seguro).
  static MenuItem byIndex(int index) =>
      index >= 0 && index < items.length ? items[index] : items.first;
}
