// Copyright 2026 Transporte Escolar Maranata.
// Panel administrativo: centro de configuración de cada módulo.
//
// Se abre desde el botón rojo de Configuración (tras el PIN) y ofrece un
// apartado por menú —Resumen, Estudiantes, Conductores, Flota, Rutas,
// Alertas y Ajustes— con alta, edición y borrado conectados al AdminStore.
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'admin_secciones.dart';

/// Entradas del riel lateral del panel administrativo.
enum _SeccionAdmin {
  resumen,
  alumnos,
  conductores,
  flota,
  rutas,
  viajes,
  asignaciones,
  ubicaciones,
  alertas,
  galeria,
  ajustes,
}

/// Pantalla completa del panel administrativo.
class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  _SeccionAdmin _seccion = _SeccionAdmin.resumen;

  @override
  void initState() {
    super.initState();
    // Intenta sincronizar con la nube (silencioso si no hay Firebase).
    AdminStore.instance.sincronizar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.instance,
      builder: (context, _) {
        final store = AdminStore.instance;
        final ancho = MediaQuery.sizeOf(context).width;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.guindo,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: 'Cerrar panel',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Panel administrativo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _chipSync(store.estadoSync)),
              ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavigationRail(
                extended: ancho > 1100,
                selectedIndex: _SeccionAdmin.values.indexOf(_seccion),
                onDestinationSelected: (i) => setState(
                  () => _seccion = _SeccionAdmin.values[i],
                ),
                backgroundColor: AppColors.surface,
                selectedIconTheme:
                    const IconThemeData(color: AppColors.guindo, size: 24),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.guindo,
                  fontWeight: FontWeight.w700,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Resumen'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school_rounded),
                    label: Text('Estudiantes'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded),
                    label: Text('Conductores'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.directions_bus_outlined),
                    selectedIcon: Icon(Icons.directions_bus_rounded),
                    label: Text('Flota'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded),
                    label: Text('Rutas'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.alt_route_outlined),
                    selectedIcon: Icon(Icons.alt_route_rounded),
                    label: Text('Viajes'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.assignment_ind_outlined),
                    selectedIcon: Icon(Icons.assignment_ind_rounded),
                    label: Text('Asignaciones'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.my_location_outlined),
                    selectedIcon: Icon(Icons.my_location_rounded),
                    label: Text('Ubicaciones'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.warning_amber_outlined),
                    selectedIcon: Icon(Icons.warning_amber_rounded),
                    label: Text('Alertas'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.photo_library_outlined),
                    selectedIcon: Icon(Icons.photo_library_rounded),
                    label: Text('Galería'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune_rounded),
                    label: Text('Ajustes'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _contenido(store),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _contenido(AdminStore store) {
    return switch (_seccion) {
      _SeccionAdmin.resumen => _ResumenSection(store: store),
      _SeccionAdmin.alumnos => const AdminAlumnosSection(),
      _SeccionAdmin.conductores => const AdminConductoresSection(),
      _SeccionAdmin.flota => const AdminFlotaSection(),
      _SeccionAdmin.rutas => const AdminRutasSection(),
      _SeccionAdmin.viajes => const AdminViajesSection(),
      _SeccionAdmin.asignaciones => const AdminAsignacionesSection(),
      _SeccionAdmin.ubicaciones => const AdminUbicacionesSection(),
      _SeccionAdmin.alertas => const AdminAlertasSection(),
      _SeccionAdmin.galeria => const AdminGaleriaSection(),
      _SeccionAdmin.ajustes => _AjustesSection(store: store),
    };
  }

  Widget _chipSync(EstadoSync estado) {
    final (texto, color) = switch (estado) {
      EstadoSync.sincronizado => ('Sincronizado', Colors.white),
      EstadoSync.sincronizando => ('Sincronizando…', Colors.white70),
      EstadoSync.error => ('Solo local', Colors.amberAccent),
      EstadoSync.local => ('Solo local', Colors.white70),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado == EstadoSync.sincronizado
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Apartado «Resumen»: métricas en vivo, bitácora y restauración.
class _ResumenSection extends StatelessWidget {
  const _ResumenSection({required this.store});

  final AdminStore store;

  @override
  Widget build(BuildContext context) {
    final pendientes =
        store.alertas.where((a) => !a.respondido).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del sistema',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Estado actual de los datos que ven todos los módulos.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        MetricGrid(
          children: [
            StatCard(
              label: 'Alumnos',
              value: '${store.alumnos.length}',
              icon: Icons.school_rounded,
            ),
            StatCard(
              label: 'Conductores',
              value: '${store.conductores.length}',
              icon: Icons.badge_rounded,
              color: AppColors.navy,
            ),
            StatCard(
              label: 'Buses',
              value: '${store.buses.length}',
              icon: Icons.directions_bus_rounded,
              color: AppColors.info,
            ),
            StatCard(
              label: 'Rutas',
              value: '${store.rutas.length}',
              icon: Icons.map_rounded,
              color: AppColors.success,
            ),
            StatCard(
              label: 'Alertas sin responder',
              value: '$pendientes',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Actividad reciente del panel',
          subtitle: 'Últimas altas, ediciones y borrados de esta sesión',
          icon: Icons.history_rounded,
          child: store.bitacora.isEmpty
              ? const Text(
                  'Aún no hay movimientos: agrega, edita o elimina un '
                  'registro para verlo aquí.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                )
              : Column(
                  children: [
                    for (final a in store.bitacora.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.hora,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.guindo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.mensaje,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}


/// Apartado «Ajustes»: PIN de acceso, nube y zona de peligro.
class _AjustesSection extends StatefulWidget {
  const _AjustesSection({required this.store});

  final AdminStore store;

  @override
  State<_AjustesSection> createState() => _AjustesSectionState();
}

class _AjustesSectionState extends State<_AjustesSection> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajustes del panel',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Seguridad, sincronización y mantenimiento de los datos.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Seguridad del panel',
          subtitle: 'PIN de acceso al panel administrativo',
          icon: Icons.lock_outline_rounded,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'PIN actual: ${'•' * store.pin.length} '
                  '(${store.pin.length} dígitos)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _cambiarPin(context, store),
                icon: const Icon(Icons.key_rounded, size: 17),
                label: const Text('Cambiar PIN'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Sincronización con la nube',
          subtitle: 'Colecciones persistidas en Realtime Database',
          icon: Icons.cloud_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado: ${_textoSync(store.estadoSync)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nodos: panel/alumnos · panel/conductores · panel/buses · '
                'panel/rutas · panel/alertas · panel/config/pin.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await store.sincronizar();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sincronización intentada con la nube'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text('Sincronizar ahora'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Zona de peligro',
          subtitle: 'Acciones irreversibles sobre los datos',
          icon: Icons.dangerous_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Devuelve alumnos, conductores, flota, rutas y alertas a '
                'los datos de ejemplo originales.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _restaurar(context, store),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Restaurar datos de ejemplo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.guindo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> _cambiarPin(BuildContext context, AdminStore store) async {
    final pin = TextEditingController();
    final confirma = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar PIN del panel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'Nuevo PIN'),
            ),
            TextField(
              controller: confirma,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'Confirma el PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar PIN'),
          ),
        ],
      ),
    );
    pin.dispose();
    confirma.dispose();
    if (ok != true || !context.mounted) return;
    if (pin.text.trim().length < 4 || pin.text.trim() != confirma.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El PIN debe tener 4+ dígitos y coincidir'),
        ),
      );
      return;
    }
    store.cambiarPin(pin.text.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN actualizado correctamente')),
      );
    }
  }

  Future<void> _restaurar(BuildContext context, AdminStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar datos de ejemplo'),
        content: const Text(
          'Se perderán los cambios hechos desde el panel y volverán '
          'los 448 alumnos, 28 conductores, 6 buses, 4 rutas y 6 alertas '
          'originales. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.guindo),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await store.restaurarTodo();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de ejemplo restaurados')),
      );
    }
  }

  String _textoSync(EstadoSync estado) => switch (estado) {
        EstadoSync.sincronizado => 'Sincronizado con la nube',
        EstadoSync.sincronizando => 'Sincronizando…',
        EstadoSync.error => 'Error: trabajando solo en local',
        EstadoSync.local => 'Solo local (sin conexión a la nube)',
      };
}

//__ADMIN_PANEL_PART2__
