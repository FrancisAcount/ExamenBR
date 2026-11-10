path = r'c:\Users\Cori\OneDrive\Documents\Transporte_Maranata\lib\src\views\driver_mode_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Encontrar y reemplazar la sección GoogleMap en el build (líneas 506-522)
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    # Detectar inicio del widget GoogleMap en el build del mapa del conductor
    if 'child: GoogleMap(' in line:
        # Reemplazar GoogleMap por FlutterMap
        new_lines.append(line.replace('child: GoogleMap(', 'child: FlutterMap('))
        i += 1
        # Reemplazar initialCameraPosition: CameraPosition por options: MapOptions
        while i < len(lines):
            l = lines[i]
            if 'initialCameraPosition: CameraPosition(' in l:
                new_lines.append(l.replace('initialCameraPosition: CameraPosition(', 'options: MapOptions('))
            elif 'onMapCreated: (c) => mapController = c,' in l:
                new_lines.append(l.replace('onMapCreated: (c) => mapController = c,', 'mapController: _mapController,'))
            elif 'myLocationEnabled: false,' in l:
                # Saltar esta línea (eliminar)
                pass
            elif 'markers: markers,' in l:
                new_lines.append(l)
                # Agregar TileLayer y MarkerLayer después de markers
                new_lines.append('                  children: [\n')
                new_lines.append('                    TileLayer(\n')
                new_lines.append("                      urlTemplate:\n")
                new_lines.append("                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',\n")
                new_lines.append('                      userAgentPackageName:\n')
                new_lines.append("                          'com.maranata.transporte',\n")
                new_lines.append('                    ),\n')
                new_lines.append('                    MarkerLayer(markers: markers),\n')
                new_lines.append('                  ],\n')
            elif '                ),' in l and i > 515:
                # Cierre de GoogleMap -> FlutterMap
                new_lines.append(l)
                i += 1
                break
            else:
                new_lines.append(l)
            i += 1
    else:
        new_lines.append(line)
        i += 1

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Seccion GoogleMap reemplazada por FlutterMap en driver_mode_view.dart')