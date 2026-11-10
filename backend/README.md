# API de Transporte Escolar Maranata 🐍

Backend FastAPI + MySQL que expone los estudiantes del padrón.
La app Flutter lo consume desde `lib/src/services/estudiante_service.dart`
(`http://127.0.0.1:8000/estudiantes`).

## Puesta en marcha (Windows / PowerShell)

```powershell
# 1) Crea y activa el entorno virtual (ya creado en esta máquina: .venv)
python -m venv .venv
.venv\Scripts\activate

# 2) Instala las dependencias (ya instaladas en esta máquina)
pip install -r requirement.txt

# 3) Levanta la API
uvicorn main:app --reload --port 8000
```

> ⚠️ **Nota importante para PowerShell:** la redirección `<` de bash
> (`mysql -u root -p < schema.sql`) **no existe** en PowerShell y lanza el
> error «El operador '<' está reservado para uso futuro». Usa las
> alternativas de la sección MySQL de abajo.

## MySQL

En esta máquina el servidor es el **MySQL de XAMPP** (servicio `mysqld`,
puerto 3306, usuario `root` sin contraseña) y la base `maranata_escolar`
**ya existe** con 7 tablas (estudiantes, conductores, rutas, vehiculos,
viajes, asignaciones, ubicaciones). En ese caso no hay nada que importar.

Solo si arrancas desde un MySQL vacío, crea la base con `schema.sql`:

```powershell
# PowerShell no soporta '<'; usa el pipe:
Get-Content schema.sql | mysql -u root -p

# …o pásalo por cmd, que sí soporta la redirección clásica:
cmd /c "mysql -u root -p < schema.sql"
```

> `schema.sql` usa `CREATE DATABASE/TABLE IF NOT EXISTS`: no destruye nada
> existente. El `INSERT` añade 8 estudiantes de prueba, así que no lo
> ejecutes sobre una base que ya tenga datos reales.

El cliente `mysql.exe` no está en el PATH de Windows en esta máquina; las
rutas son `C:\xampp\mysql\bin\mysql.exe` y la del Workbench
(`C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe`). Puedes
añadir XAMPP al PATH o llamarlo con la ruta completa.

### Credenciales

Si tu MySQL usa otra contraseña, crea un `.env` (copia de
`.env.example`):

```
DB_USER=root
DB_PASSWORD=tu_contraseña
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=maranata_escolar
```

## Endpoints

La API expone CRUD completo para las entidades del sistema. Documentación interactiva: `http://127.0.0.1:8000/docs`.

| Recurso        | Listar (GET)     | Obtener (GET)          | Crear (POST)     | Actualizar (PUT)       | Eliminar (DELETE)      |
|----------------|------------------|------------------------|------------------|------------------------|------------------------|
| Estudiantes    | `/estudiantes`   | `/estudiantes/{id}`    | `/estudiantes`   | `/estudiantes/{id}`    | `/estudiantes/{id}`    |
| Conductores    | `/conductores`   | `/conductores/{id}`    | `/conductores`   | `/conductores/{id}`    | `/conductores/{id}`    |
| Rutas          | `/rutas`         | `/rutas/{id}`          | `/rutas`         | `/rutas/{id}`          | `/rutas/{id}`          |
| Vehículos      | `/vehiculos`     | `/vehiculos/{id}`      | `/vehiculos`     | `/vehiculos/{id}`      | `/vehiculos/{id}`      |
| Viajes         | `/viajes`        | `/viajes/{id}`         | `/viajes`        | `/viajes/{id}`         | `/viajes/{id}`         |
| Asignaciones   | `/asignaciones`  | `/asignaciones/{id}`   | `/asignaciones`  | `/asignaciones/{id}`   | `/asignaciones/{id}`   |
| Ubicaciones    | `/ubicaciones`   | `/ubicaciones/{id}`    | `/ubicaciones`   | `/ubicaciones/{id}`    | `/ubicaciones/{id}`    |

Utilidad:

| Método | Ruta        | Descripción                                      |
|--------|-------------|--------------------------------------------------|
| GET    | `/`         | Estado de la API                                 |
| GET    | `/health`   | Health check ligero (para monitoreo/Docker)      |
| GET    | `/db-check` | Verifica la conexión y lista las tablas de MySQL |

> **GPS:** el dispositivo físico puede esperar. El CRUD de `/ubicaciones` ya está implementado para registrar/consultar posiciones (manual o desde integración futura).  
> **Compatibilidad Flutter:** `GET /estudiantes` mantiene el formato `{ "total": ..., "estudiantes": [...] }`.

## Notas

- Sin MySQL la app Flutter sigue funcionando: el módulo de Estudiantes usa
  el padrón local de `AdminStore`.
- La URL del backend se puede cambiar al compilar la app sin tocar código:
  `flutter run --dart-define=API_ESTUDIANTES=http://TU_IP:8000`
- Documentación interactiva (Swagger UI): `http://127.0.0.1:8000/docs`.
