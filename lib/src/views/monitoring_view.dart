import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/admin_store.dart';
import '../models/live_bus.dart';
import '../services/live_bus_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'live_bus_tracking_view.dart';

/// Rutas y Monitoreo: flota en vivo desde Firebase (`buses_en_vivo`) con
/// modo simulación automático cuando no hay dispositivo GPS enviando datos.
class MonitoringView extends StatefulWidget {
  const MonitoringView({super.key});

  @override
  State<MonitoringView> createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  static const int totalBuses = 50;
  static const LatLng _base = LatLng(-16.4897, -68.1193); // La Paz (referencia)

  final LiveBusService liveService = LiveBusService();
  String? focusedBusId;

  // Simulación (sin GPS físico)
  Timer? _simTimer;
  List<LiveBus> _simulados = const [];
  double _tick = 0;
  bool _forzarSimulacion = false;

  @override
  void initState() {
    super.initState();
    _simulados = _generarSimulados(0);
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _tick += 1;
        _simulados = _generarSimulados(_tick);
      });
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  List<LiveBus> _generarSimulados(double t) {
    // Simula un subconjunto de buses en movimiento para que el monitoreo sea visible.
    final activos = math.min(12, totalBuses);
    return List<LiveBus>.generate(totalBuses, (i) {
      final id = 'BUS-${i + 1}';
      if (i >= activos) {
        return LiveBus(id: id, rutaActiva: false, latitud: null, longitud: null, velocidadKmh: 0);
      }
      final ang = (t * 0.08) + (i * 0.55);
      final radioLat = 0.015 + (i % 5) * 0.003;
      final radioLng = 0.018 + (i % 4) * 0.003;
      final lat = _base.latitude + math.sin(ang) * radioLat;
      final lng = _base.longitude + math.cos(ang) * radioLng;
      final vel = 18 + (i % 6) * 5 + (math.sin(t * 0.3 + i) * 4);
      return LiveBus(
        id: id,
        rutaActiva: true,
        latitud: lat,
        longitud: lng,
        velocidadKmh: vel.abs(),
        ultimaActualizacion: DateTime.now(),
      );
    });
  }

  void focusBus(String busId) => setState(() => focusedBusId = busId);

  Future<void> _abrirEnGoogleMaps(BuildContext context, LiveBus bus) async {
    if (!bus.hasPosition) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin ubicación disponible para este bus.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    final lat = bus.latitud!;
    final lng = bus.longitud!;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _mostrarOpcionesMapa(BuildContext context, LiveBus bus, {required bool simulado}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ver ${bus.id} en el mapa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              simulado
                  ? 'Mostrando posición simulada (sin GPS físico).'
                  : 'Elige cómo quieres ver la ubicación del bus.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.open_in_new, color: isDark ? Colors.white : AppColors.navy),
              title: Text('Abrir en Google Maps', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              subtitle: Text('Posición actual ${simulado ? '(simulada)' : ''}', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _abrirEnGoogleMaps(context, bus);
              },
            ),
            ListTile(
              leading: Icon(Icons.live_tv, color: isDark ? Colors.green : AppColors.success),
              title: Text('Seguimiento en vivo', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              subtitle: Text(
                simulado
                    ? 'En simulación: la app muestra movimiento sin dispositivo GPS'
                    : 'El marcador se mueve con datos reales de Firebase',
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveBusTrackingView(busId: bus.id),
                  ),
                );
              },
            ),
            if (simulado && bus.hasPosition)
              ListTile(
                leading: const Icon(Icons.map_rounded, color: AppColors.info),
                title: const Text('Vista rápida en mapa (simulada)'),
                subtitle: const Text('Ver marcador simulado dentro de esta pantalla'),
                onTap: () {
                  Navigator.pop(ctx);
                  _mostrarMapaSimulado(context, bus);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarMapaSimulado(BuildContext context, LiveBus bus) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${bus.id} — Monitoreo simulado'),
        content: SizedBox(
          width: 520,
          height: 360,
          child: _MiniMapa(bus: bus),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.instance,
      builder: (context, _) {
        final stream = liveService.watchFleet(total: totalBuses);
        return StreamBuilder<List<LiveBus>>(
          stream: stream,
          builder: (context, snap) {
            final reales = snap.data ??
                List<LiveBus>.generate(totalBuses, (i) => LiveBus.offline('BUS-${i + 1}'));
            final hayPosicionesReales = reales.any((b) => b.hasPosition);
            final usandoSimulacion = _forzarSimulacion || !hayPosicionesReales;
            final buses = usandoSimulacion ? _simulados : reales;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _bannerEstado(
                  hayPosicionesReales: hayPosicionesReales,
                  usandoSimulacion: usandoSimulacion,
                  error: snap.hasError ? '${snap.error}' : null,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 1100
                      ? 4
                      : c.maxWidth > 800
                          ? 3
                          : c.maxWidth > 520
                              ? 2
                              : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 190,
                    ),
                    itemCount: buses.length,
                    itemBuilder: (context, i) => _BusCard(
                      bus: buses[i],
                      selected: buses[i].id == focusedBusId,
                      simulado: usandoSimulacion,
                      onViewOnMap: () => _mostrarOpcionesMapa(
                        context,
                        buses[i],
                        simulado: usandoSimulacion,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bannerEstado({
    required bool hayPosicionesReales,
    required bool usandoSimulacion,
    String? error,
  }) {
    final color = usandoSimulacion ? AppColors.info : AppColors.success;
    final titulo = usandoSimulacion
        ? 'Monitoreo en modo simulación (sin dispositivo GPS)'
        : 'Monitoreo en vivo conectado a Firebase';
    final detalle = usandoSimulacion
        ? 'Se muestran posiciones simuladas para que puedas probar rutas y monitoreo. Cuando el GPS físico envíe datos a Firebase (buses_en_vivo), se usarán automáticamente.'
        : 'Recibiendo posiciones reales desde Realtime Database (buses_en_vivo).';
    return SectionCard(
      title: titulo,
      subtitle: 'Rutas y Monitoreo · Firebase: trasporte-maranata',
      icon: usandoSimulacion ? Icons.sensors_off_rounded : Icons.sensors_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(label: usandoSimulacion ? 'SIMULADO' : 'EN VIVO', color: color, icon: Icons.satellite_alt_rounded),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _forzarSimulacion ? 'Usar datos reales si existen' : 'Forzar simulación',
            onPressed: () => setState(() => _forzarSimulacion = !_forzarSimulacion),
            icon: Icon(_forzarSimulacion ? Icons.sync_rounded : Icons.science_outlined),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detalle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text('Aviso Firebase: $error', style: const TextStyle(fontSize: 12, color: AppColors.warning)),
          ],
        ],
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  const _BusCard({
    required this.bus,
    required this.selected,
    required this.onViewOnMap,
    required this.simulado,
  });
  final LiveBus bus;
  final bool selected;
  final bool simulado;
  final VoidCallback onViewOnMap;

  @override
  Widget build(BuildContext context) {
    final active = bus.rutaActiva || bus.hasPosition;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.border),
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (active ? AppColors.success : AppColors.textMuted).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_bus_filled_rounded, size: 20, color: active ? AppColors.success : AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bus.id,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
            StatusChip(
              label: active ? (simulado ? 'SIMULADO' : 'EN RUTA') : 'APAGADO',
              color: active ? AppColors.success : AppColors.textMuted,
              icon: active ? Icons.satellite_alt_rounded : Icons.satellite_alt_outlined,
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            active ? '${bus.velocidadKmh.toStringAsFixed(1)} km/h' : 'Sin transmisión',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          Text(
            bus.hasPosition
                ? '${bus.latitud!.toStringAsFixed(5)}, ${bus.longitud!.toStringAsFixed(5)}'
                : '-- , --',
            style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onViewOnMap,
              style: FilledButton.styleFrom(
                backgroundColor: selected ? AppColors.success : AppColors.sidebarBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ver en Mapa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapa extends StatelessWidget {
  const _MiniMapa({required this.bus});
  final LiveBus bus;

  @override
  Widget build(BuildContext context) {
    final center = bus.hasPosition ? LatLng(bus.latitud!, bus.longitud!) : const LatLng(-16.4897, -68.1193);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.maranata.transporte',
          ),
          if (bus.hasPosition)
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.guindo, size: 34),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
