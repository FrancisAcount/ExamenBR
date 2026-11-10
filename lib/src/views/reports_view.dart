import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/admin_store.dart';
import '../services/api_crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

enum _TipoReporte { estudiantes, vehiculos }

enum _PeriodoReporte { semanal, mensual, anual }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _loading = true;
  String? _error;
  String? _avisoParcial;
  DateTime? _actualizado;

  _TipoReporte _tipo = _TipoReporte.estudiantes;
  _PeriodoReporte _periodo = _PeriodoReporte.mensual;
  DateTime _referencia = DateTime.now();

  List<Map<String, dynamic>> _viajes = const [];
  List<Map<String, dynamic>> _asignaciones = const [];
  List<Map<String, dynamic>> _estudiantesApi = const [];
  List<Map<String, dynamic>> _vehiculos = const [];
  List<Map<String, dynamic>> _conductores = const [];
  List<Map<String, dynamic>> _rutas = const [];
  List<Map<String, dynamic>> _ubicaciones = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<List<Map<String, dynamic>>> _safeList(
    String path,
    String key,
    List<String> errores,
  ) async {
    try {
      return await ApiCrudService.listar(path, listKey: key);
    } catch (e) {
      errores.add('$key: $e');
      return const [];
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _avisoParcial = null;
    });
    final errores = <String>[];
    try {
      final results = await Future.wait([
        _safeList('/viajes', 'viajes', errores),
        _safeList('/asignaciones', 'asignaciones', errores),
        _safeList('/estudiantes', 'estudiantes', errores),
        _safeList('/vehiculos', 'vehiculos', errores),
        _safeList('/conductores', 'conductores', errores),
        _safeList('/rutas', 'rutas', errores),
        _safeList('/ubicaciones', 'ubicaciones', errores),
      ]);
      if (!mounted) return;
      setState(() {
        _viajes = results[0];
        _asignaciones = results[1];
        _estudiantesApi = results[2];
        _vehiculos = results[3];
        _conductores = results[4];
        _rutas = results[5];
        _ubicaciones = results[6];
        _loading = false;
        _actualizado = DateTime.now();
        _error = errores.length == 7
            ? 'No fue posible establecer conexión con el servicio de datos (${ApiCrudService.baseUrl}). Verifique la disponibilidad de la API y del servidor MySQL.'
            : null;
        _avisoParcial = (errores.isNotEmpty && errores.length < 7)
            ? 'Se registraron incidencias en la carga de información:\n• ${errores.join('\n• ')}'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado al generar el reporte: $e';
        _loading = false;
      });
    }
  }

  // ---------- helpers ----------
  String _s(dynamic v) => (v == null || '$v'.trim().isEmpty || '$v' == 'null') ? '—' : '$v';

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = '$v'.trim();
    if (s.isEmpty || s == 'null') return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      final p = s.split(' ').first.split('T').first;
      final parts = p.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  DateTime _startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime _endOfWeek(DateTime d) => _startOfWeek(d).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  DateTime _startOfYear(DateTime d) => DateTime(d.year, 1, 1);
  DateTime _endOfYear(DateTime d) => DateTime(d.year, 12, 31, 23, 59, 59);

  (DateTime, DateTime) get _rangoPeriodo {
    switch (_periodo) {
      case _PeriodoReporte.semanal:
        return (_startOfWeek(_referencia), _endOfWeek(_referencia));
      case _PeriodoReporte.mensual:
        return (_startOfMonth(_referencia), _endOfMonth(_referencia));
      case _PeriodoReporte.anual:
        return (_startOfYear(_referencia), _endOfYear(_referencia));
    }
  }

  String get _periodoLabel => switch (_periodo) {
        _PeriodoReporte.semanal => 'Semanal',
        _PeriodoReporte.mensual => 'Mensual',
        _PeriodoReporte.anual => 'Anual',
      };

  String get _tipoLabel => _tipo == _TipoReporte.estudiantes ? 'Por Estudiantes' : 'Por Vehículos';
  String get _tituloReporte => _tipo == _TipoReporte.estudiantes
      ? 'Informe Operativo de Estudiantes'
      : 'Informe Operativo de Vehículos';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _rangoLabel {
    final r = _rangoPeriodo;
    return '${_fmtDate(r.$1)} al ${_fmtDate(r.$2)}';
  }

  bool _enPeriodo(DateTime? d) {
    if (d == null) return false;
    final r = _rangoPeriodo;
    final dd = DateTime(d.year, d.month, d.day, 12);
    return !dd.isBefore(DateTime(r.$1.year, r.$1.month, r.$1.day)) &&
        !dd.isAfter(DateTime(r.$2.year, r.$2.month, r.$2.day, 23, 59, 59));
  }

  List<Map<String, dynamic>> get _viajesPeriodo =>
      _viajes.where((v) => _enPeriodo(_parseDate(v['fecha']))).toList();
  List<Map<String, dynamic>> get _ubicacionesPeriodo =>
      _ubicaciones.where((u) => _enPeriodo(_parseDate(u['fecha_hora']))).toList();

  String _nombreEstudiante(dynamic id) {
    final sid = '$id';
    final e = _estudiantesApi.firstWhere((x) => '${x['id']}' == sid, orElse: () => const {});
    if (e.isNotEmpty) {
      final n = '${_s(e['nombres'])} ${_s(e['apellidos'])}'.trim();
      if (n.isNotEmpty && n != '— —') return n;
    }
    return 'Estudiante $sid';
  }

  String _nombreVehiculo(dynamic id) {
    final vid = '$id';
    final v = _vehiculos.firstWhere((x) => '${x['id']}' == vid, orElse: () => const {});
    if (v.isNotEmpty) {
      final placa = _s(v['placa']);
      final marca = _s(v['marca']);
      final modelo = _s(v['modelo']);
      final nombre = [placa, marca, modelo].where((p) => p != '—').join(' ');
      if (nombre.trim().isNotEmpty) return '$nombre (ID $vid)';
    }
    return 'Vehículo $vid';
  }

  String _nombreConductor(dynamic id) {
    final cid = '$id';
    final c = _conductores.firstWhere((x) => '${x['id']}' == cid, orElse: () => const {});
    if (c.isNotEmpty) {
      final n = '${_s(c['nombres'])} ${_s(c['apellidos'])}'.trim();
      if (n.isNotEmpty && n != '— —') return n;
    }
    return 'Conductor $cid';
  }

  String _nombreRuta(dynamic id) {
    final rid = '$id';
    final r = _rutas.firstWhere((x) => '${x['id']}' == rid, orElse: () => const {});
    if (r.isNotEmpty) {
      final nom = _s(r['nombre']);
      if (nom != '—') return '$nom (ID $rid)';
    }
    return 'Ruta $rid';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.instance,
      builder: (context, _) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _encabezadoInstitucional(),
            if (_error != null) ...[const SizedBox(height: 12), _errorCard()],
            if (_avisoParcial != null) ...[const SizedBox(height: 12), _avisoCard()],
            const SizedBox(height: 16),
            _filtros(),
            const SizedBox(height: 16),
            _resumenPeriodo(),
            const SizedBox(height: 16),
            if (_tipo == _TipoReporte.estudiantes) ..._reporteEstudiantes()
            else ..._reporteVehiculos(),
          ],
        );
      },
    );
  }

  Widget _encabezadoInstitucional() {
    final fechaGen = _actualizado == null ? '—' : '${_fmtDate(_actualizado!)} ${_actualizado!.hour.toString().padLeft(2, '0')}:${_actualizado!.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRANSPORTE ESCOLAR MARANATA',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    const Text('Sistema de Gestión y Monitoreo de Transporte',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Text(_tituloReporte,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('Periodo $_periodoLabel · $_rangoLabel',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  StatusChip(label: 'Actualizado: $fechaGen', color: AppColors.info, icon: Icons.schedule_rounded),
                  FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Actualizar')),
                  FilledButton.icon(
                    onPressed: _imprimir,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Imprimir / PDF'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _meta('Tipo de informe', _tipoLabel),
              _meta('Periodicidad', _periodoLabel),
              _meta('Periodo evaluado', _rangoLabel),
              _meta('Fecha de emisión', fechaGen),
              _meta('Fuente de datos', 'API ${ApiCrudService.baseUrl} y registros del sistema'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextSpan(text: v),
          ],
        ),
      );

  Widget _filtros() {
    return SectionCard(
      title: 'Parámetros del informe',
      subtitle: 'Seleccione el alcance y la periodicidad del reporte',
      icon: Icons.tune_rounded,
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chipSelector<_TipoReporte>(
            label: 'Alcance del informe',
            value: _tipo,
            items: const [
              (_TipoReporte.estudiantes, 'Por Estudiantes', Icons.school_rounded),
              (_TipoReporte.vehiculos, 'Por Vehículos', Icons.directions_bus_rounded),
            ],
            onChanged: (v) => setState(() => _tipo = v),
          ),
          _chipSelector<_PeriodoReporte>(
            label: 'Periodicidad',
            value: _periodo,
            items: const [
              (_PeriodoReporte.semanal, 'Semanal', Icons.view_week_rounded),
              (_PeriodoReporte.mensual, 'Mensual', Icons.calendar_month_rounded),
              (_PeriodoReporte.anual, 'Anual', Icons.calendar_today_rounded),
            ],
            onChanged: (v) => setState(() => _periodo = v),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fecha de referencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _elegirReferencia,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(_fmtDate(_referencia)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipSelector<T>({
    required String label,
    required T value,
    required List<(T, String, IconData)> items,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((it) {
            final sel = it.$1 == value;
            return ChoiceChip(
              selected: sel,
              label: Text(it.$2),
              avatar: Icon(it.$3, size: 16, color: sel ? Colors.white : AppColors.navy),
              selectedColor: AppColors.guindo,
              labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
              onSelected: (_) => onChanged(it.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _elegirReferencia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referencia,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccione la fecha de referencia del periodo',
    );
    if (picked != null) setState(() => _referencia = picked);
  }

  Widget _errorCard() => SectionCard(
        title: 'Error en la obtención de información',
        subtitle: 'No fue posible recuperar la totalidad de los datos desde el servicio.',
        icon: Icons.error_outline_rounded,
        child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.guindo)),
      );

  Widget _avisoCard() => SectionCard(
        title: 'Observaciones sobre la integridad de datos',
        subtitle: 'El informe se generó con carga parcial de información.',
        icon: Icons.warning_amber_rounded,
        child: Text(_avisoParcial!, style: const TextStyle(fontSize: 12.5, color: AppColors.warning)),
      );

  Widget _resumenPeriodo() {
    final vp = _viajesPeriodo;
    final up = _ubicacionesPeriodo;
    final estudiantesConAsig = _asignaciones.map((a) => '${a['estudiante_id']}').toSet().length;
    final vehiculosConViaje = vp.map((v) => '${v['vehiculo_id']}').where((x) => x != 'null' && x != '—').toSet().length;

    Widget kpi(String label, String value, IconData icon, {Color? color}) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (color ?? AppColors.navy).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? AppColors.navy).withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.navy, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'I. Resumen ejecutivo del periodo',
      subtitle: '$_tipoLabel · Periodo $_periodoLabel ($_rangoLabel)',
      icon: Icons.summarize_rounded,
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 2 : 1;
        final items = [
          kpi('Viajes registrados en el periodo', '${vp.length}', Icons.alt_route_rounded, color: AppColors.navy),
          kpi('Asignaciones vigentes', '${_asignaciones.length}', Icons.assignment_ind_outlined, color: AppColors.info),
          kpi('Estudiantes registrados', '${_estudiantesApi.length}', Icons.school_rounded),
          kpi('Estudiantes con asignación', '$estudiantesConAsig', Icons.how_to_reg_rounded, color: AppColors.success),
          kpi('Vehículos registrados', '${_vehiculos.length}', Icons.directions_bus_rounded, color: AppColors.info),
          kpi('Vehículos con actividad', '$vehiculosConViaje', Icons.local_shipping_rounded, color: AppColors.success),
          kpi('Ubicaciones GPS en periodo', '${up.length}', Icons.my_location_rounded, color: AppColors.warning),
          kpi('Rutas registradas', '${_rutas.length}', Icons.map_rounded),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 84,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => items[i],
        );
      }),
    );
  }

  // ---------- Estudiantes ----------
  List<Widget> _reporteEstudiantes() {
    final vp = _viajesPeriodo;
    final asigPorEst = <String, List<Map<String, dynamic>>>{};
    for (final a in _asignaciones) {
      asigPorEst.putIfAbsent('${a['estudiante_id']}', () => []).add(a);
    }
    final estudiantesIds = <String>{..._estudiantesApi.map((e) => '${e['id']}'), ...asigPorEst.keys}
        .where((e) => e != 'null' && e.isNotEmpty)
        .toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    final porRutaCount = <String, int>{};
    for (final a in _asignaciones) {
      final k = _nombreRuta(a['ruta_id']);
      porRutaCount[k] = (porRutaCount[k] ?? 0) + 1;
    }
    final porRutaEntries = porRutaCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return [
      SectionCard(
        title: 'II. Detalle del informe por estudiantes',
        subtitle: 'Periodo evaluado: $_rangoLabel · Total de registros: ${estudiantesIds.length}',
        icon: Icons.school_rounded,
        child: estudiantesIds.isEmpty
            ? _vacio('No se registran estudiantes ni asignaciones para el periodo y parámetros seleccionados.')
            : Column(
                children: estudiantesIds.take(80).map((eid) {
                  final asigs = asigPorEst[eid] ?? const [];
                  final rutasEst = asigs.map((a) => '${a['ruta_id']}').toSet();
                  final viajesEst = vp.where((v) => rutasEst.contains('${v['ruta_id']}')).toList();
                  final rutasN = asigs.map((a) => _nombreRuta(a['ruta_id'])).toSet().join(', ');
                  final paradas = asigs.map((a) => _s(a['parada'])).where((p) => p != '—').toSet().join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background.withValues(alpha: 0.35),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(_nombreEstudiante(eid), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                        StatusChip(label: '${viajesEst.length} viaje(s) en periodo', color: viajesEst.isEmpty ? AppColors.textMuted : AppColors.success),
                      ]),
                      const SizedBox(height: 8),
                      _kv('Asignaciones registradas', '${asigs.length}'),
                      _kv('Rutas asignadas', rutasN.isEmpty ? '—' : rutasN),
                      _kv('Paradas designadas', paradas.isEmpty ? '—' : paradas),
                      _kv('Viajes en periodo (rutas asignadas)', '${viajesEst.length}'),
                      if (viajesEst.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Detalle de viajes del periodo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        const SizedBox(height: 4),
                        ...viajesEst.take(6).map((v) => _filaDetalle(
                              'Viaje N.º ${_s(v['id'])} · ${_fmtDate(_parseDate(v['fecha']) ?? _referencia)}',
                              'Ruta: ${_nombreRuta(v['ruta_id'])} | Vehículo: ${_nombreVehiculo(v['vehiculo_id'])} | Conductor: ${_nombreConductor(v['conductor_id'])} | Estado: ${_s(v['estado'])}',
                            )),
                      ],
                    ]),
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'III. Distribución de asignaciones por ruta',
        subtitle: 'Consolidado de estudiantes/asignaciones vinculadas a cada ruta',
        icon: Icons.account_tree_rounded,
        child: porRutaEntries.isEmpty
            ? _vacio('No se registran asignaciones por ruta.')
            : _tablaSimple(['Ruta', 'Asignaciones'], porRutaEntries.map((e) => [e.key, '${e.value}']).toList()),
      ),
    ];
  }

  // ---------- Vehículos ----------
  List<Widget> _reporteVehiculos() {
    final vp = _viajesPeriodo;
    final up = _ubicacionesPeriodo;
    final vehiculosIds = <String>{..._vehiculos.map((v) => '${v['id']}'), ...vp.map((v) => '${v['vehiculo_id']}')}
        .where((e) => e != 'null' && e.isNotEmpty && e != '—')
        .toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    final viajeIdsPorVehiculo = <String, Set<String>>{};
    for (final v in vp) {
      final vid = '${v['vehiculo_id']}';
      if (vid == 'null' || vid.isEmpty) continue;
      viajeIdsPorVehiculo.putIfAbsent(vid, () => <String>{}).add('${v['id']}');
    }
    final ubisPorViaje = <String, int>{};
    for (final u in up) {
      final tid = '${u['viaje_id']}';
      if (tid == 'null' || tid.isEmpty) continue;
      ubisPorViaje[tid] = (ubisPorViaje[tid] ?? 0) + 1;
    }

    final resumenUso = <String, int>{};
    for (final v in vp) {
      final vid = '${v['vehiculo_id']}';
      if (vid == 'null' || vid.isEmpty) continue;
      final n = _nombreVehiculo(vid);
      resumenUso[n] = (resumenUso[n] ?? 0) + 1;
    }
    final resumenEntries = resumenUso.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return [
      SectionCard(
        title: 'II. Detalle del informe por vehículos',
        subtitle: 'Periodo evaluado: $_rangoLabel · Total de registros: ${vehiculosIds.length}',
        icon: Icons.directions_bus_rounded,
        child: vehiculosIds.isEmpty
            ? _vacio('No se registran vehículos ni viajes para el periodo y parámetros seleccionados.')
            : Column(
                children: vehiculosIds.take(80).map((vid) {
                  final viajesVeh = vp.where((v) => '${v['vehiculo_id']}' == vid).toList();
                  final viajeIds = viajeIdsPorVehiculo[vid] ?? <String>{};
                  final ubisCount = viajeIds.fold<int>(0, (acc, tid) => acc + (ubisPorViaje[tid] ?? 0));
                  final rutas = viajesVeh.map((v) => _nombreRuta(v['ruta_id'])).toSet().join(', ');
                  final conductores = viajesVeh.map((v) => _nombreConductor(v['conductor_id'])).toSet().join(', ');
                  final estados = <String, int>{};
                  for (final v in viajesVeh) {
                    estados[_s(v['estado'])] = (estados[_s(v['estado'])] ?? 0) + 1;
                  }
                  final estadosTxt = estados.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background.withValues(alpha: 0.35),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(_nombreVehiculo(vid), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                        StatusChip(label: '${viajesVeh.length} viaje(s)', color: viajesVeh.isEmpty ? AppColors.textMuted : AppColors.success),
                      ]),
                      const SizedBox(height: 8),
                      _kv('Viajes realizados en el periodo', '${viajesVeh.length}'),
                      _kv('Ubicaciones GPS asociadas (periodo)', '$ubisCount'),
                      _kv('Rutas atendidas', rutas.isEmpty ? '—' : rutas),
                      _kv('Conductores asignados', conductores.isEmpty ? '—' : conductores),
                      _kv('Estados de viaje', estadosTxt.isEmpty ? '—' : estadosTxt),
                      if (viajesVeh.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Detalle de viajes del periodo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        const SizedBox(height: 4),
                        ...viajesVeh.take(8).map((v) => _filaDetalle(
                              'Viaje N.º ${_s(v['id'])} · ${_fmtDate(_parseDate(v['fecha']) ?? _referencia)}',
                              'Ruta: ${_nombreRuta(v['ruta_id'])} | Conductor: ${_nombreConductor(v['conductor_id'])} | Horario: ${_s(v['hora_salida'])}–${_s(v['hora_llegada'])} | Estado: ${_s(v['estado'])}',
                            )),
                      ],
                    ]),
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'III. Consolidado de utilización de vehículos',
        subtitle: 'Total de viajes por unidad en el periodo $_periodoLabel',
        icon: Icons.bar_chart_rounded,
        child: resumenEntries.isEmpty
            ? _vacio('No se registran viajes de vehículos en el periodo seleccionado.')
            : _tablaSimple(['Vehículo', 'Viajes en el periodo'], resumenEntries.map((e) => [e.key, '${e.value}']).toList()),
      ),
    ];
  }

  // ---------- UI helpers ----------
  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            children: [
              TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              TextSpan(text: v),
            ],
          ),
        ),
      );

  Widget _filaDetalle(String titulo, String detalle) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 6, color: AppColors.navy)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(detalle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      );

  Widget _tablaSimple(List<String> headers, List<List<String>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.navy.withValues(alpha: 0.06)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.navy),
        dataTextStyle: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows.take(60).map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList())).toList(),
      ),
    );
  }

  Widget _vacio(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(msg, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
      );

  // ---------- Impresión / PDF formal ----------
  Future<void> _imprimir() async {
    final doc = pw.Document();
    final fecha = _actualizado ?? DateTime.now();
    final fechaTxt = '${_fmtDate(fecha)} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')} hrs.';
    final vp = _viajesPeriodo;

    pw.Widget pdfHeader() {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('TRANSPORTE ESCOLAR MARANATA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Text('Sistema de Gestión y Monitoreo de Transporte', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
              pw.Text(_tituloReporte.toUpperCase(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Fecha de emisión: $fechaTxt', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Periodicidad: $_periodoLabel', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Periodo evaluado: $_rangoLabel', style: const pw.TextStyle(fontSize: 9)),
          ]),
        ]),
      );
    }

    pw.Widget pdfSection(String title, {List<String>? bullets, List<List<String>>? table, List<String>? headers}) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          color: PdfColors.blueGrey50,
          child: pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ),
        pw.SizedBox(height: 6),
        if (table != null && headers != null && table.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: table.take(40).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          )
        else if (bullets != null && bullets.isNotEmpty)
          ...bullets.take(50).map((b) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 9))),
                ]),
              ))
        else
          pw.Text('No se registran datos para los parámetros seleccionados.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
      ]);
    }

    final content = <pw.Widget>[
      pdfHeader(),
      if (_avisoParcial != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.amber50,
            child: pw.Text('Observación: el presente informe fue generado con carga parcial de información debido a incidencias en la obtención de datos.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.orange800)),
          ),
        ),
      pdfSection('I. Resumen ejecutivo del periodo', table: [
        ['Indicador', 'Valor'],
        ['Periodo evaluado', _rangoLabel],
        ['Periodicidad', _periodoLabel],
        ['Tipo de informe', _tipoLabel],
        ['Viajes registrados en el periodo', '${vp.length}'],
        ['Asignaciones vigentes (total)', '${_asignaciones.length}'],
        ['Estudiantes registrados', '${_estudiantesApi.length}'],
        ['Vehículos registrados', '${_vehiculos.length}'],
        ['Ubicaciones GPS en el periodo', '${_ubicacionesPeriodo.length}'],
        ['Rutas registradas', '${_rutas.length}'],
      ], headers: ['Indicador', 'Valor']),
    ];

    if (_tipo == _TipoReporte.estudiantes) {
      final asigPorEst = <String, List<Map<String, dynamic>>>{};
      for (final a in _asignaciones) {
        asigPorEst.putIfAbsent('${a['estudiante_id']}', () => []).add(a);
      }
      final ids = <String>{..._estudiantesApi.map((e) => '${e['id']}'), ...asigPorEst.keys}
          .where((e) => e != 'null' && e.isNotEmpty)
          .toList()
        ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      final rows = ids.take(50).map((eid) {
        final asigs = asigPorEst[eid] ?? const [];
        final rutasEst = asigs.map((a) => '${a['ruta_id']}').toSet();
        final ve = vp.where((v) => rutasEst.contains('${v['ruta_id']}')).length;
        final rutasN = asigs.map((a) => _nombreRuta(a['ruta_id'])).toSet().join(', ');
        return [_nombreEstudiante(eid), '${asigs.length}', '$ve', rutasN.isEmpty ? '—' : rutasN];
      }).toList();
      content.add(pdfSection('II. Detalle por estudiantes', table: rows, headers: ['Estudiante', 'Asignaciones', 'Viajes en periodo', 'Rutas asignadas']));

      final porRutaCount = <String, int>{};
      for (final a in _asignaciones) {
        porRutaCount[_nombreRuta(a['ruta_id'])] = (porRutaCount[_nombreRuta(a['ruta_id'])] ?? 0) + 1;
      }
      final pr = porRutaCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      content.add(pdfSection('III. Distribución de asignaciones por ruta', table: pr.map((e) => [e.key, '${e.value}']).toList(), headers: ['Ruta', 'Asignaciones']));
    } else {
      final vehiculosIds = <String>{..._vehiculos.map((v) => '${v['id']}'), ...vp.map((v) => '${v['vehiculo_id']}')}
          .where((e) => e != 'null' && e.isNotEmpty && e != '—')
          .toList()
        ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      final rows = vehiculosIds.take(50).map((vid) {
        final vv = vp.where((v) => '${v['vehiculo_id']}' == vid).toList();
        final rutas = vv.map((v) => _nombreRuta(v['ruta_id'])).toSet().join(', ');
        final conductores = vv.map((v) => _nombreConductor(v['conductor_id'])).toSet().join(', ');
        return [_nombreVehiculo(vid), '${vv.length}', rutas.isEmpty ? '—' : rutas, conductores.isEmpty ? '—' : conductores];
      }).toList();
      content.add(pdfSection('II. Detalle por vehículos', table: rows, headers: ['Vehículo', 'Viajes en periodo', 'Rutas atendidas', 'Conductores']));

      final m = <String, int>{};
      for (final v in vp) {
        final vid = '${v['vehiculo_id']}';
        if (vid == 'null' || vid.isEmpty) continue;
        m[_nombreVehiculo(vid)] = (m[_nombreVehiculo(vid)] ?? 0) + 1;
      }
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      content.add(pdfSection('III. Consolidado de utilización de vehículos', table: e.map((x) => [x.key, '${x.value}']).toList(), headers: ['Vehículo', 'Total de viajes']));
    }

    content.add(pw.SizedBox(height: 18));
    content.add(pw.Divider(color: PdfColors.grey400));
    content.add(pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Documento generado por el Sistema de Gestión de Transporte Escolar Maranata', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      pw.Text('Periodo: $_periodoLabel ($_rangoLabel)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ]));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => ctx.pageNumber > 1
          ? pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text('$_tituloReporte · $_rangoLabel', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            )
          : pw.SizedBox(),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (ctx) => content,
    ));

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'Informe_${_tipo == _TipoReporte.estudiantes ? 'Estudiantes' : 'Vehiculos'}_${_periodoLabel}_${_fmtDateIso(_rangoPeriodo.$1)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No fue posible generar o imprimir el informe: $e')));
    }
  }
}
