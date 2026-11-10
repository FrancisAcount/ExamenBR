import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../models/bus.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/data_table.dart';
import 'admin/admin_form.dart';

/// 🚌 Apartado 3: control de autobuses, placas y estado mecánico.
class FleetView extends StatelessWidget {
  const FleetView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: AdminStore.instance,
      builder: (context, _) {
        final buses = AdminStore.instance.buses;
        int porEstado(BusStatus s) =>
            buses.where((b) => b.estado == s).length;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Resumen de estados de la flota (conteos vivos del panel).
            MetricGrid(
              children: [
                StatCard(
                  label: 'En ruta',
                  value: '${porEstado(BusStatus.enRuta)}',
                  icon: Icons.directions_bus_filled_rounded,
                  color: AppColors.success,
                ),
                StatCard(
                  label: 'En garaje',
                  value: '${porEstado(BusStatus.enGaraje)}',
                  icon: Icons.garage_outlined,
                  color: AppColors.info,
                ),
                StatCard(
                  label: 'En mantenimiento',
                  value: '${porEstado(BusStatus.mantenimiento)}',
                  icon: Icons.build_circle_outlined,
                  color: AppColors.warning,
                ),
                StatCard(
                  label: 'Fuera de servicio',
                  value: '${porEstado(BusStatus.fueraDeServicio)}',
                  icon: Icons.car_crash_outlined,
                  color: AppColors.guindo,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabla de la flota
            SectionCard(
              title: 'Inventario de flota',
              subtitle: '${buses.length} vehículos registrados',
              icon: Icons.directions_bus_filled_rounded,
              trailing: FilledButton.icon(
                onPressed: () => _nuevoBus(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo bus'),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTableSim(
                  headers: const [
                    'Placa',
                    'Marca y modelo',
                    'Capacidad',
                    'Conductor',
                    'Ruta',
                    'Kilometraje',
                    'Mantenimiento',
                    'Estado'
                  ],
                  rows: buses.map(_buildRow).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fichas de vehículo
            SectionCard(
              title: 'Fichas técnicas destacadas',
              subtitle: 'Vehículos con intervención reciente',
              icon: Icons.assignment_outlined,
              // Fichas técnicas dimensionadas por contenido (sin alturas fijas).
              child: AdaptiveGrid(
                maxColumns: 3,
                children: buses.take(3).map((b) => _buildSpecCard(b, isDark: isDark)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
  /// Fila de la tabla de flota.
  List<Widget> _buildRow(Bus b) => <Widget>[
        Text(b.placa, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        Text('${b.marca} ${b.modelo}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text('${b.capacidad} pax', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(b.conductor, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(b.ruta, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text('${formatThousands(b.kilometraje)} km', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(
          b.proximoMantenimiento,
          style: TextStyle(
            fontSize: 12.5,
            color: b.proximoMantenimiento == 'Hoy' ? AppColors.guindo : AppColors.textSecondary,
            fontWeight: b.proximoMantenimiento == 'Hoy' ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        StatusChip(label: b.estado.label, color: busStatusColor(b.estado)),
      ];

  /// Ficha técnica de un vehículo.
  Widget _buildSpecCard(Bus b, {required bool isDark}) {
    final color = busStatusColor(b.estado);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.airport_shuttle_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.placa, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(
                        '${b.marca} ${b.modelo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _specLine('Capacidad', '${b.capacidad} pasajeros', isDark: isDark),
            _specLine('Kilometraje', '${formatThousands(b.kilometraje)} km', isDark: isDark),
            _specLine('Próximo mantenimiento', b.proximoMantenimiento, isDark: isDark),
            _specLine('Estado', b.estado.label, isDark: isDark),
          ],
        ),
      ),
    );
  }

  /// Línea clave: valor dentro de la ficha técnica.
  Widget _specLine(String label, String value, {required bool isDark}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted))),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      );

  Future<void> _nuevoBus(BuildContext context) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: 'Nuevo bus',
      icono: Icons.directions_bus_rounded,
      campos: const [
        CampoForm(clave: 'placa', etiqueta: 'Placa (única)', icono: Icons.confirmation_number_outlined),
        CampoForm(clave: 'marca', etiqueta: 'Marca', icono: Icons.factory_outlined),
        CampoForm(clave: 'modelo', etiqueta: 'Modelo', icono: Icons.directions_bus_outlined),
        CampoForm(clave: 'capacidad', etiqueta: 'Capacidad (pasajeros)', icono: Icons.groups_outlined, tipo: TipoCampo.numero),
        CampoForm(clave: 'conductor', etiqueta: 'Conductor asignado', icono: Icons.badge_outlined),
        CampoForm(clave: 'ruta', etiqueta: 'Ruta asignada', icono: Icons.route_rounded),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.build_circle_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['En ruta', 'En garaje', 'Mantenimiento', 'Fuera de servicio'],
        ),
        CampoForm(clave: 'kilometraje', etiqueta: 'Kilometraje', icono: Icons.speed_rounded, tipo: TipoCampo.numero),
        CampoForm(clave: 'mantenimiento', etiqueta: 'Próximo mantenimiento', icono: Icons.event_rounded),
      ],
    );
    if (valores == null || !context.mounted) return;
    final bus = Bus(
      placa: valores['placa']!.toUpperCase(),
      marca: valores['marca']!,
      modelo: valores['modelo']!,
      capacidad: int.tryParse(valores['capacidad']!) ?? 0,
      conductor: valores['conductor']!,
      ruta: valores['ruta']!,
      estado: _estadoBus(valores['estado'] ?? ''),
      kilometraje: int.tryParse(valores['kilometraje']!) ?? 0,
      proximoMantenimiento: valores['mantenimiento']!,
    );
    final ok = store.agregarBus(bus);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Bus ${bus.placa} agregado correctamente'
            : 'No se pudo agregar: la placa ya existe'),
      ),
    );
  }

  BusStatus _estadoBus(String etiqueta) => switch (etiqueta) {
        'En ruta' => BusStatus.enRuta,
        'Mantenimiento' => BusStatus.mantenimiento,
        'Fuera de servicio' => BusStatus.fueraDeServicio,
        _ => BusStatus.enGaraje,
      };
}

/// Color asociado al estado mecánico del bus.
Color busStatusColor(BusStatus s) => switch (s) {
      BusStatus.enRuta => AppColors.success,
      BusStatus.enGaraje => AppColors.info,
      BusStatus.mantenimiento => AppColors.warning,
      BusStatus.fueraDeServicio => AppColors.guindo,
    };

/// Formatea miles con separador de punto (128450 → 128.450).
String formatThousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
