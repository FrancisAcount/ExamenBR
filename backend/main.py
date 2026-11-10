from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from crud import create_row, delete_row, get_row, list_rows, update_row
from database import engine, verificar_conexion
from schemas import (
    AsignacionCreate,
    AsignacionUpdate,
    ConductorCreate,
    ConductorUpdate,
    EstudianteCreate,
    EstudianteUpdate,
    RutaCreate,
    RutaUpdate,
    UbicacionCreate,
    UbicacionUpdate,
    VehiculoCreate,
    VehiculoUpdate,
    ViajeCreate,
    ViajeUpdate,
)

app = FastAPI(
    title="API Transporte Escolar Maranata",
    version="1.1.0",
    description="API REST con CRUDs para estudiantes, conductores, rutas, vehículos, viajes, asignaciones y ubicaciones.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:8000",
        "http://localhost:5000",
        "http://localhost:8080",
        "http://localhost:5173",
        "http://localhost:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def inicio():
    return {
        "mensaje": "API de Transporte Escolar Maranata",
        "estado": "activa",
        "version": "1.1.0",
    }


@app.get("/health")
def estado_salud():
    """Health check ligero: solo confirma que el proceso responde."""
    return {"status": "ok"}


@app.get("/db-check")
def comprobar_base_datos():
    try:
        if not verificar_conexion():
            raise HTTPException(status_code=503, detail="MySQL no respondió correctamente")

        with engine.connect() as conexion:
            tablas = conexion.execute(text("SHOW TABLES")).scalars().all()

        return {
            "conexion": "correcta",
            "base_datos": "maranata_escolar",
            "cantidad_tablas": len(tablas),
            "tablas": tablas,
        }

    except SQLAlchemyError:
        raise HTTPException(
            status_code=503,
            detail="No se pudo conectar con MySQL. Revisa el servidor y las credenciales.",
        )


@app.get("/v1/models")
def listar_modelos_compat():
    """Endpoint de compatibilidad para clientes que prueban APIs tipo OpenAI.
    Este backend es de transporte escolar (CRUDs), no expone modelos LLM.
    """
    return {"object": "list", "data": []}


# =========================
# CRUD: Estudiantes
# =========================
@app.get("/estudiantes")
def listar_estudiantes():
    """Lista estudiantes (formato compatible con la app Flutter actual)."""
    estudiantes = list_rows("estudiantes", order_by="apellidos, nombres")
    return {"total": len(estudiantes), "estudiantes": estudiantes}


@app.get("/estudiantes/{estudiante_id}")
def obtener_estudiante(estudiante_id: int):
    return get_row("estudiantes", estudiante_id)


@app.post("/estudiantes", status_code=201)
def crear_estudiante(payload: EstudianteCreate):
    return create_row("estudiantes", payload.model_dump())


@app.put("/estudiantes/{estudiante_id}")
def actualizar_estudiante(estudiante_id: int, payload: EstudianteUpdate):
    return update_row("estudiantes", estudiante_id, payload.model_dump(exclude_unset=True))


@app.delete("/estudiantes/{estudiante_id}")
def eliminar_estudiante(estudiante_id: int):
    return delete_row("estudiantes", estudiante_id)


# =========================
# CRUD: Conductores
# =========================
@app.get("/conductores")
def listar_conductores():
    return {"total": len(list_rows("conductores", "apellidos, nombres")), "conductores": list_rows("conductores", "apellidos, nombres")}


@app.get("/conductores/{conductor_id}")
def obtener_conductor(conductor_id: int):
    return get_row("conductores", conductor_id)


@app.post("/conductores", status_code=201)
def crear_conductor(payload: ConductorCreate):
    return create_row("conductores", payload.model_dump())


@app.put("/conductores/{conductor_id}")
def actualizar_conductor(conductor_id: int, payload: ConductorUpdate):
    return update_row("conductores", conductor_id, payload.model_dump(exclude_unset=True))


@app.delete("/conductores/{conductor_id}")
def eliminar_conductor(conductor_id: int):
    return delete_row("conductores", conductor_id)


# =========================
# CRUD: Rutas
# =========================
@app.get("/rutas")
def listar_rutas():
    return {"total": len(list_rows("rutas", "nombre")), "rutas": list_rows("rutas", "nombre")}


@app.get("/rutas/{ruta_id}")
def obtener_ruta(ruta_id: int):
    return get_row("rutas", ruta_id)


@app.post("/rutas", status_code=201)
def crear_ruta(payload: RutaCreate):
    return create_row("rutas", payload.model_dump())


@app.put("/rutas/{ruta_id}")
def actualizar_ruta(ruta_id: int, payload: RutaUpdate):
    return update_row("rutas", ruta_id, payload.model_dump(exclude_unset=True))


@app.delete("/rutas/{ruta_id}")
def eliminar_ruta(ruta_id: int):
    return delete_row("rutas", ruta_id)


# =========================
# CRUD: Vehículos
# =========================
@app.get("/vehiculos")
def listar_vehiculos():
    return {"total": len(list_rows("vehiculos", "placa")), "vehiculos": list_rows("vehiculos", "placa")}


@app.get("/vehiculos/{vehiculo_id}")
def obtener_vehiculo(vehiculo_id: int):
    return get_row("vehiculos", vehiculo_id)


@app.post("/vehiculos", status_code=201)
def crear_vehiculo(payload: VehiculoCreate):
    return create_row("vehiculos", payload.model_dump())


@app.put("/vehiculos/{vehiculo_id}")
def actualizar_vehiculo(vehiculo_id: int, payload: VehiculoUpdate):
    return update_row("vehiculos", vehiculo_id, payload.model_dump(exclude_unset=True))


@app.delete("/vehiculos/{vehiculo_id}")
def eliminar_vehiculo(vehiculo_id: int):
    return delete_row("vehiculos", vehiculo_id)


# =========================
# CRUD: Viajes
# =========================
@app.get("/viajes")
def listar_viajes():
    return {"total": len(list_rows("viajes", "id DESC")), "viajes": list_rows("viajes", "id DESC")}


@app.get("/viajes/{viaje_id}")
def obtener_viaje(viaje_id: int):
    return get_row("viajes", viaje_id)


@app.post("/viajes", status_code=201)
def crear_viaje(payload: ViajeCreate):
    return create_row("viajes", payload.model_dump())


@app.put("/viajes/{viaje_id}")
def actualizar_viaje(viaje_id: int, payload: ViajeUpdate):
    return update_row("viajes", viaje_id, payload.model_dump(exclude_unset=True))


@app.delete("/viajes/{viaje_id}")
def eliminar_viaje(viaje_id: int):
    return delete_row("viajes", viaje_id)


# =========================
# CRUD: Asignaciones
# =========================
@app.get("/asignaciones")
def listar_asignaciones():
    return {"total": len(list_rows("asignaciones", "id DESC")), "asignaciones": list_rows("asignaciones", "id DESC")}


@app.get("/asignaciones/{asignacion_id}")
def obtener_asignacion(asignacion_id: int):
    return get_row("asignaciones", asignacion_id)


@app.post("/asignaciones", status_code=201)
def crear_asignacion(payload: AsignacionCreate):
    return create_row("asignaciones", payload.model_dump())


@app.put("/asignaciones/{asignacion_id}")
def actualizar_asignacion(asignacion_id: int, payload: AsignacionUpdate):
    return update_row("asignaciones", asignacion_id, payload.model_dump(exclude_unset=True))


@app.delete("/asignaciones/{asignacion_id}")
def eliminar_asignacion(asignacion_id: int):
    return delete_row("asignaciones", asignacion_id)


# =========================
# CRUD: Ubicaciones (GPS)
# =========================
@app.get("/ubicaciones")
def listar_ubicaciones():
    return {"total": len(list_rows("ubicaciones", "id DESC")), "ubicaciones": list_rows("ubicaciones", "id DESC")}


@app.get("/ubicaciones/{ubicacion_id}")
def obtener_ubicacion(ubicacion_id: int):
    return get_row("ubicaciones", ubicacion_id)


@app.post("/ubicaciones", status_code=201)
def crear_ubicacion(payload: UbicacionCreate):
    """Registra una ubicación GPS. El dispositivo físico puede esperar; el endpoint queda listo."""
    data = payload.model_dump()
    # Si no se envía fecha_hora, MySQL usará el DEFAULT CURRENT_TIMESTAMP cuando aplique.
    return create_row("ubicaciones", data)


@app.put("/ubicaciones/{ubicacion_id}")
def actualizar_ubicacion(ubicacion_id: int, payload: UbicacionUpdate):
    return update_row("ubicaciones", ubicacion_id, payload.model_dump(exclude_unset=True))


@app.delete("/ubicaciones/{ubicacion_id}")
def eliminar_ubicacion(ubicacion_id: int):
    return delete_row("ubicaciones", ubicacion_id)
