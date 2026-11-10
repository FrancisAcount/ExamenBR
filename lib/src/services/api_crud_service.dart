import 'dart:convert';

import 'package:http/http.dart' as http;

/// Servicio HTTP genérico para consumir los CRUDs del backend FastAPI.
///
/// Base URL configurable con `--dart-define=API_BASE_URL=http://HOST:8000`.
/// Por defecto apunta al backend local.
class ApiCrudService {
  ApiCrudService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'API_ESTUDIANTES',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Exception _error(http.Response r, String accion) {
    String detalle = 'HTTP ${r.statusCode}';
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['detail'] != null) {
        detalle = '${body['detail']}';
      } else if (r.body.isNotEmpty) {
        detalle = r.body;
      }
    } catch (_) {
      if (r.body.isNotEmpty) detalle = r.body;
    }
    return Exception('$accion: $detalle');
  }

  /// Lista registros. Soporta respuestas `{claveLista:[...]}` o `[...]`.
  static Future<List<Map<String, dynamic>>> listar(
    String path, {
    String? listKey,
  }) async {
    final r = await http.get(_uri(path)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw _error(r, 'Error al listar $path');
    final data = jsonDecode(r.body);
    List<dynamic> lista;
    if (data is List) {
      lista = data;
    } else if (data is Map<String, dynamic>) {
      if (listKey != null && data[listKey] is List) {
        lista = data[listKey] as List<dynamic>;
      } else {
        // tomar la primera lista encontrada
        final found = data.values.firstWhere(
          (v) => v is List,
          orElse: () => const <dynamic>[],
        );
        lista = found is List ? found : const <dynamic>[];
      }
    } else {
      lista = const <dynamic>[];
    }
    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<Map<String, dynamic>> obtener(String path) async {
    final r = await http.get(_uri(path)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw _error(r, 'Error al obtener $path');
    final data = jsonDecode(r.body);
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  static Future<Map<String, dynamic>> crear(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await http
        .post(
          _uri(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw _error(r, 'Error al crear en $path');
    }
    final data = jsonDecode(r.body);
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  static Future<Map<String, dynamic>> actualizar(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await http
        .put(
          _uri(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw _error(r, 'Error al actualizar $path');
    final data = jsonDecode(r.body);
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  static Future<void> eliminar(String path) async {
    final r = await http.delete(_uri(path)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw _error(r, 'Error al eliminar $path');
    }
  }
}
