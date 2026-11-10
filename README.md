# Transporte Escolar Maranata 🚌

Sistema de gestión de transporte escolar (**Web + APK Android**) construido con Flutter.
Interfaz institucional: sidebar azul oscuro, contenido claro y acentos guindo/carmesí.

## Estructura de carpetas

```text
lib/
├── main.dart                      # Punto de entrada + MaterialApp + Firebase
├── firebase_options.dart          # Credenciales Firebase (proyecto trasporte-maranata)
└── src/
    ├── theme/
    │   ├── app_colors.dart        # Paleta institucional (claro/oscuro)
    │   ├── app_settings.dart      # Ajustes globales (modo oscuro, alertas, frecuencia)
    │   └── app_theme.dart         # ThemeData global
    ├── models/                    # bus, driver, student, route, live_bus, alertas…
    ├── data/
    │   ├── admin_store.dart       # Padrón vivo (singleton): conductores, estudiantes, galería
    │   ├── driver_data.dart       # Semilla de 28 unidades + placas
    │   ├── student_data.dart      # Semilla de estudiantes (grados, paradas)
    │   └── mock_data.dart         # Datos simulados de rutas/alertas
    ├── services/
    │   ├── live_bus_service.dart  # GPS → Firebase Realtime DB (buses_en_vivo/BUS-XX)
    │   └── estudiante_service.dart # Cliente HTTP del backend FastAPI
    ├── widgets/                   # sidebar, tarjetas comunes, tablas, mapa pintado
    ├── screens/
    │   └── home_screen.dart       # Shell: sidebar + cabecera + vista activa
    └── views/
        ├── welcome/               # Portada pública (7 bloques)
        ├── admin/                 # Panel administrativo con PIN (matrícula, flota…)
        ├── dashboard_view.dart    # 🏠 Panel de Inicio
        ├── monitoring_view.dart   # 🗺️ Rutas y Monitoreo (mapa OpenStreetMap)
        ├── fleet_view.dart        # 🚌 Gestión de Flota
        ├── drivers_view.dart      # 👨‍✈️ Conductores y Personal
        ├── students_view.dart     # 🧒 Registro de Estudiantes (28 unidades)
        ├── alerts_view.dart       # 🚨 Alertas y Seguridad
        ├── gallery_view.dart     # 🖼️ Galería de la flota
        ├── driver_mode_view.dart  # 🚍 Modo Conductor (GPS real del celular)
        └── settings_view.dart     # ⚙️ Configuración

backend/                           # API FastAPI + MySQL (opcional, ver su README)
tools/                            # crear_icono.dart, descargar_fotos.ps1
```

## Paleta

| Uso                | Color                    |
|--------------------|--------------------------|
| Sidebar            | `#0F172A` (azul oscuro)  |
| Fondo de pantalla  | `#F8FAFC` (gris claro)   |
| Acentos / alertas  | `#991B1B` (guindo)       |
| Texto principal    | `#0F172A`                |
| Texto secundario   | `#475569`                |

## Puesta en marcha

Las carpetas de plataforma (`android/`, `web/`) ya están generadas, incluidos
los scripts de Gradle (`gradlew`), así que solo necesitas dependencias:

```bash
# 1) Instalar dependencias
flutter pub get

# 2) Ejecutar
flutter run -d chrome     # Web
flutter run               # Android (requiere SDK de Android + dispositivo/emulador)
flutter build apk --release   # Genera el APK en build/app/outputs/flutter-apk/
```

### Requisitos por plataforma

| Plataforma | Requisito extra |
|------------|-----------------|
| Web        | Chrome instalado (`flutter run -d chrome`) |
| Android    | Android SDK (Android Studio o cmdline-tools). Verifica con `flutter doctor` |
| Windows    | Visual Studio 2022 con «Desktop development with C++» |

### Verificaciones rápidas

```bash
flutter analyze   # 0 problemas
flutter test      # 17 tests de widget
```

## Firma del APK de producción

El release ya está configurado para firmarse con un keystore propio:

- `android/app/maranata-upload.jks` — keystore PKCS12 (vigencia 30 años)
- `android/key.properties` — contraseña y alias (ambos **ignorados por git**)

Si pierdes el keystore o necesitas regenerarlo:

```bash
keytool -genkeypair -v -storetype PKCS12 ^
  -keystore android/app/maranata-upload.jks -alias maranata ^
  -keyalg RSA -keysize 2048 -validity 10950
```

Y crea `android/key.properties` con `storePassword`, `password`,
`keyPassword`, `alias` y `storeFile=maranata-upload.jks`.

> ⚠️ Subir a Google Play un APK firmado con un keystore distinto al ya
> publicado obliga a cambiar el `versionCode` de `pubspec.yaml`.

## Firebase (GPS en vivo del Modo Conductor)

`lib/firebase_options.dart` usa las credenciales web del proyecto
`trasporte-maranata` (Realtime Database). En **web** funciona tal cual.
Para el **APK Android**, `firebase_database` necesita el `appId` nativo de
Android; obténlo ejecutando:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

y reemplazando el bloque `android` de `firebase_options.dart` con el que
genere. Sin eso, la app funciona igual: el GPS del conductor se sigue
mostrando en pantalla, solo que no se publica en Realtime Database.

## Backend (opcional)

La API FastAPI + MySQL vive en [`backend/`](backend/README.md) y alimenta la
lista de estudiantes desde MySQL. La app funciona sin ella (usa el padrón
local), pero si quieres conectarla:

```powershell
cd backend
.venv\Scripts\activate          # el venv ya está creado en esta máquina
uvicorn main:app --reload --port 8000
```

> En esta máquina el MySQL de XAMPP ya corre con la base `maranata_escolar`
> creada; `schema.sql` solo es necesario en un MySQL vacío (y en PowerShell
> se importa con `Get-Content schema.sql | mysql -u root -p`, no con `<`).

## Pruebas

```bash
flutter test      # 17 tests de widget (intro, navegación, módulos, portada)
```

Cada push a `main` en GitHub ejecuta `.github/workflows/ci.yml`:
`flutter analyze` + `flutter test` + `flutter build web`.

## Icono de la app

El icono (bus con tinte institucional) se regenera desde la foto
`assets/images/bus-coaster-escolar.jpg`:

```bash
dart run tools/crear_icono.dart        # genera assets/icon/app_icon.png (1024²)
dart run flutter_launcher_icons        # aplica a Android (mipmap) y Web (icons/)
```

## Notas de arquitectura

- `HomeScreen` es el único que conoce el estado del menú; cada vista es independiente.
- La navegación usa `AnimatedSwitcher` + `KeyedSubtree` para cambiar de módulo sin cortar el diseño.
- Layout responsivo: sidebar fijo en escritorio/web y `Drawer` en móvil (< 900 px).
- El padrón de datos vive en `AdminStore` (singleton `ChangeNotifier`); las
  vistas se reconstruyen en vivo cuando el panel administrativo cambia algo.
- El mapa usa `flutter_map` + OpenStreetMap: **no requiere API key** de Google Maps.
- El Modo Conductor usa el GPS real del celular (`geolocator`) y lo publica
  en Firebase Realtime Database; sin conexión sigue mostrando la posición local.
