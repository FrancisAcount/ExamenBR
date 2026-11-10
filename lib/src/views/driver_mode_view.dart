import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/live_bus.dart';
import '../services/live_bus_service.dart';

import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

/// Modo Conductor flota 50: seleccion + detalle individual con GPS y mapa.
///
/// - Vista principal: grid BUS-1..BUS-50 con "INICIAR RUTA" por tarjeta.
/// - Detalle: telemetria viva del nodo `buses_en_vivo/BUS-XX` + GPS local
///   del celular + GoogleMap con marcador y camara que sigue al conductor.
/// - Coordenadas base de simulacion: lat -16.595322, lon -68.181822.
class DriverModeView extends StatefulWidget {
  const DriverModeView({super.key});

  @override
  State<DriverModeView> createState() => _DriverModeViewState();
}

class _DriverModeViewState extends State<DriverModeView> {
  static const int totalBuses = 50;

  String? selectedBusId;
  List<String> get buses =>
      List<String>.generate(totalBuses, (i) => 'BUS-${i + 1}');

  @override
  Widget build(BuildContext context) {
    final busId = selectedBusId;
    if (busId == null) {
      return _FleetGrid(
        buses: buses,
        onSelect: (id) => setState(() => selectedBusId = id),
      );
    }
    return _DriverBusDetail(
      key: ValueKey(busId),
      busId: busId,
      onBack: () => setState(() => selectedBusId = null),
    );
  }
}

/// Vista principal: cuadricula de 50 tarjetas con INICIAR RUTA.
class _FleetGrid extends StatelessWidget {
  const _FleetGrid({required this.buses, required this.onSelect});

  final List<String> buses;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
          title: 'Flota del conductor',
          subtitle: '${buses.length} unidades — elige tu bus',
          icon: Icons.directions_bus_filled_rounded,
          trailing: const StatusChip(
            label: '50 UNIDADES',
            color: AppColors.info,
            icon: Icons.grid_view_rounded,
          ),
          child: LayoutBuilder(builder: (context, c) {
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
                mainAxisExtent: 158,
              ),
              itemCount: buses.length,
              itemBuilder: (context, i) {
                final id = buses[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F0F172A),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.sidebarBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            id,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ]),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onSelect(id),
                          icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 18),
                          label: const Text('INICIAR RUTA'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    ));
  }
}

/// Detalle individual: GPS + telemetria Firebase + GoogleMap del bus.
class _DriverBusDetail extends StatefulWidget {
  const _DriverBusDetail(
      {super.key, required this.busId, required this.onBack});

  final String busId;
  final VoidCallback onBack;

  @override
  State<_DriverBusDetail> createState() => _DriverBusDetailState();
}

class _DriverBusDetailState extends State<_DriverBusDetail>
    with SingleTickerProviderStateMixin {
  static const int updateSeconds = 3;

  // Base de simulacion pedida (El Alto, La Paz).
  static const double simLat = -16.595322;
  static const double simLon = -68.181822;
  static const LatLng simCenter = LatLng(simLat, simLon);

  bool isActive = false;
  bool isStarting = false;
  String? errorMsg;
  bool firebaseOk = true;

  Position? lastPosition;
  double speedKmh = 0;
  DateTime? lastUpdate;
  DateTime? lastEmittedAt;
  StreamSubscription<Position>? positionSub;
  final LiveBusService liveService = LiveBusService();

  late final MapController _mapController;
  List<Marker> markers = [];

  late final AnimationController blinkController;
  late final Animation<double> blinkAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    blinkAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: blinkController, curve: Curves.easeInOut),
    );
    _seedMapMarker();
  }

  @override
  void dispose() {
    positionSub?.cancel();
    _mapController.dispose();
    blinkController.dispose();
    super.dispose();
  }

  void _seedMapMarker() {
    markers = [
      const Marker(
        point: simCenter,
        width: 40,
        height: 40,
        child: Icon(
          Icons.directions_bus_filled_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    ];
  }

  void animateTo(LatLng target) {
    _mapController.move(target, 16);
  }

  void updateMapFromGps(double lat, double lon) {
    final pos = LatLng(lat, lon);
    if (mounted) {
      setState(() {
        markers = [
          Marker(
            point: pos,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ];
      });
    }
    if (isActive) animateTo(pos);
  }

  Future<void> toggleRoute() async {
    if (isStarting) return;
    if (isActive) {
      await stopRoute();
      return;
    }
    setState(() {
      isStarting = true;
      errorMsg = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const GpsException(
          'Activa el GPS del telefono (Ubicacion) e intentalo de nuevo.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const GpsException(
          'Permiso de ubicacion denegado. Autorizalo para transmitir.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const GpsException(
          'Permiso bloqueado. Activalo en Ajustes > Apps > Maranata > Permisos.',
        );
      }
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() {
            lastPosition = lastKnown;
            speedKmh = lastKnown.speed < 0 ? 0 : lastKnown.speed * 3.6;
            lastUpdate = DateTime.now();
          });
        }
      } catch (_) {
        // El stream entregara la primera fija; no bloquea el inicio.
      }
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
      await positionSub?.cancel();
      lastEmittedAt = null;
      positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        onPosition,
        onError: onStreamError,
      );
      if (!mounted) return;
      setState(() => isActive = true);
      blinkController.repeat(reverse: true);
    } on GpsException catch (e) {
      if (!mounted) return;
      setState(() => errorMsg = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMsg = kIsWeb
          ? 'Chrome bloqueo la ubicacion. Permite ubicacion en el candado de la URL y recarga.'
          : 'No se pudo encender el GPS: $e');
    } finally {
      if (mounted) setState(() => isStarting = false);
    }
  }

  void onPosition(Position position) {
    if (!isActive || !mounted) return;
    final now = DateTime.now();
    if (lastEmittedAt != null &&
        now.difference(lastEmittedAt!).inSeconds < updateSeconds) {
      return;
    }
    lastEmittedAt = now;
    final kmh =
        position.speed.isNaN || position.speed < 0 ? 0.0 : position.speed * 3.6;
    setState(() {
      lastPosition = position;
      speedKmh = kmh;
      lastUpdate = now;
      errorMsg = null;
    });
    // Envio a Firebase Realtime Database: no bloquea la UI.
    liveService
        .publishPosition(
      busId: widget.busId,
      latitud: position.latitude,
      longitud: position.longitude,
      velocidadKmh: kmh,
      rutaActiva: true,
    )
        .then((ok) {
      if (!mounted) return;
      if (firebaseOk != ok) setState(() => firebaseOk = ok);
    });
    updateMapFromGps(position.latitude, position.longitude);
  }

  void onStreamError(Object error) {
    if (!mounted) return;
    setState(() {
      errorMsg = error is GpsException
          ? error.message
          : 'Se perdio la senal GPS. Revisa cobertura y GPS encendido.';
    });
  }

  Future<void> stopRoute() async {
    await positionSub?.cancel();
    positionSub = null;
    blinkController.stop();
    final ok = await liveService.markRouteFinished(widget.busId);
    if (!mounted) return;
    setState(() {
      isActive = false;
      lastEmittedAt = null;
      firebaseOk = ok;
    });
  }

  String fmtCoord(double? v, String placeholder) =>
      v == null ? placeholder : v.toStringAsFixed(6);

  String fmtTime(DateTime? t) {
    if (t == null) return '--:--:--';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.background,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        children: [
        Row(children: [
          IconButton(
            tooltip: 'Volver a la flota',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.sidebarBg,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(widget.busId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: StatusChip(
              label: isActive
                  ? (firebaseOk ? 'GPS + NUBE' : 'GPS SIN NUBE')
                  : 'GPS APAGADO',
              color: isActive
                  ? (firebaseOk ? AppColors.success : AppColors.warning)
                  : AppColors.textMuted,
              icon: isActive
                  ? Icons.satellite_alt_rounded
                  : Icons.satellite_alt_outlined,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ElevatedButton(
            onPressed: isStarting ? null : toggleRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isActive ? AppColors.danger : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStarting)
                  const SizedBox(height: 28, width: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white))
                else
                  Icon(isActive
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_fill_rounded, size: 38),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    isStarting ? 'SOLICITANDO GPS...'
                        : isActive ? 'FINALIZAR RUTA\n(APAGAR GPS)'
                        : 'INICIAR RUTA\n(ENCENDER GPS)',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900, height: 1.15),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg!,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger))),
            ]),
          ),
        ],
        SizedBox(height: isMobile ? 16 : 20),
        SectionCard(
          title: 'Mapa del conductor',
          subtitle: isActive
              ? 'Siguiendo posicion GPS en vivo'
              : 'Base: -16.595322, -68.181822',
          icon: Icons.map_rounded,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 320,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: lastPosition != null
                      ? LatLng(lastPosition!.latitude,
                          lastPosition!.longitude)
                      : simCenter,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.maranata.transporte',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        StreamBuilder<LiveBus>(
          stream: liveService.watchBus(widget.busId),
          builder: (context, snap) {
            final cloud = snap.data;
            final lat = lastPosition?.latitude ?? cloud?.latitud;
            final lon = lastPosition?.longitude ?? cloud?.longitud;
            final kmh = isActive ? speedKmh : (cloud?.velocidadKmh ?? 0);
            final cards = <Widget>[
              GpsInfoCard(label: 'LATITUD ACTUAL',
                  value: fmtCoord(lat, 'Esperando...'),
                  icon: Icons.explore_rounded),
              GpsInfoCard(label: 'LONGITUD ACTUAL',
                  value: fmtCoord(lon, 'Esperando...'),
                  icon: Icons.explore_outlined),
              GpsInfoCard(label: 'VELOCIDAD',
                  value: '${kmh.toStringAsFixed(1)} km/h',
                  icon: Icons.speed_rounded),
              GpsStatusCard(
                  isActive: isActive || (cloud?.rutaActiva ?? false),
                  blink: blinkAnimation,
                  lastUpdate:
                      fmtTime(lastUpdate ?? cloud?.ultimaActualizacion),
                  selectedBus: widget.busId),
            ];
            return LayoutBuilder(builder: (context, c) {
              if (c.maxWidth > 640) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.1,
                  children: cards,
                );
              }
              return Column(children: [
                for (var i = 0; i < cards.length; i++) ...[
                  cards[i],
                  if (i != cards.length - 1) const SizedBox(height: 12),
                ],
              ]);
            });
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Actualizacion cada $updateSeconds segundos - ${widget.busId}'
          '${kIsWeb ? ' - Web: permite ubicacion' : ''}',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    ));
  }
}

/// Tarjeta negra de alto contraste con valor grande.
class GpsInfoCard extends StatelessWidget {
  const GpsInfoCard({super.key,
    required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.sidebarBg,
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(height: 52, width: 52,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(value, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 24, fontWeight: FontWeight.w900)),
            ])),
      ]),
    );
  }
}


/// Tarjeta de estado con icono satelite parpadeante.
class GpsStatusCard extends StatelessWidget {
  const GpsStatusCard({super.key, required this.isActive,
    required this.blink, required this.lastUpdate,
    required this.selectedBus});
  final bool isActive;
  final Animation<double> blink;
  final String lastUpdate;
  final String selectedBus;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: isActive ? AppColors.success : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        FadeTransition(
          opacity: isActive
              ? blink : const AlwaysStoppedAnimation<double>(0.45),
          child: Container(height: 52, width: 52,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle),
            child: const Icon(Icons.satellite_alt_rounded,
                color: Colors.white, size: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ESTADO', style: TextStyle(
                  color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(isActive
                  ? 'Transmitiendo senal de satelite...'
                  : 'GPS apagado - presiona INICIAR RUTA',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('$selectedBus - act. $lastUpdate',
                  style: const TextStyle(color: Colors.white70,
                      fontSize: 12.5, fontWeight: FontWeight.w500)),
            ])),
      ]),
    );
  }
}

/// Error controlado de GPS.
class GpsException implements Exception {
  const GpsException(this.message);
  final String message;
  @override
  String toString() => 'GpsException: $message';
}

