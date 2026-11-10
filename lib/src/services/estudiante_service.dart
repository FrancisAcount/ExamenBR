
import 'dart:convert';

import 'package:http/http.dart' as http;

class EstudianteApi {
  final int id;
  final String nombres;
  final String apellidos;
  final String curso;
  final String direccion;
  final String estado;
  final String nombreTutor;
  final String telefonoTutor;

  const EstudianteApi({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.curso,
    required this.direccion,
    required this.estado,
    required this.nombreTutor,
    required this.telefonoTutor,
  });

  factory EstudianteApi.fromJson(Map<String, dynamic> json) {
    return EstudianteApi(
      id: int.parse('${json['id']}'),
      nombres: '${json['nombres'] ?? ''}',
      apellidos: '${json['apellidos'] ?? ''}',
      curso: '${json['curso'] ?? ''}',
      direccion: '${json['direccion'] ?? ''}',
      estado: '${json['estado'] ?? ''}',
      nombreTutor: '${json['nombre_tutor'] ?? ''}',
      telefonoTutor: '${json['telefono_tutor'] ?? ''}',
    );
  }
}

class EstudianteService {
  /// URL base de la API de estudiantes.
  ///
  /// Se puede sobrescribir en tiempo de compilación sin tocar código:
  /// `flutter run --dart-define=API_ESTUDIANTES=http://192.168.1.5:8000`
  /// (útil para probar desde un celular contra el backend de la PC).
  /// Por defecto apunta al servidor local de `backend/`.
  static const String baseUrl = String.fromEnvironment(
    'API_ESTUDIANTES',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Future<List<EstudianteApi>> listar() async {
    final respuesta = await http
        .get(Uri.parse('$baseUrl/estudiantes'))
        .timeout(const Duration(seconds: 15));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al consultar estudiantes: ${respuesta.statusCode}',
      );
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['estudiantes'] as List<dynamic>;

    return lista
        .map(
          (elemento) => EstudianteApi.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          ),
        )
        .toList();
  }
}
