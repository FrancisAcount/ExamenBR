// Copyright 2026 Transporte Escolar Maranata.
// Formulario genérico del panel administrativo.
//
// Un mismo diálogo construye el alta y la edición de alumnos, conductores,
// buses, rutas y alertas a partir de una lista de [CampoForm].
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tipos de campo soportados por el formulario del panel.
enum TipoCampo { texto, numero, opciones, interruptor }

/// Definición de un campo del formulario de alta/edición.
class CampoForm {
  const CampoForm({
    required this.clave,
    required this.etiqueta,
    this.icono,
    this.inicial,
    this.obligatorio = true,
    this.tipo = TipoCampo.texto,
    this.opciones = const <String>[],
    this.lineas = 1,
  });

  final String clave;
  final String etiqueta;
  final IconData? icono;
  final String? inicial;
  final bool obligatorio;
  final TipoCampo tipo;
  final List<String> opciones;
  final int lineas;
}

/// Muestra el diálogo de alta/edición y devuelve `clave → valor` o `null`
/// si el usuario cancela.
Future<Map<String, String>?> mostrarFormulario({
  required BuildContext context,
  required String titulo,
  required IconData icono,
  required List<CampoForm> campos,
  Map<String, String>? iniciales,
  String textoGuardar = 'Guardar',
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _DialogoFormulario(
      titulo: titulo,
      icono: icono,
      campos: campos,
      iniciales: iniciales ?? const <String, String>{},
      textoGuardar: textoGuardar,
    ),
  );
}

/// Confirma una eliminación con botón rojo; devuelve true si se confirma.
Future<bool> confirmarEliminacion(
  BuildContext context, {
  required String titulo,
  required String detalle,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.guindo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.guindo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: Text(detalle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.guindo),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _DialogoFormulario extends StatefulWidget {
  const _DialogoFormulario({
    required this.titulo,
    required this.icono,
    required this.campos,
    required this.iniciales,
    required this.textoGuardar,
  });

  final String titulo;
  final IconData icono;
  final List<CampoForm> campos;
  final Map<String, String> iniciales;
  final String textoGuardar;

  @override
  State<_DialogoFormulario> createState() => _DialogoFormularioState();
}

class _DialogoFormularioState extends State<_DialogoFormulario> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _textos;
  late final Map<String, String?> _opciones;
  late final Map<String, bool> _interruptores;

  @override
  void initState() {
    super.initState();
    _textos = {};
    _opciones = {};
    _interruptores = {};
    for (final c in widget.campos) {
      final inicial = widget.iniciales[c.clave] ?? c.inicial ?? '';
      switch (c.tipo) {
        case TipoCampo.opciones:
          _opciones[c.clave] =
              c.opciones.contains(inicial) ? inicial : c.opciones.firstOrNull;
          break;
        case TipoCampo.interruptor:
          _interruptores[c.clave] = inicial.toLowerCase() == 'true';
          break;
        case TipoCampo.texto:
        case TipoCampo.numero:
          _textos[c.clave] = TextEditingController(text: inicial);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textos.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final valores = <String, String>{};
    for (final c in widget.campos) {
      switch (c.tipo) {
        case TipoCampo.opciones:
          valores[c.clave] = _opciones[c.clave] ?? '';
          break;
        case TipoCampo.interruptor:
          valores[c.clave] = '${_interruptores[c.clave] ?? false}';
          break;
        case TipoCampo.texto:
        case TipoCampo.numero:
          valores[c.clave] = _textos[c.clave]!.text.trim();
      }
    }
    Navigator.of(context).pop(valores);
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _encabezado(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Form(key: _formKey, child: _campos()),
              ),
            ),
            _acciones(),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        decoration: const BoxDecoration(
          color: AppColors.guindo,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icono, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _campos() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.campos.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _campo(widget.campos[i]),
          ],
        ],
      );

  Widget _campo(CampoForm c) {
    switch (c.tipo) {
      case TipoCampo.opciones:
        return DropdownButtonFormField<String>(
          initialValue: _opciones[c.clave],
          decoration: _decoracion(c),
          items: [
            for (final o in c.opciones)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => setState(() => _opciones[c.clave] = v),
          validator: (v) => c.obligatorio && (v == null || v.isEmpty)
              ? 'Elige una opción'
              : null,
        );
      case TipoCampo.interruptor:
        return SwitchListTile(
          value: _interruptores[c.clave] ?? false,
          onChanged: (v) => setState(() => _interruptores[c.clave] = v),
          title: Text(c.etiqueta, style: const TextStyle(fontSize: 13.5)),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.guindo,
        );
      case TipoCampo.texto:
      case TipoCampo.numero:
        return TextFormField(
          controller: _textos[c.clave],
          keyboardType:
              c.tipo == TipoCampo.numero ? TextInputType.number : null,
          maxLines: c.lineas,
          style: const TextStyle(fontSize: 13.5),
          decoration: _decoracion(c),
          validator: (v) {
            if (!c.obligatorio) return null;
            if (v == null || v.trim().isEmpty) {
              return 'Este campo es obligatorio';
            }
            if (c.tipo == TipoCampo.numero && num.tryParse(v.trim()) == null) {
              return 'Ingresa un número válido';
            }
            return null;
          },
        );
    }
  }

  InputDecoration _decoracion(CampoForm c) => InputDecoration(
        labelText: c.etiqueta,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: c.icono == null
            ? null
            : Icon(c.icono, size: 18, color: AppColors.textSecondary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.guindo, width: 1.4),
        ),
      );

  Widget _acciones() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.guindo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(widget.textoGuardar),
              ),
            ),
          ],
        ),
      );
}


