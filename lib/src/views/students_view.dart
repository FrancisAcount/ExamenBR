import 'package:flutter/material.dart';
import '../data/admin_store.dart';
import '../data/driver_data.dart';
import '../models/driver_record.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'bus_student_detail_view.dart';

/// 🧒 Apartado 5: registro de estudiantes agrupado por unidad.
///
/// La pantalla principal muestra una cuadrícula con las 28 tarjetas de bus
/// (número de unidad, placa y chófer). El botón «Ver estudiantes» muestra el
/// detalle de la unidad **dentro de este mismo módulo** (con el menú lateral
/// visible), con el nombre del chófer y la lista tipo Excel de sus alumnos.
class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  /// Unidad abierta en detalle; `null` = se muestra la cuadrícula de buses.
  ///
  /// El detalle se gestiona con estado local (y no con `Navigator.push`) para
  /// que la vista permanezca dentro del shell con el sidebar visible.
  String? _busSeleccionado;

  /// Unidades del padrón vivo del [AdminStore]: si el panel agrega o quita
  /// conductores, las tarjetas se actualizan en vivo.
  List<DriverRecord> get _unidades => AdminStore.instance.conductores;

  /// Estilo de las microetiquetas en versalitas de las tarjetas.
  static TextStyle _etiqueta(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      letterSpacing: 1,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Unidades visibles tras el buscador (chofer, placa o número de bus).
  List<DriverRecord> get _visibles {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _unidades;
    return _unidades
        .where((u) => '${u.bus} ${u.nombre} ${DriverData.placaDe(u.bus)}'
            .toLowerCase()
            .contains(q))
        .toList();
  }

  /// Abre el detalle de la unidad dentro del propio módulo.
  ///
  /// No se usa `Navigator.push`: el detalle reemplaza la cuadrícula con
  /// `setState`, de modo que el shell (menú lateral + cabecera) permanece.
  void _abrirUnidad(DriverRecord unidad) {
    setState(() => _busSeleccionado = unidad.bus);
  }

  /// Regresa a la cuadrícula de las 28 tarjetas.
  void _volverAUnidades() => setState(() => _busSeleccionado = null);

  @override
  Widget build(BuildContext context) {
    // Detalle de la unidad: se renderiza dentro del mismo módulo para que el
    // menú lateral siga visible, igual que en el resto de apartados.
    final bus = _busSeleccionado;
    if (bus != null) {
      return ListenableBuilder(
        listenable: AdminStore.instance,
        builder: (context, _) => BusStudentDetailView(
          busId: bus,
          onVolver: _volverAUnidades,
        ),
      );
    }

    return ListenableBuilder(
      listenable: AdminStore.instance,
      builder: (context, _) {
        final visibles = _visibles;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppSearchBar(
              hintText: 'Buscar por chófer, placa o número de bus...',
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            _encabezado(visibles.length),
            const SizedBox(height: 16),
            if (visibles.isEmpty) _vacio(context) else _cuadricula(visibles),
          ],
        );
      },
    );
  }

  /// Título del módulo con el resumen de buses y alumnos.
  Widget _encabezado(int unidades) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unidades de transporte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_unidades.length} buses · ${AdminStore.instance.alumnos.length} alumnos matriculados',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          label: '$unidades unidades',
          color: AppColors.navy,
          icon: Icons.directions_bus_rounded,
        ),
      ],
    );
  }

  /// Cuadrícula responsive de tarjetas de bus (1 a 4 columnas).
  Widget _cuadricula(List<DriverRecord> unidades) => LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final columnas = ancho >= 1100
              ? 4
              : ancho >= 820
                  ? 3
                  : ancho >= 540
                      ? 2
                      : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnas,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 204,
            ),
            itemCount: unidades.length,
            itemBuilder: (context, i) => _tarjeta(unidades[i]),
          );
        },
      );

  /// Tarjeta de una unidad: número de bus, placa, chófer y botón de acceso.
  Widget _tarjeta(DriverRecord unidad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placa = DriverData.placaDe(unidad.bus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N.° DE BUS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _etiqueta(context),
                    ),
                    Text(
                      unidad.bus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: isDark ? 0.2 : 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.navy.withValues(alpha: isDark ? 0.4 : 0.25),
                  ),
                ),
                child: Text(
                  placa,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.navy,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: 12),
          Text('CHOFER', style: _etiqueta(context)),
          const SizedBox(height: 3),
          Text(
            unidad.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _abrirUnidad(unidad),
              icon: const Icon(Icons.groups_rounded, size: 17),
              label: const Text('Ver estudiantes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacío cuando el buscador no encuentra ninguna unidad.
  Widget _vacio(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 46,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba con otro chófer, placa o número de bus.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      );
}
