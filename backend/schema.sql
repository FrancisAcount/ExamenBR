-- ============================================================
-- Base de datos «maranata_escolar» — API de Transporte Maranata
-- Ejecuta este script en MySQL/MariaDB antes de levantar la API:
--   PowerShell: Get-Content schema.sql | mysql -u root -p
--   cmd:        mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS maranata_escolar
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE maranata_escolar;

-- =========================
-- Estudiantes
-- =========================
CREATE TABLE IF NOT EXISTS estudiantes (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  nombres        VARCHAR(80)  NOT NULL,
  apellidos      VARCHAR(80)  NOT NULL,
  curso          VARCHAR(40)  NOT NULL,
  nombre_tutor   VARCHAR(120) NOT NULL,
  telefono_tutor VARCHAR(30)  NOT NULL,
  direccion      VARCHAR(200) NOT NULL,
  estado         VARCHAR(20)  NOT NULL DEFAULT 'Activo',
  INDEX idx_estudiantes_apellidos (apellidos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Conductores
-- =========================
CREATE TABLE IF NOT EXISTS conductores (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nombres   VARCHAR(80)  NOT NULL,
  apellidos VARCHAR(80)  NOT NULL,
  ci        VARCHAR(30)  NULL,
  telefono  VARCHAR(30)  NULL,
  licencia  VARCHAR(50)  NULL,
  estado    VARCHAR(20)  NOT NULL DEFAULT 'Activo',
  INDEX idx_conductores_apellidos (apellidos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Rutas
-- =========================
CREATE TABLE IF NOT EXISTS rutas (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  origen      VARCHAR(150) NULL,
  destino     VARCHAR(150) NULL,
  descripcion TEXT         NULL,
  estado      VARCHAR(20)  NOT NULL DEFAULT 'Activa',
  INDEX idx_rutas_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Vehículos
-- =========================
CREATE TABLE IF NOT EXISTS vehiculos (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  placa     VARCHAR(20)  NOT NULL,
  marca     VARCHAR(60)  NULL,
  modelo    VARCHAR(60)  NULL,
  capacidad INT          NULL,
  estado    VARCHAR(20)  NOT NULL DEFAULT 'Activo',
  UNIQUE KEY uk_vehiculos_placa (placa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Viajes
-- =========================
CREATE TABLE IF NOT EXISTS viajes (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  ruta_id      INT  NULL,
  vehiculo_id  INT  NULL,
  conductor_id INT  NULL,
  fecha        DATE NULL,
  hora_salida  TIME NULL,
  hora_llegada TIME NULL,
  estado       VARCHAR(20) NOT NULL DEFAULT 'Programado',
  INDEX idx_viajes_fecha (fecha),
  CONSTRAINT fk_viajes_ruta FOREIGN KEY (ruta_id) REFERENCES rutas(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_viajes_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_viajes_conductor FOREIGN KEY (conductor_id) REFERENCES conductores(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Asignaciones (estudiante <-> ruta)
-- =========================
CREATE TABLE IF NOT EXISTS asignaciones (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id INT NOT NULL,
  ruta_id       INT NOT NULL,
  parada        VARCHAR(150) NULL,
  estado        VARCHAR(20)  NOT NULL DEFAULT 'Activa',
  INDEX idx_asignaciones_estudiante (estudiante_id),
  INDEX idx_asignaciones_ruta (ruta_id),
  CONSTRAINT fk_asignaciones_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_asignaciones_ruta FOREIGN KEY (ruta_id) REFERENCES rutas(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- Ubicaciones (GPS)
-- Nota: el dispositivo GPS físico puede esperar; la tabla/CRUD quedan listos.
-- =========================
CREATE TABLE IF NOT EXISTS ubicaciones (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  viaje_id   INT            NULL,
  latitud    DECIMAL(10, 7) NOT NULL,
  longitud   DECIMAL(10, 7) NOT NULL,
  velocidad  DECIMAL(6, 2)  NULL,
  fecha_hora DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ubicaciones_viaje_fecha (viaje_id, fecha_hora),
  CONSTRAINT fk_ubicaciones_viaje FOREIGN KEY (viaje_id) REFERENCES viajes(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Datos de prueba (opcional): 8 estudiantes de ejemplo.
-- No lo ejecutes sobre una base que ya tenga datos reales para evitar duplicados.
INSERT INTO estudiantes
  (nombres, apellidos, curso, nombre_tutor, telefono_tutor, direccion, estado)
VALUES
  ('Mateo',    'Quispe Ramos',     '1ro Primaria', 'Rosa Ramos',      '+593 99 111 0001', 'Av. Simón Bolívar 120',  'Activo'),
  ('Valentina','Flores Cardozo',   '2do Primaria', 'Ana Cardozo',     '+593 99 111 0002', 'Calle Los Pinos 45',     'Activo'),
  ('Santiago', 'Mamani Vilca',     '3ro Primaria', 'Luis Mamani',     '+593 99 111 0003', 'Jr. Las Palmeras 310',   'Activo'),
  ('Isabela',  'Rojas Torres',     '4to Primaria', 'Carmen Torres',    '+593 99 111 0004', 'Av. Arequipa 890',       'Activo'),
  ('Lucas',    'Condori Poma',     '5to Primaria', 'María Poma',      '+593 99 111 0005', 'Pasaje Los Rosales 12',  'Activo'),
  ('Camila',   'Vargas Lima',      '6to Primaria', 'Pedro Vargas',    '+593 99 111 0006', 'Av. Del Sol 675',        'Activo'),
  ('Mateo',    'Álvarez Soto',     '1ro Secundaria','Julia Soto',     '+593 99 111 0007', 'Calle Buenos Aires 220', 'Activo'),
  ('Renata',   'Chávez Medina',    '2do Secundaria','Iván Chávez',    '+593 99 111 0008', 'Av. La Marina 1050',     'Activo');
