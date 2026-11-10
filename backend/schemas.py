from datetime import date, datetime, time
from typing import Optional

from pydantic import BaseModel, Field


# ---------- Estudiantes ----------
class EstudianteBase(BaseModel):
    nombres: str
    apellidos: str
    curso: str
    nombre_tutor: str
    telefono_tutor: str
    direccion: str
    estado: str = "Activo"


class EstudianteCreate(EstudianteBase):
    pass


class EstudianteUpdate(BaseModel):
    nombres: Optional[str] = None
    apellidos: Optional[str] = None
    curso: Optional[str] = None
    nombre_tutor: Optional[str] = None
    telefono_tutor: Optional[str] = None
    direccion: Optional[str] = None
    estado: Optional[str] = None


# ---------- Conductores ----------
class ConductorBase(BaseModel):
    nombres: str
    apellidos: str
    ci: Optional[str] = None
    telefono: Optional[str] = None
    licencia: Optional[str] = None
    estado: str = "Activo"


class ConductorCreate(ConductorBase):
    pass


class ConductorUpdate(BaseModel):
    nombres: Optional[str] = None
    apellidos: Optional[str] = None
    ci: Optional[str] = None
    telefono: Optional[str] = None
    licencia: Optional[str] = None
    estado: Optional[str] = None


# ---------- Rutas ----------
class RutaBase(BaseModel):
    nombre: str
    origen: Optional[str] = None
    destino: Optional[str] = None
    descripcion: Optional[str] = None
    estado: str = "Activa"


class RutaCreate(RutaBase):
    pass


class RutaUpdate(BaseModel):
    nombre: Optional[str] = None
    origen: Optional[str] = None
    destino: Optional[str] = None
    descripcion: Optional[str] = None
    estado: Optional[str] = None


# ---------- Vehiculos ----------
class VehiculoBase(BaseModel):
    placa: str
    marca: Optional[str] = None
    modelo: Optional[str] = None
    capacidad: Optional[int] = Field(default=None, ge=0)
    estado: str = "Activo"


class VehiculoCreate(VehiculoBase):
    pass


class VehiculoUpdate(BaseModel):
    placa: Optional[str] = None
    marca: Optional[str] = None
    modelo: Optional[str] = None
    capacidad: Optional[int] = Field(default=None, ge=0)
    estado: Optional[str] = None


# ---------- Viajes ----------
class ViajeBase(BaseModel):
    ruta_id: Optional[int] = None
    vehiculo_id: Optional[int] = None
    conductor_id: Optional[int] = None
    fecha: Optional[date] = None
    hora_salida: Optional[time] = None
    hora_llegada: Optional[time] = None
    estado: str = "Programado"


class ViajeCreate(ViajeBase):
    pass


class ViajeUpdate(BaseModel):
    ruta_id: Optional[int] = None
    vehiculo_id: Optional[int] = None
    conductor_id: Optional[int] = None
    fecha: Optional[date] = None
    hora_salida: Optional[time] = None
    hora_llegada: Optional[time] = None
    estado: Optional[str] = None


# ---------- Asignaciones ----------
class AsignacionBase(BaseModel):
    estudiante_id: int
    ruta_id: int
    parada: Optional[str] = None
    estado: str = "Activa"


class AsignacionCreate(AsignacionBase):
    pass


class AsignacionUpdate(BaseModel):
    estudiante_id: Optional[int] = None
    ruta_id: Optional[int] = None
    parada: Optional[str] = None
    estado: Optional[str] = None


# ---------- Ubicaciones (GPS) ----------
class UbicacionBase(BaseModel):
    viaje_id: Optional[int] = None
    latitud: float
    longitud: float
    velocidad: Optional[float] = None
    fecha_hora: Optional[datetime] = None


class UbicacionCreate(UbicacionBase):
    pass


class UbicacionUpdate(BaseModel):
    viaje_id: Optional[int] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    velocidad: Optional[float] = None
    fecha_hora: Optional[datetime] = None
