// Genera el icono cuadrado de la app (1024x1024) para flutter_launcher_icons.
//
// Uso:  dart run tools/crear_icono.dart
//
// Recorta al centro la foto del bus escolar, le aplica un tinte azul
// institucional (#0F172A) y guarda assets/icon/app_icon.png.
import 'dart:io';

import 'package:image/image.dart' as img;

const String origen = 'assets/images/bus-coaster-escolar.jpg';
const String destino = 'assets/icon/app_icon.png';
const int lado = 1024;

void main() {
  final bytes = File(origen).readAsBytesSync();
  final foto = img.decodeImage(bytes);
  if (foto == null) {
    stderr.writeln('No se pudo decodificar $origen');
    exitCode = 1;
    return;
  }

  // Recorte central al cuadrado más grande posible.
  final ladoMenor = foto.width < foto.height ? foto.width : foto.height;
  final cuadrado = img.copyCrop(
    foto,
    x: (foto.width - ladoMenor) ~/ 2,
    y: (foto.height - ladoMenor) ~/ 2,
    width: ladoMenor,
    height: ladoMenor,
  );

  // Escala al tamaño final del icono.
  final escalada = img.copyResize(cuadrado, width: lado, height: lado);

  // Tinte institucional: mezcla con azul marino para coherencia de marca.
  const int tr = 15, tg = 23, tb = 42; // #0F172A
  final resultado = img.Image.from(escalada);
  for (final p in resultado) {
    p.r = (p.r * 0.72 + tr * 0.28).round().clamp(0, 255);
    p.g = (p.g * 0.72 + tg * 0.28).round().clamp(0, 255);
    p.b = (p.b * 0.72 + tb * 0.28).round().clamp(0, 255);
  }

  Directory('assets/icon').createSync(recursive: true);
  File(destino).writeAsBytesSync(img.encodePng(resultado));
  stdout.writeln('Icono generado: $destino (${lado}x$lado)');
}
