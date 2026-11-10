import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../widgets/common_widgets.dart';
import 'admin/admin_panel_view.dart';

/// ⚙️ Apartado 7: ajustes generales del sistema y perfil de usuario.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Estado local de los interruptores (simula la persistencia).
  bool _notificacionesPush = true;
  bool _alertasCriticas = true;
  bool _modoMantenimiento = false;
  double _capacidadMinima = 50;

  /// Referencia rápida a la configuración global.
  final AppSettings _settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 900;
          final perfil = _buildProfileCard();
          final general = _buildGeneralCard();
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: perfil), const SizedBox(width: 16), Expanded(child: general)])
              : Column(children: [perfil, const SizedBox(height: 16), general]);
        }),
        const SizedBox(height: 16),
        _buildAdminCard(),
        const SizedBox(height: 16),
        _buildAboutCard(),
      ],
    );
  }

  /// Tarjeta de perfil del coordinador.
  Widget _buildProfileCard() {
    return SectionCard(
      title: 'Perfil del usuario',
      subtitle: 'Datos de la cuenta administrativa',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.guindo,
                child: Text('CM', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Coordinador Maranata', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('coordinacion@maranata.edu.ec', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.textMuted)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _toast('Edición de perfil'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _field('Nombre completo', 'Coordinador Maranata'),
          const SizedBox(height: 12),
          _field('Correo institucional', 'coordinacion@maranata.edu.ec'),
          const SizedBox(height: 12),
          _field('Teléfono', '+593 99 000 0000'),
        ],
      ),
    );
  }
  /// Tarjeta de ajustes generales (preferencias).
  Widget _buildGeneralCard() {
    return SectionCard(
      title: 'Ajustes generales',
      subtitle: 'Preferencias del sistema',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          _switch('Notificaciones push', 'Recibir avisos en el dispositivo', _notificacionesPush, (v) => setState(() => _notificacionesPush = v)),
          const Divider(height: 24),
          _switch('Alertas críticas', 'Avisar incidentemente de seguridad', _alertasCriticas, (v) => setState(() => _alertasCriticas = v)),
          const Divider(height: 24),
          _switch('Modo mantenimiento', 'Bloquear despacho de rutas', _modoMantenimiento, (v) => setState(() => _modoMantenimiento = v)),
          const Divider(height: 24),

          // —— NUEVO: Modo oscuro ——
          _switch('Modo oscuro', 'Cambia la app y el mapa a colores oscuros', _settings.isDarkMode, (v) {
            setState(() {});
            _settings.isDarkMode = v;
          }),
          const Divider(height: 24),

          // —— NUEVO: Alertas de proximidad ——
          _switch(
            'Alertas de proximidad',
            'Notifica al padre cuando el bus se acerque a la parada',
            _settings.proximityAlerts,
            (v) {
              setState(() {});
              _settings.proximityAlerts = v;
            },
          ),
          const Divider(height: 24),

          // —— NUEVO: Frecuencia de actualización ——
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frecuencia de actualización del mapa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Cada cuántos segundos se refresca la posición del bus',
                style: TextStyle(fontSize: 11.5, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _settings.updateFrequencySeconds,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 segundos')),
                    DropdownMenuItem(value: 10, child: Text('10 segundos')),
                    DropdownMenuItem(value: 30, child: Text('30 segundos')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {});
                      _settings.updateFrequencySeconds = v;
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Capacidad mínima de aforo (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text('${_capacidadMinima.round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.guindo)),
                ],
              ),
              Slider(
                value: _capacidadMinima,
                min: 0,
                max: 100,
                activeColor: AppColors.guindo,
                onChanged: (v) => setState(() => _capacidadMinima = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _toast('Configuración guardada correctamente'),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta roja de acceso al panel administrativo (con PIN).
  Widget _buildAdminCard() {
    return SectionCard(
      title: 'Panel administrativo',
      subtitle: 'Gestión de matrícula, flota, rutas y alertas',
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.guindo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.guindo.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.guindo,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zona restringida: se pedirá el PIN de administrador '
                    'para entrar.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.guindo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _abrirPanel,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.guindo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shield_rounded, size: 19),
              label: const Text('Abrir panel administrativo'),
            ),
          ),
        ],
      ),
    );
  }

  /// Pide el PIN y, si es correcto, abre el panel administrativo.
  Future<void> _abrirPanel() async {
    final store = AdminStore.instance;
    if (!store.sesionAdmin) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _DialogoPin(store: store),
      );
      if (ok != true || !mounted) return;
      store.sesionAdmin = true;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminPanelView()),
    );
  }

  /// Tarjeta de información del sistema.
  Widget _buildAboutCard() {
    return const SectionCard(
      title: 'Información del sistema',
      subtitle: 'Detalles de la plataforma',
      icon: Icons.info_outline_rounded,
      child: Wrap(
        spacing: 40,
        runSpacing: 12,
        children: [
          _Info(label: 'Versión', value: '1.0.0'),
          _Info(label: 'Entorno', value: 'Producción (demo)'),
          _Info(label: 'Última sincronización', value: 'Hoy, 14:30'),
          _Info(label: 'Módulos activos', value: '7 de 7'),
        ],
      ),
    );
  }

  /// Campo de texto de solo lectura (estilizado).
  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(initialValue: value, decoration: const InputDecoration(isDense: true)),
      ],
    );
  }

  /// Fila con interruptor y descripción.
  Widget _switch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(fontSize: 11.5, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.textMuted)),
            ],
          ),
        ),
        Switch(value: value, activeThumbColor: AppColors.guindo, onChanged: onChanged),
      ],
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Diálogo que pide el PIN de administrador antes de abrir el panel.
class _DialogoPin extends StatefulWidget {
  const _DialogoPin({required this.store});

  final AdminStore store;

  @override
  State<_DialogoPin> createState() => _DialogoPinState();
}

class _DialogoPinState extends State<_DialogoPin> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _validar() {
    if (_pin.text.trim() == widget.store.pin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'PIN incorrecto, inténtalo de nuevo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.guindo),
          SizedBox(width: 10),
          Expanded(child: Text('Acceso restringido')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresa el PIN de administrador para abrir el panel '
            '(PIN inicial: 2580).',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            autofocus: true,
            onSubmitted: (_) => _validar(),
            decoration: InputDecoration(
              labelText: 'PIN de administrador',
              prefixIcon: const Icon(Icons.key_rounded),
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _validar,
          style: FilledButton.styleFrom(backgroundColor: AppColors.guindo),
          child: const Text('Entrar al panel'),
        ),
      ],
    );
  }
}

/// Dato informativo estático.
class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
