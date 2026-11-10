// Copyright 2026 Transporte Escolar Maranata.
// Apartados de matrícula y personal del panel administrativo.
//
// Cada sección configura un módulo del sistema (estudiantes, conductores)
// con alta, edición y borrado conectados al [AdminStore].
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:image/image.dart' as img;

import '../../data/admin_store.dart';
import '../../data/student_data.dart';
import '../../models/bus.dart';
import '../../models/driver_record.dart';
import '../../models/foto_galeria.dart';
import '../../models/route.dart';
import '../../models/safety_alert.dart';
import '../../models/student_record.dart';
import '../../services/api_crud_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'admin_form.dart';
import 'admin_list.dart';

/// Unidades disponibles para asignar alumnos (BUS-1 … BUS-28 del padrón).
List<String> _busesDisponibles(AdminStore store) {
  final buses = store.conductores.map((d) => d.bus).toSet().toList()
    ..sort((a, b) => _numBus(a).compareTo(_numBus(b)));
  return buses.isEmpty ? const ['BUS-1'] : buses;
}

int _numBus(String bus) => int.tryParse(bus.split('-').last) ?? 999;

/// Apartado «Estudiantes»: configura la matrícula de cada unidad.
class AdminAlumnosSection extends StatelessWidget {
  const AdminAlumnosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminListSection<StudentRecord>(
      titulo: 'Estudiantes',
      subtitulo: 'Matrícula por unidad: agrega, edita o elimina alumnos.',
      icono: Icons.school_rounded,
      hintBusqueda: 'Buscar alumno por nombre, bus o grado...',
      etiquetaNuevo: 'Nuevo alumno',
      items: () => store.alumnos,
      coincide: (a, q) =>
          '${a.nombreCompleto} ${a.busId} ${a.grado} ${a.parada}'
              .toLowerCase()
              .contains(q),
      clave: (a) => a.id,
      tarjeta: (a) => TarjetaAdmin(
        titulo: a.nombreCompleto,
        subtitulo: '${a.grado} · ${a.busId} · ${a.parada}\n'
            'Rep.: ${a.telefonoRepresentante}',
        avatar: a.iniciales,
        chipTexto: a.estadoLabel,
        chipColor: a.colorEstado,
      ),
      nombreEliminar: (a) => a.nombreCompleto,
      onNuevo: (ctx) => _formAlumno(ctx),
      onEditar: (ctx, a) => _formAlumno(ctx, existente: a),
      onEliminar: (ctx, a) async {
        store.eliminarAlumno(a.id);
      },
    );
  }

  Future<void> _formAlumno(
    BuildContext context, {
    StudentRecord? existente,
  }) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: existente == null ? 'Nuevo alumno' : 'Editar alumno',
      icono: Icons.school_rounded,
      iniciales: existente == null
          ? null
          : {
              'nombres': existente.nombres,
              'apellidoPaterno': existente.apellidoPaterno,
              'apellidoMaterno': existente.apellidoMaterno,
              'grado': existente.grado,
              'parada': existente.parada,
              'estado': existente.estadoLabel,
              'busId': existente.busId,
              'telefono': existente.telefonoRepresentante,
            },
      campos: [
        const CampoForm(
          clave: 'nombres',
          etiqueta: 'Nombres',
          icono: Icons.person_outline_rounded,
        ),
        const CampoForm(
          clave: 'apellidoPaterno',
          etiqueta: 'Apellido paterno',
          icono: Icons.person_outline_rounded,
        ),
        const CampoForm(
          clave: 'apellidoMaterno',
          etiqueta: 'Apellido materno',
          icono: Icons.person_outline_rounded,
        ),
        const CampoForm(
          clave: 'grado',
          etiqueta: 'Grado',
          icono: Icons.class_outlined,
          tipo: TipoCampo.opciones,
          opciones: StudentData.grados,
        ),
        const CampoForm(
          clave: 'parada',
          etiqueta: 'Parada',
          icono: Icons.location_on_outlined,
          tipo: TipoCampo.opciones,
          opciones: StudentData.paradas,
        ),
        CampoForm(
          clave: 'busId',
          etiqueta: 'Unidad (bus)',
          icono: Icons.directions_bus_outlined,
          tipo: TipoCampo.opciones,
          opciones: _busesDisponibles(store),
        ),
        const CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.flag_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['En la escuela', 'Recogido', 'En ruta', 'Ausente'],
        ),
        const CampoForm(
          clave: 'telefono',
          etiqueta: 'Teléfono del representante',
          icono: Icons.phone_iphone_rounded,
        ),
      ],
    );
    if (valores == null || !context.mounted) return;
    final estado = _estadoAlumno(valores['estado'] ?? '');
    final ok = existente == null
        ? store.agregarAlumno(StudentRecord(
            id: store.nuevoId('STU', store.alumnos.map((a) => a.id)),
            nombres: valores['nombres']!,
            apellidoPaterno: valores['apellidoPaterno']!,
            apellidoMaterno: valores['apellidoMaterno']!,
            grado: valores['grado']!,
            parada: valores['parada']!,
            estado: estado,
            busId: valores['busId']!,
            telefonoRepresentante: valores['telefono']!,
          ))
        : store.actualizarAlumno(StudentRecord(
            id: existente.id,
            nombres: valores['nombres']!,
            apellidoPaterno: valores['apellidoPaterno']!,
            apellidoMaterno: valores['apellidoMaterno']!,
            grado: valores['grado']!,
            parada: valores['parada']!,
            estado: estado,
            busId: valores['busId']!,
            telefonoRepresentante: valores['telefono']!,
          ));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar: id duplicado')),
      );
    }
  }

  StudentStatus _estadoAlumno(String etiqueta) => switch (etiqueta) {
        'Recogido' => StudentStatus.recogido,
        'En ruta' => StudentStatus.enRuta,
        'Ausente' => StudentStatus.ausente,
        _ => StudentStatus.enEscuela,
      };
}


/// Apartado «Conductores»: configura el padrón de choferes y asistentes.
class AdminConductoresSection extends StatelessWidget {
  const AdminConductoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminListSection<DriverRecord>(
      titulo: 'Conductores',
      subtitulo: 'Padrón de choferes y asistentes de las 28 unidades.',
      icono: Icons.badge_rounded,
      hintBusqueda: 'Buscar conductor por nombre, bus o cédula...',
      etiquetaNuevo: 'Nuevo conductor',
      items: () => store.conductores,
      coincide: (d, q) =>
          '${d.nombre} ${d.bus} ${d.cedula} ${d.ruta} ${d.cargo}'
              .toLowerCase()
              .contains(q),
      clave: (d) => d.id,
      tarjeta: (d) => TarjetaAdmin(
        titulo: d.nombre,
        subtitulo: '${d.cargo} · ${d.bus} · C.I. ${d.cedula}\n'
            '${d.telefono} · Lic. ${d.licencia}',
        avatar: d.iniciales,
        chipTexto: d.estadoLabel,
        chipColor: d.colorEstado,
      ),
      nombreEliminar: (d) => d.nombre,
      onNuevo: (ctx) => _formConductor(ctx),
      onEditar: (ctx, d) => _formConductor(ctx, existente: d),
      onEliminar: (ctx, d) async {
        store.eliminarConductor(d.id);
      },
    );
  }

  Future<void> _formConductor(
    BuildContext context, {
    DriverRecord? existente,
  }) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: existente == null ? 'Nuevo conductor' : 'Editar conductor',
      icono: Icons.badge_rounded,
      iniciales: existente == null
          ? null
          : {
              'nombre': existente.nombre,
              'cedula': existente.cedula,
              'telefono': existente.telefono,
              'bus': existente.bus,
              'licencia': existente.licencia,
              'ruta': existente.ruta,
              'cargo': existente.cargo,
              'experiencia': '${existente.aniosExperiencia}',
              'estado': existente.estadoLabel,
            },
      campos: const [
        CampoForm(
          clave: 'nombre',
          etiqueta: 'Nombre completo',
          icono: Icons.person_outline_rounded,
        ),
        CampoForm(
          clave: 'cedula',
          etiqueta: 'Cédula',
          icono: Icons.contact_mail_outlined,
        ),
        CampoForm(
          clave: 'telefono',
          etiqueta: 'Teléfono',
          icono: Icons.phone_iphone_rounded,
        ),
        CampoForm(
          clave: 'bus',
          etiqueta: 'Bus asignado (BUS-1 … BUS-28)',
          icono: Icons.directions_bus_outlined,
        ),
        CampoForm(
          clave: 'licencia',
          etiqueta: 'Licencia',
          icono: Icons.workspace_premium_outlined,
        ),
        CampoForm(
          clave: 'ruta',
          etiqueta: 'Ruta',
          icono: Icons.route_rounded,
        ),
        CampoForm(
          clave: 'cargo',
          etiqueta: 'Cargo',
          icono: Icons.work_outline_rounded,
          tipo: TipoCampo.opciones,
          opciones: ['Conductor', 'Conductora', 'Asistente'],
        ),
        CampoForm(
          clave: 'experiencia',
          etiqueta: 'Años de experiencia',
          icono: Icons.timeline_rounded,
          tipo: TipoCampo.numero,
        ),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.flag_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['En Ruta', 'Disponible', 'Ausente'],
        ),
      ],
    );
    if (valores == null || !context.mounted) return;
    final ok = existente == null
        ? store.agregarConductor(DriverRecord(
            id: store.nuevoId('DRV', store.conductores.map((d) => d.id)),
            nombre: valores['nombre']!,
            cedula: valores['cedula']!,
            telefono: valores['telefono']!,
            bus: valores['bus']!.toUpperCase(),
            licencia: valores['licencia']!,
            ruta: valores['ruta']!,
            cargo: valores['cargo']!,
            aniosExperiencia: int.tryParse(valores['experiencia']!) ?? 0,
            estado: _estadoConductor(valores['estado'] ?? ''),
          ))
        : store.actualizarConductor(DriverRecord(
            id: existente.id,
            nombre: valores['nombre']!,
            cedula: valores['cedula']!,
            telefono: valores['telefono']!,
            bus: valores['bus']!.toUpperCase(),
            licencia: valores['licencia']!,
            ruta: valores['ruta']!,
            cargo: valores['cargo']!,
            aniosExperiencia: int.tryParse(valores['experiencia']!) ?? 0,
            estado: _estadoConductor(valores['estado'] ?? ''),
          ));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar: id duplicado')),
      );
    }
  }

  DriverStatus _estadoConductor(String etiqueta) => switch (etiqueta) {
        'En Ruta' => DriverStatus.enRuta,
        'Ausente' => DriverStatus.ausente,
        _ => DriverStatus.disponible,
      };
}

/// Apartado «Flota»: configura los buses, placas y estado mecánico.
class AdminFlotaSection extends StatelessWidget {
  const AdminFlotaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminListSection<Bus>(
      titulo: 'Flota',
      subtitulo: 'Vehículos, placas, capacidad y estado mecánico.',
      icono: Icons.directions_bus_rounded,
      hintBusqueda: 'Buscar bus por placa, marca o conductor...',
      etiquetaNuevo: 'Nuevo bus',
      items: () => store.buses,
      coincide: (b, q) =>
          '${b.placa} ${b.marca} ${b.modelo} ${b.conductor} ${b.ruta}'
              .toLowerCase()
              .contains(q),
      clave: (b) => b.placa,
      tarjeta: (b) => TarjetaAdmin(
        titulo: '${b.placa} · ${b.marca} ${b.modelo}',
        subtitulo: '${b.capacidad} pax · ${formatKm(b.kilometraje)} km · '
            'Mant.: ${b.proximoMantenimiento}\n'
            '${b.conductor} · ${b.ruta}',
        avatar: '🚌',
        chipTexto: b.estado.label,
        chipColor: colorBus(b.estado),
      ),
      nombreEliminar: (b) => b.placa,
      onNuevo: (ctx) => _formBus(ctx),
      onEditar: (ctx, b) => _formBus(ctx, existente: b),
      onEliminar: (ctx, b) async {
        store.eliminarBus(b.placa);
      },
    );
  }

  Future<void> _formBus(BuildContext context, {Bus? existente}) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: existente == null ? 'Nuevo bus' : 'Editar bus',
      icono: Icons.directions_bus_rounded,
      iniciales: existente == null
          ? null
          : {
              'placa': existente.placa,
              'marca': existente.marca,
              'modelo': existente.modelo,
              'capacidad': '${existente.capacidad}',
              'conductor': existente.conductor,
              'ruta': existente.ruta,
              'estado': existente.estado.label,
              'kilometraje': '${existente.kilometraje}',
              'mantenimiento': existente.proximoMantenimiento,
            },
      campos: const [
        CampoForm(
          clave: 'placa',
          etiqueta: 'Placa (única)',
          icono: Icons.confirmation_number_outlined,
        ),
        CampoForm(
          clave: 'marca',
          etiqueta: 'Marca',
          icono: Icons.factory_outlined,
        ),
        CampoForm(
          clave: 'modelo',
          etiqueta: 'Modelo',
          icono: Icons.directions_bus_outlined,
        ),
        CampoForm(
          clave: 'capacidad',
          etiqueta: 'Capacidad (pasajeros)',
          icono: Icons.groups_outlined,
          tipo: TipoCampo.numero,
        ),
        CampoForm(
          clave: 'conductor',
          etiqueta: 'Conductor asignado',
          icono: Icons.badge_outlined,
        ),
        CampoForm(
          clave: 'ruta',
          etiqueta: 'Ruta asignada',
          icono: Icons.route_rounded,
        ),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.build_circle_outlined,
          tipo: TipoCampo.opciones,
          opciones: [
            'En ruta',
            'En garaje',
            'Mantenimiento',
            'Fuera de servicio',
          ],
        ),
        CampoForm(
          clave: 'kilometraje',
          etiqueta: 'Kilometraje',
          icono: Icons.speed_rounded,
          tipo: TipoCampo.numero,
        ),
        CampoForm(
          clave: 'mantenimiento',
          etiqueta: 'Próximo mantenimiento',
          icono: Icons.event_rounded,
        ),
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
    final ok = existente == null
        ? store.agregarBus(bus)
        : store.actualizarBus(existente.placa, bus);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar: placa duplicada')),
      );
    }
  }

  BusStatus _estadoBus(String etiqueta) => switch (etiqueta) {
        'En ruta' => BusStatus.enRuta,
        'Mantenimiento' => BusStatus.mantenimiento,
        'Fuera de servicio' => BusStatus.fueraDeServicio,
        _ => BusStatus.enGaraje,
      };
}



/// Apartado «Rutas»: configura códigos, zonas, horarios y paraderos.
class AdminRutasSection extends StatelessWidget {
  const AdminRutasSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminListSection<Route>(
      titulo: 'Rutas',
      subtitulo: 'Trazados, zonas, buses asignados y horarios.',
      icono: Icons.map_rounded,
      hintBusqueda: 'Buscar ruta por código, nombre o zona...',
      etiquetaNuevo: 'Nueva ruta',
      items: () => store.rutas,
      coincide: (r, q) =>
          '${r.codigo} ${r.nombre} ${r.zona} ${r.bus} ${r.conductor}'
              .toLowerCase()
              .contains(q),
      clave: (r) => r.codigo,
      tarjeta: (r) => TarjetaAdmin(
        titulo: '${r.codigo} · ${r.nombre}',
        subtitulo: '${r.zona} · ${r.bus} · ${r.conductor}\n'
            '${r.estudiantes} est. · ${r.horaSalida} – ${r.horaRegreso}',
        avatar: '🗺️',
        chipTexto: r.estado,
        chipColor: colorRuta(r.estado),
      ),
      nombreEliminar: (r) => r.codigo,
      onNuevo: (ctx) => _formRuta(ctx),
      onEditar: (ctx, r) => _formRuta(ctx, existente: r),
      onEliminar: (ctx, r) async {
        store.eliminarRuta(r.codigo);
      },
    );
  }

  Future<void> _formRuta(BuildContext context, {Route? existente}) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: existente == null ? 'Nueva ruta' : 'Editar ruta',
      icono: Icons.map_rounded,
      iniciales: existente == null
          ? null
          : {
              'codigo': existente.codigo,
              'nombre': existente.nombre,
              'zona': existente.zona,
              'bus': existente.bus,
              'conductor': existente.conductor,
              'estudiantes': '${existente.estudiantes}',
              'salida': existente.horaSalida,
              'regreso': existente.horaRegreso,
              'estado': existente.estado,
              'origen': existente.primerPunto,
              'destino': existente.ultimoPunto,
            },
      campos: const [
        CampoForm(
          clave: 'codigo',
          etiqueta: 'Código (único, ej. RT-05)',
          icono: Icons.tag_rounded,
        ),
        CampoForm(
          clave: 'nombre',
          etiqueta: 'Nombre de la ruta',
          icono: Icons.map_outlined,
        ),
        CampoForm(
          clave: 'zona',
          etiqueta: 'Zona',
          icono: Icons.location_city_rounded,
        ),
        CampoForm(
          clave: 'bus',
          etiqueta: 'Bus asignado (placa)',
          icono: Icons.directions_bus_outlined,
        ),
        CampoForm(
          clave: 'conductor',
          etiqueta: 'Conductor',
          icono: Icons.badge_outlined,
        ),
        CampoForm(
          clave: 'estudiantes',
          etiqueta: 'Estudiantes a bordo',
          icono: Icons.groups_outlined,
          tipo: TipoCampo.numero,
        ),
        CampoForm(
          clave: 'salida',
          etiqueta: 'Hora de salida (06:30)',
          icono: Icons.schedule_rounded,
        ),
        CampoForm(
          clave: 'regreso',
          etiqueta: 'Hora de regreso (13:30)',
          icono: Icons.schedule_rounded,
        ),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.flag_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['En curso', 'Programada', 'Finalizada'],
        ),
        CampoForm(
          clave: 'origen',
          etiqueta: 'Primer punto',
          icono: Icons.trip_origin_rounded,
        ),
        CampoForm(
          clave: 'destino',
          etiqueta: 'Último punto',
          icono: Icons.place_rounded,
        ),
      ],
    );
    if (valores == null || !context.mounted) return;
    final ruta = Route(
      codigo: valores['codigo']!.toUpperCase(),
      nombre: valores['nombre']!,
      zona: valores['zona']!,
      bus: valores['bus']!.toUpperCase(),
      conductor: valores['conductor']!,
      estudiantes: int.tryParse(valores['estudiantes']!) ?? 0,
      horaSalida: valores['salida']!,
      horaRegreso: valores['regreso']!,
      estado: valores['estado']!,
      primerPunto: valores['origen']!,
      ultimoPunto: valores['destino']!,
    );
    final ok = existente == null
        ? store.agregarRuta(ruta)
        : store.actualizarRuta(existente.codigo, ruta);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar: código duplicado')),
      );
    }
  }
}

/// Color del chip de estado textual de una ruta (igual que en el módulo).
Color colorRuta(String estado) => switch (estado) {
      'En curso' => AppColors.success,
      'Programada' => AppColors.info,
      _ => AppColors.textMuted,
    };

/// Color del chip de estado mecánico de un bus (igual que en el módulo).
Color colorBus(BusStatus s) => switch (s) {
      BusStatus.enRuta => AppColors.success,
      BusStatus.enGaraje => AppColors.info,
      BusStatus.mantenimiento => AppColors.warning,
      BusStatus.fueraDeServicio => AppColors.guindo,
    };

/// Miles con punto (128450 → 128.450).
String formatKm(int n) =>
    n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');



/// Apartado «Alertas»: configura la bitácora de seguridad y emergencias.
class AdminAlertasSection extends StatelessWidget {
  const AdminAlertasSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminListSection<SafetyAlert>(
      titulo: 'Alertas',
      subtitulo: 'Bitácora de retrasos, emergencias y notificaciones.',
      icono: Icons.warning_amber_rounded,
      hintBusqueda: 'Buscar alerta por título o ruta...',
      etiquetaNuevo: 'Nueva alerta',
      items: () => store.alertas,
      coincide: (a, q) =>
          '${a.titulo} ${a.detalle} ${a.ruta}'.toLowerCase().contains(q),
      clave: (a) => a.id,
      tarjeta: (a) => TarjetaAdmin(
        titulo: '${a.hora} · ${a.titulo}',
        subtitulo: '${a.detalle}\n${a.ruta}'
            '${a.respondido ? ' · Atendida' : ' · Sin responder'}',
        avatar: '🚨',
        chipTexto: a.nivel.label,
        chipColor: a.nivel.color,
      ),
      nombreEliminar: (a) => a.titulo,
      onNuevo: (ctx) => _formAlerta(ctx),
      onEditar: (ctx, a) => _formAlerta(ctx, existente: a),
      onEliminar: (ctx, a) async {
        store.eliminarAlerta(a.id);
      },
    );
  }

  Future<void> _formAlerta(
    BuildContext context, {
    SafetyAlert? existente,
  }) async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: existente == null ? 'Nueva alerta' : 'Editar alerta',
      icono: Icons.warning_amber_rounded,
      iniciales: existente == null
          ? null
          : {
              'hora': existente.hora,
              'titulo': existente.titulo,
              'detalle': existente.detalle,
              'nivel': existente.nivel.label,
              'ruta': existente.ruta,
              'respondido': '${existente.respondido}',
            },
      campos: const [
        CampoForm(
          clave: 'hora',
          etiqueta: 'Hora (07:42)',
          icono: Icons.schedule_rounded,
        ),
        CampoForm(
          clave: 'titulo',
          etiqueta: 'Título',
          icono: Icons.title_rounded,
        ),
        CampoForm(
          clave: 'detalle',
          etiqueta: 'Detalle',
          icono: Icons.notes_rounded,
          lineas: 3,
        ),
        CampoForm(
          clave: 'nivel',
          etiqueta: 'Nivel',
          icono: Icons.priority_high_rounded,
          tipo: TipoCampo.opciones,
          opciones: ['Crítica', 'Advertencia', 'Informativa'],
        ),
        CampoForm(
          clave: 'ruta',
          etiqueta: 'Ruta afectada',
          icono: Icons.route_rounded,
        ),
        CampoForm(
          clave: 'respondido',
          etiqueta: 'Marcada como atendida',
          tipo: TipoCampo.interruptor,
        ),
      ],
    );
    if (valores == null || !context.mounted) return;
    final nivel = _nivelAlerta(valores['nivel'] ?? '');
    final respondido = valores['respondido'] == 'true';
    final ok = existente == null
        ? store.agregarAlerta(SafetyAlert(
            id: store.nuevoId('ALT', store.alertas.map((a) => a.id)),
            hora: valores['hora']!,
            titulo: valores['titulo']!,
            detalle: valores['detalle']!,
            nivel: nivel,
            ruta: valores['ruta']!,
            respondido: respondido,
          ))
        : (respondido && !existente.respondido
            ? store.marcarAtendida(existente.id)
            : store.actualizarAlerta(SafetyAlert(
                id: existente.id,
                hora: valores['hora']!,
                titulo: valores['titulo']!,
                detalle: valores['detalle']!,
                nivel: nivel,
                ruta: valores['ruta']!,
                respondido: respondido,
              )));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la alerta')),
      );
    }
  }

  AlertLevel _nivelAlerta(String etiqueta) => switch (etiqueta) {
        'Crítica' => AlertLevel.critical,
        'Advertencia' => AlertLevel.warning,
        _ => AlertLevel.info,
      };
}

/// Apartado «Galería»: sube fotos desde el dispositivo y gestiona las subidas.
///
/// La imagen se comprime a un ancho máximo de 1280 px (JPEG calidad 80) para
/// que el payload base64 quepa en Realtime Database. Tras guardar, la foto
/// aparece al instante en el módulo «Galería» del menú lateral.
class AdminGaleriaSection extends StatefulWidget {
  const AdminGaleriaSection({super.key});

  @override
  State<AdminGaleriaSection> createState() => _AdminGaleriaSectionState();
}

class _AdminGaleriaSectionState extends State<AdminGaleriaSection> {
  /// Imagen seleccionada pero aún no guardada (comprimida).
  Uint8List? _preview;
  String? _previewNombre;

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _procesando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final fotos = store.fotosGaleria;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Subir foto a la galería',
          subtitle: 'Elige una imagen desde tu dispositivo',
          icon: Icons.upload_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_preview != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_preview!, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                Text(
                  _previewNombre ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título de la foto',
                  hintText: 'Ej. Bus de la Ruta Norte',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej. Minibús de 18 asientos, salida 06:30',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _procesando ? null : _elegirImagen,
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Elegir imagen del dispositivo'),
                  ),
                  FilledButton.icon(
                    onPressed: (_preview != null && !_procesando) ? _guardar : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(_procesando ? 'Procesando…' : 'Guardar en la galería'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Fotos subidas (${fotos.length})',
          subtitle: 'Se muestran en el módulo Galería del menú lateral',
          icon: Icons.photo_camera_rounded,
          child: fotos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Aún no has subido ninguna foto.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final columnas = c.maxWidth >= 900
                        ? 3
                        : (c.maxWidth >= 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: columnas,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        for (final f in fotos) _TarjetaSubida(foto: f, store: store),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Abre el selector de archivos del dispositivo y comprime la imagen.
  Future<void> _elegirImagen() async {
    final archivos =
        await FilePicker.pickFiles(type: FileType.image);
    if (archivos.isEmpty) return;
    final archivo = archivos.first;
    final Uint8List bytes;
    try {
      bytes = await archivo.readAsBytes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer la imagen elegida')),
        );
      }
      return;
    }

    setState(() => _procesando = true);
    try {
      final comprimida = _comprimir(bytes);
      setState(() {
        _preview = comprimida;
        _previewNombre = archivo.name;
        if (_tituloCtrl.text.trim().isEmpty) {
          _tituloCtrl.text = _quitarExtension(archivo.name);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato de imagen no soportado')),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  /// Reduce la imagen a un ancho máximo de 1280 px y la reentrama en JPEG.
  Uint8List _comprimir(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    img.Image processed = decoded;
    const anchoMax = 1280;
    if (processed.width > anchoMax) {
      processed = img.copyResize(
        processed,
        width: anchoMax,
        interpolation: img.Interpolation.linear,
      );
    }
    return Uint8List.fromList(img.encodeJpg(processed, quality: 80));
  }

  /// Guarda la foto en el store (y en la nube).
  Future<void> _guardar() async {
    final bytes = _preview;
    if (bytes == null) return;
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un título para la foto')),
      );
      return;
    }

    setState(() => _procesando = true);
    try {
      final store = AdminStore.instance;
      final foto = FotoGaleria(
        id: store.siguienteIdFoto(),
        titulo: titulo,
        descripcion: _descCtrl.text.trim(),
        datosBase64: base64Encode(bytes),
        fechaSubida: DateTime.now().millisecondsSinceEpoch,
      );
      final ok = store.agregarFoto(foto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Foto «$titulo» agregada a la galería'
              : 'No se pudo guardar la foto'),
        ),
      );
      if (ok) {
        setState(() {
          _preview = null;
          _previewNombre = null;
          _tituloCtrl.clear();
          _descCtrl.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  String _quitarExtension(String nombre) {
    final i = nombre.lastIndexOf('.');
    return i > 0 ? nombre.substring(0, i) : nombre;
  }
}

/// Tarjeta de una foto ya subida, con miniatura, título y borrado.
class _TarjetaSubida extends StatelessWidget {
  const _TarjetaSubida({required this.foto, required this.store});

  final FotoGaleria foto;
  final AdminStore store;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(foto.datosBase64);
    } catch (_) {
      bytes = null;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: bytes == null
                ? const Center(
                    child:
                        Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                  )
                : Image.memory(bytes, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    foto.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar foto',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.guindo, size: 20),
                  onPressed: () => _confirmarBorrado(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarBorrado(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: Text('¿Quitar «${foto.titulo}» de la galería?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.guindo),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) store.eliminarFoto(foto.id);
  }
}

// ---------------------------------------------------------------------------
// Secciones CRUD conectadas al backend FastAPI (viajes, asignaciones, ubicaciones)
// ---------------------------------------------------------------------------

String _fmtId(dynamic v) => v == null ? '' : '$v';

String _apiSubtitulo(Map<String, dynamic> m, List<String> campos) {
  final partes = <String>[];
  for (final c in campos) {
    final v = m[c];
    if (v == null) continue;
    final s = '$v'.trim();
    if (s.isEmpty || s == 'null') continue;
    partes.add('$c: $s');
  }
  return partes.join(' · ');
}

dynamic _parseValor(String clave, String valor, Map<String, dynamic> original) {
  if (valor.trim().isEmpty) return null;
  final o = original[clave];
  if (o is int) return int.tryParse(valor) ?? valor;
  if (o is double) return double.tryParse(valor) ?? valor;
  if (o is num) return num.tryParse(valor) ?? valor;
  // ids comunes
  if (clave.endsWith('_id') || clave == 'id' || clave == 'capacidad') {
    final n = int.tryParse(valor);
    if (n != null) return n;
  }
  if (clave == 'latitud' || clave == 'longitud' || clave == 'velocidad') {
    final n = double.tryParse(valor);
    if (n != null) return n;
  }
  return valor;
}

Map<String, String> _inicialesDe(Map<String, dynamic> item, List<String> claves) {
  final out = <String, String>{};
  for (final k in claves) {
    final v = item[k];
    if (v != null && '$v' != 'null') out[k] = '$v';
  }
  return out;
}

class _ApiCrudSection extends StatefulWidget {
  const _ApiCrudSection({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.path,
    required this.listKey,
    required this.hintBusqueda,
    required this.etiquetaNuevo,
    required this.campos,
    required this.camposResumen,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final String path;
  final String listKey;
  final String hintBusqueda;
  final String etiquetaNuevo;
  final List<CampoForm> campos;
  final List<String> camposResumen;

  @override
  State<_ApiCrudSection> createState() => _ApiCrudSectionState();
}

class _ApiCrudSectionState extends State<_ApiCrudSection> {
  final TextEditingController _busqueda = TextEditingController();
  String _consulta = '';
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiCrudService.listar(widget.path, listKey: widget.listKey);
      if (!mounted) return;
      setState(() {
        _items = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _consulta.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((m) => m.values.any((v) => '$v'.toLowerCase().contains(q))).toList();
  }

  Future<void> _nuevo() async {
    final claves = widget.campos.map((c) => c.clave).toList();
    final valores = await mostrarFormulario(
      context: context,
      titulo: widget.etiquetaNuevo,
      icono: widget.icono,
      campos: widget.campos,
    );
    if (valores == null || !mounted) return;
    final body = <String, dynamic>{};
    for (final k in claves) {
      final v = valores[k];
      if (v == null) continue;
      if (v.trim().isEmpty) continue; // omitir vacíos para no enviar nulls innecesarios
      body[k] = _parseValor(k, v, const {});
    }
    try {
      await ApiCrudService.crear(widget.path, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.titulo}: registro creado')),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear: $e')),
      );
    }
  }

  Future<void> _editar(Map<String, dynamic> item) async {
    final id = item['id'] ?? item.values.first;
    final claves = widget.campos.map((c) => c.clave).toList();
    final valores = await mostrarFormulario(
      context: context,
      titulo: 'Editar ${widget.titulo.toLowerCase()}',
      icono: widget.icono,
      campos: widget.campos,
      iniciales: _inicialesDe(item, claves),
    );
    if (valores == null || !mounted) return;
    final body = <String, dynamic>{};
    for (final k in claves) {
      final v = valores[k];
      if (v == null) continue;
      if (v.trim().isEmpty) {
        body[k] = null;
      } else {
        body[k] = _parseValor(k, v, item);
      }
    }
    try {
      await ApiCrudService.actualizar('${widget.path}/${_fmtId(id)}', body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.titulo}: registro actualizado')),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    }
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final id = item['id'] ?? item.values.first;
    final ok = await confirmarEliminacion(
      context,
      titulo: 'Eliminar registro',
      detalle: '¿Eliminar el registro #${_fmtId(id)} de ${widget.titulo}? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      await ApiCrudService.eliminar('${widget.path}/${_fmtId(id)}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.titulo}: registro eliminado')),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hintText: widget.hintBusqueda,
                controller: _busqueda,
                onChanged: (v) => setState(() => _consulta = v),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _nuevo,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(widget.etiquetaNuevo),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.guindo,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitulo,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: '${visibles.length} registros',
              color: AppColors.navy,
              icon: widget.icono,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Recargar desde API',
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SectionCard(
            title: 'No se pudo conectar con el backend',
            subtitle: 'Verifica que la API esté corriendo y que la BD esté disponible.',
            icon: Icons.cloud_off_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.guindo),
                ),
                const SizedBox(height: 10),
                Text(
                  'API: ${ApiCrudService.baseUrl}${widget.path}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Sin registros. Crea uno nuevo para probar el formulario.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...visibles.map(_tarjeta),
      ],
    );
  }

  Widget _tarjeta(Map<String, dynamic> item) {
    final id = _fmtId(item['id'] ?? item.values.firstOrNull ?? '');
    final titulo = item['nombre'] ?? item['nombres'] ?? item['titulo'] ?? 'Registro #$id';
    final subtitulo = _apiSubtitulo(item, widget.camposResumen);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.navy.withValues(alpha: 0.10),
              child: Text(
                id.isEmpty ? '?' : id,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$titulo  (id: $id)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo.isEmpty ? '—' : subtitulo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 19),
              color: AppColors.textSecondary,
              onPressed: () => _editar(item),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.guindo,
              onPressed: () => _eliminar(item),
            ),
          ],
        ),
      ),
    );
  }
}

/// CRUD de Viajes (backend /viajes).
class AdminViajesSection extends StatelessWidget {
  const AdminViajesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ApiCrudSection(
      titulo: 'Viajes',
      subtitulo: 'Programación y control de viajes (conectado a la API).',
      icono: Icons.alt_route_rounded,
      path: '/viajes',
      listKey: 'viajes',
      hintBusqueda: 'Buscar viaje por ruta, vehículo, conductor, estado...',
      etiquetaNuevo: 'Nuevo viaje',
      camposResumen: ['ruta_id', 'vehiculo_id', 'conductor_id', 'fecha', 'hora_salida', 'hora_llegada', 'estado'],
      campos: [
        CampoForm(clave: 'ruta_id', etiqueta: 'ID de ruta', icono: Icons.map_outlined, tipo: TipoCampo.numero, obligatorio: false),
        CampoForm(clave: 'vehiculo_id', etiqueta: 'ID de vehículo', icono: Icons.directions_bus_outlined, tipo: TipoCampo.numero, obligatorio: false),
        CampoForm(clave: 'conductor_id', etiqueta: 'ID de conductor', icono: Icons.badge_outlined, tipo: TipoCampo.numero, obligatorio: false),
        CampoForm(clave: 'fecha', etiqueta: 'Fecha (YYYY-MM-DD)', icono: Icons.event_outlined, obligatorio: false),
        CampoForm(clave: 'hora_salida', etiqueta: 'Hora salida (HH:MM:SS)', icono: Icons.schedule_rounded, obligatorio: false),
        CampoForm(clave: 'hora_llegada', etiqueta: 'Hora llegada (HH:MM:SS)', icono: Icons.schedule_rounded, obligatorio: false),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.flag_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['Programado', 'En curso', 'Finalizado', 'Cancelado'],
        ),
      ],
    );
  }
}

/// CRUD de Asignaciones (backend /asignaciones).
class AdminAsignacionesSection extends StatelessWidget {
  const AdminAsignacionesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ApiCrudSection(
      titulo: 'Asignaciones',
      subtitulo: 'Asignación de estudiantes a rutas/paradas (conectado a la API).',
      icono: Icons.assignment_ind_outlined,
      path: '/asignaciones',
      listKey: 'asignaciones',
      hintBusqueda: 'Buscar por estudiante, ruta, parada, estado...',
      etiquetaNuevo: 'Nueva asignación',
      camposResumen: ['estudiante_id', 'ruta_id', 'parada', 'estado'],
      campos: [
        CampoForm(clave: 'estudiante_id', etiqueta: 'ID de estudiante', icono: Icons.school_outlined, tipo: TipoCampo.numero),
        CampoForm(clave: 'ruta_id', etiqueta: 'ID de ruta', icono: Icons.map_outlined, tipo: TipoCampo.numero),
        CampoForm(clave: 'parada', etiqueta: 'Parada', icono: Icons.location_on_outlined, obligatorio: false),
        CampoForm(
          clave: 'estado',
          etiqueta: 'Estado',
          icono: Icons.flag_outlined,
          tipo: TipoCampo.opciones,
          opciones: ['Activa', 'Inactiva'],
        ),
      ],
    );
  }
}

/// CRUD de Ubicaciones GPS (backend /ubicaciones). Dispositivo físico puede esperar.
class AdminUbicacionesSection extends StatelessWidget {
  const AdminUbicacionesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ApiCrudSection(
      titulo: 'Ubicaciones (GPS)',
      subtitulo: 'Registro de posiciones GPS (listo para uso; dispositivo físico puede esperar).',
      icono: Icons.my_location_rounded,
      path: '/ubicaciones',
      listKey: 'ubicaciones',
      hintBusqueda: 'Buscar por viaje, latitud, longitud...',
      etiquetaNuevo: 'Nueva ubicación',
      camposResumen: ['viaje_id', 'latitud', 'longitud', 'velocidad', 'fecha_hora'],
      campos: [
        CampoForm(clave: 'viaje_id', etiqueta: 'ID de viaje (opcional)', icono: Icons.alt_route_rounded, tipo: TipoCampo.numero, obligatorio: false),
        CampoForm(clave: 'latitud', etiqueta: 'Latitud (ej. -16.5)', icono: Icons.place_outlined, tipo: TipoCampo.numero),
        CampoForm(clave: 'longitud', etiqueta: 'Longitud (ej. -68.15)', icono: Icons.place_outlined, tipo: TipoCampo.numero),
        CampoForm(clave: 'velocidad', etiqueta: 'Velocidad (opcional)', icono: Icons.speed_rounded, tipo: TipoCampo.numero, obligatorio: false),
        CampoForm(clave: 'fecha_hora', etiqueta: 'Fecha y hora (YYYY-MM-DDTHH:MM:SS, opcional)', icono: Icons.schedule_rounded, obligatorio: false),
      ],
    );
  }
}



