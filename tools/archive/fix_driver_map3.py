path = r'c:\Users\Cori\OneDrive\Documents\Transporte_Maranata\lib\src\views\driver_mode_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Reemplazar líneas 510-521 (0-indexed: 509-520) - el widget GoogleMap incompleto
# Línea 510: "              child: FlutterMap("
# Línea 511: "                options: MapOptions("
# Línea 512: "                  target: lastPosition != null"
# ... hasta línea 521: "              ),"

new_block = [
    '              child: FlutterMap(\n',
    '                mapController: _mapController,\n',
    '                options: MapOptions(\n',
    '                  initialCenter: lastPosition != null\n',
    '                      ? LatLng(lastPosition!.latitude,\n',
    '                          lastPosition!.longitude)\n',
    '                      : simCenter,\n',
    '                  initialZoom: 15,\n',
    '                ),\n',
    '                children: [\n',
    '                  TileLayer(\n',
    "                    urlTemplate:\n",
    "                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',\n",
    '                    userAgentPackageName:\n',
    "                        'com.maranata.transporte',\n",
    '                  ),\n',
    '                  MarkerLayer(markers: markers),\n',
    '                ],\n',
    '              ),\n',
]

# Reemplazar líneas 509-520 (índices 509 a 520 inclusive)
start = 509  # línea 510
end = 521    # línea 521 (exclusive)
lines[start:end] = new_block

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Widget FlutterMap corregido en líneas 510-521')