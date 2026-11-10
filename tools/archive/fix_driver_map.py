path = r'c:\Users\Cori\OneDrive\Documents\Transporte_Maranata\lib\src\views\driver_mode_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Import
content = content.replace(
    "import 'package:google_maps_flutter/google_maps_flutter.dart';",
    "import 'package:flutter_map/flutter_map.dart';\nimport 'package:latlong2/latlong.dart';"
)

# 2. Variables de estado
content = content.replace(
    "  GoogleMapController? mapController;\n  Set<Marker> markers = {};",
    "  late final MapController _mapController;\n  List<Marker> markers = [];"
)

# 3. Dispose
content = content.replace(
    "    mapController?.dispose();",
    "    _mapController.dispose();"
)

# 4. _seedMapMarker
content = content.replace(
    """  void _seedMapMarker() {
    markers = {
      const Marker(
        markerId: MarkerId('bus-marker'),
        position: simCenter,
        infoWindow: InfoWindow(title: 'Punto base de simulacion'),
      ),
    };
  }""",
    """  void _seedMapMarker() {
    markers = [
      Marker(
        point: simCenter,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.directions_bus_filled_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    ];
  }"""
)

# 5. animateTo
content = content.replace(
    """  Future<void> animateTo(LatLng target) async {
    final c = mapController;
    if (c == null) return;
    try {
      await c.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      // Mapa aun no listo.
    }
  }""",
    """  void animateTo(LatLng target) {
    _mapController.move(target, 16);
  }"""
)

# 6. updateMapFromGps
content = content.replace(
    """  void updateMapFromGps(double lat, double lon) {
    final pos = LatLng(lat, lon);
    if (mounted) {
      setState(() {
        markers = {
          Marker(
            markerId: const MarkerId('bus-marker'),
            position: pos,
            infoWindow: InfoWindow(
              title: widget.busId,
              snippet: '${speedKmh.toStringAsFixed(1)} km/h',
            ),
          ),
        };
      });
    }
    if (isActive) animateTo(pos);
  }""",
    """  void updateMapFromGps(double lat, double lon) {
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
  }"""
)

# 7. GoogleMap -> FlutterMap widget
content = content.replace(
    """            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: lastPosition != null
                        ? LatLng(lastPosition!.latitude,
                            lastPosition!.longitude)
                        : simCenter,
                    zoom: 15,
                  ),
                  markers: markers,
                  onMapCreated: (c) => mapController = c,
                  myLocationEnabled: false,
                ),
              ),
            ),""",
    """            child: ClipRRect(
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
            ),"""
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Archivo driver_mode_view.dart corregido exitosamente')