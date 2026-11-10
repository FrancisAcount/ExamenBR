import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../models/safety_alert.dart';
import '../theme/app_colors.dart';
import 'admin/admin_form.dart';
import 'welcome/welcome_benefits.dart';
import 'welcome/welcome_footer.dart';
import 'welcome/welcome_gallery.dart';
import 'welcome/welcome_header.dart';
import 'welcome/welcome_hero.dart';
import 'welcome/welcome_metrics_routes.dart';
import 'welcome/welcome_services.dart';
import 'welcome/welcome_tables.dart';

/// Bienvenida: portada institucional integrada en el panel lateral.
///
/// Se muestra como módulo 0 del listado de `HomeScreen`, con el sidebar azul
/// visible a la izquierda. Desde aquí, «Iniciar Sesión» devuelve al usuario al
/// Panel de Inicio mediante [onIniciarSesion].
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, this.onIniciarSesion, this.onVerRutas});

  /// Callback invocado por «Iniciar Sesión» para volver al Panel de Inicio.
  final VoidCallback? onIniciarSesion;

  /// Callback para abrir el módulo de Rutas y Monitoreo.
  final VoidCallback? onVerRutas;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  /// Consulta del buscador del header.
  final TextEditingController _buscador = TextEditingController();

  /// Identificador de la sección de rutas, para desplazar el scroll hasta ella.
  final GlobalKey _anclaRutas = GlobalKey();

  /// Texto actual del buscador.
  String _consulta = '';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  /// Abre el módulo real de Rutas y Monitoreo (o hace scroll como respaldo).
  void _irARutas() {
    if (widget.onVerRutas != null) {
      widget.onVerRutas!.call();
      return;
    }
    final contexto = _anclaRutas.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _solicitarTransporte() async {
    final store = AdminStore.instance;
    final valores = await mostrarFormulario(
      context: context,
      titulo: 'Solicitar transporte',
      icono: Icons.directions_bus_rounded,
      campos: const [
        CampoForm(clave: 'estudiante', etiqueta: 'Nombre del estudiante', icono: Icons.school_outlined),
        CampoForm(clave: 'tutor', etiqueta: 'Nombre del tutor/representante', icono: Icons.person_outline_rounded),
        CampoForm(clave: 'telefono', etiqueta: 'Teléfono de contacto', icono: Icons.phone_rounded),
        CampoForm(clave: 'direccion', etiqueta: 'Dirección / parada solicitada', icono: Icons.location_on_outlined),
        CampoForm(clave: 'ruta', etiqueta: 'Ruta o zona de interés', icono: Icons.map_outlined),
        CampoForm(clave: 'turno', etiqueta: 'Turno', icono: Icons.schedule_rounded, tipo: TipoCampo.opciones, opciones: ['Mañana', 'Tarde', 'Mañana y Tarde']),
        CampoForm(clave: 'detalle', etiqueta: 'Detalle adicional (opcional)', icono: Icons.notes_rounded, obligatorio: false, lineas: 3),
      ],
    );
    if (valores == null || !mounted) return;
    final detalle = [
      'Estudiante: ${valores['estudiante']}',
      'Tutor: ${valores['tutor']}',
      'Tel: ${valores['telefono']}',
      'Dirección: ${valores['direccion']}',
      'Ruta: ${valores['ruta']}',
      'Turno: ${valores['turno']}',
      if ((valores['detalle'] ?? '').trim().isNotEmpty) 'Detalle: ${valores['detalle']}',
    ].join(' · ');
    store.agregarAlerta(SafetyAlert(
      id: store.nuevoId('ALT', store.alertas.map((a) => a.id)),
      hora: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      titulo: 'Solicitud de transporte: ${valores['estudiante']}',
      detalle: detalle,
      nivel: AlertLevel.info,
      ruta: valores['ruta'] ?? '',
      respondido: false,
    ));
    if (!mounted) return;
    _aviso('Solicitud registrada correctamente. El equipo la revisará pronto.');
  }

  /// Aviso uniforme para las acciones simuladas de la portada.
  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.background,
      // Un solo scroll vertical para toda la portada.
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header compacto con buscador.
            WelcomeHeader(
              controller: _buscador,
              onQueryChanged: (valor) => setState(() => _consulta = valor),
              onVerRutas: _irARutas,
              onIniciarSesion: () => widget.onIniciarSesion?.call(),
            ),

            // 2. Banner de bienvenida dividido.
            WelcomeHero(
              onVerRutas: _irARutas,
              onSolicitar: _solicitarTransporte,
            ),

            // 3. Servicios: tarjeta azul + dos tarjetas blancas.
            WelcomeServices(
              onVerRutas: _irARutas,
              onSolicitar: _solicitarTransporte,
            ),

            // 4. Carrusel horizontal de beneficios.
            const WelcomeBenefitsCarousel(),

            // 5. Métricas clave + tarjetas de las rutas principales.
            WelcomeMetricsRoutes(
              key: _anclaRutas,
              consulta: _consulta,
              onLimpiarConsulta: () {
                _buscador.clear();
                setState(() => _consulta = '');
              },
              onVerRuta: (ruta) => _aviso('${ruta.name} · detalle de ruta simulado'),
            ),

            // 6. Tablas de horarios, avisos y estado del servicio.
            const WelcomeTablesSection(),

            // 7. Galería de la flota y objetivos del proyecto.
            const WelcomeGallerySection(),

            // 8. Pie institucional con suscripción.
            WelcomeFooter(
              onSuscribirse: (correo) => _aviso('¡Gracias! Enviamos las novedades a $correo'),
            ),

            // Cierre visual de la página.
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
