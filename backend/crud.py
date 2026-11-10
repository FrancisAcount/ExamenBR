from typing import Any, Dict, List

from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from database import engine


def _row_to_dict(row) -> Dict[str, Any]:
    return dict(row)


def _get_pk_column(conn, table: str) -> str:
    """Detecta la columna de clave primaria de la tabla (por defecto 'id')."""
    try:
        res = conn.execute(text(f"SHOW KEYS FROM `{table}` WHERE Key_name = 'PRIMARY'"))
        rows = res.mappings().all()
        if rows:
            # usar la primera columna de la PK
            return rows[0]["Column_name"]
    except Exception:
        pass
    # fallback común en esquemas existentes
    for candidate in ("id", f"{table[:-1]}_id" if table.endswith("s") else f"{table}_id"):
        try:
            cols = conn.execute(text(f"SHOW COLUMNS FROM `{table}` LIKE :c"), {"c": candidate}).mappings().all()
            if cols:
                return candidate
        except Exception:
            continue
    return "id"


def _get_order_by(conn, table: str, preferred: str) -> str:
    pk = _get_pk_column(conn, table)
    # si el preferido es simple y existe, úsalo; si no, usa pk
    pref = preferred.split(",")[0].strip().split()[0]
    try:
        cols = conn.execute(text(f"SHOW COLUMNS FROM `{table}` LIKE :c"), {"c": pref}).mappings().all()
        if cols:
            return preferred
    except Exception:
        pass
    return f"`{pk}` DESC"


def list_rows(table: str, order_by: str = "id") -> List[Dict[str, Any]]:
    try:
        with engine.connect() as conn:
            ob = _get_order_by(conn, table, order_by)
            result = conn.execute(text(f"SELECT * FROM `{table}` ORDER BY {ob}"))
            return [_row_to_dict(r) for r in result.mappings().all()]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=503, detail=f"No se pudo consultar {table}: {e}")


def get_row(table: str, row_id: int) -> Dict[str, Any]:
    try:
        with engine.connect() as conn:
            pk = _get_pk_column(conn, table)
            result = conn.execute(
                text(f"SELECT * FROM `{table}` WHERE `{pk}` = :id"), {"id": row_id}
            ).mappings().first()
        if not result:
            raise HTTPException(status_code=404, detail=f"Registro no encontrado en {table}")
        return _row_to_dict(result)
    except HTTPException:
        raise
    except SQLAlchemyError as e:
        raise HTTPException(status_code=503, detail=f"No se pudo consultar {table}: {e}")


def create_row(table: str, data: Dict[str, Any]) -> Dict[str, Any]:
    cols = [k for k, v in data.items() if v is not None]
    if not cols:
        raise HTTPException(status_code=400, detail="No hay datos para crear el registro")
    placeholders = ", ".join(f":{c}" for c in cols)
    columns_sql = ", ".join(f"`{c}`" for c in cols)
    try:
        with engine.begin() as conn:
            pk = _get_pk_column(conn, table)
            result = conn.execute(
                text(f"INSERT INTO `{table}` ({columns_sql}) VALUES ({placeholders})"),
                {c: data[c] for c in cols},
            )
            new_id = result.lastrowid
            if new_id:
                row = conn.execute(
                    text(f"SELECT * FROM `{table}` WHERE `{pk}` = :id"), {"id": new_id}
                ).mappings().first()
            else:
                # PK no autoincremental: intentar recuperar por los datos insertados
                where = " AND ".join(f"`{c}` = :{c}" for c in cols)
                row = conn.execute(
                    text(f"SELECT * FROM `{table}` WHERE {where} ORDER BY `{pk}` DESC LIMIT 1"),
                    {c: data[c] for c in cols},
                ).mappings().first()
        return _row_to_dict(row) if row else {"ok": True}
    except IntegrityError as e:
        raise HTTPException(status_code=400, detail=f"Error de integridad en {table}: {e.orig}")
    except SQLAlchemyError as e:
        raise HTTPException(status_code=503, detail=f"No se pudo crear en {table}: {e}")


def update_row(table: str, row_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
    # ensure exists
    get_row(table, row_id)
    cols = [k for k, v in data.items() if v is not None]
    if not cols:
        return get_row(table, row_id)
    set_clause = ", ".join(f"`{c}` = :{c}" for c in cols)
    params = {c: data[c] for c in cols}
    params["id"] = row_id
    try:
        with engine.begin() as conn:
            pk = _get_pk_column(conn, table)
            conn.execute(
                text(f"UPDATE `{table}` SET {set_clause} WHERE `{pk}` = :id"),
                params,
            )
            row = conn.execute(
                text(f"SELECT * FROM `{table}` WHERE `{pk}` = :id"), {"id": row_id}
            ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail=f"Registro no encontrado en {table}")
        return _row_to_dict(row)
    except IntegrityError as e:
        raise HTTPException(status_code=400, detail=f"Error de integridad en {table}: {e.orig}")
    except SQLAlchemyError as e:
        raise HTTPException(status_code=503, detail=f"No se pudo actualizar en {table}: {e}")


def delete_row(table: str, row_id: int) -> Dict[str, Any]:
    get_row(table, row_id)
    try:
        with engine.begin() as conn:
            pk = _get_pk_column(conn, table)
            conn.execute(text(f"DELETE FROM `{table}` WHERE `{pk}` = :id"), {"id": row_id})
        return {"eliminado": True, "id": row_id, "tabla": table}
    except IntegrityError as e:
        raise HTTPException(
            status_code=400,
            detail=f"No se puede eliminar el registro de {table} porque está relacionado con otros datos: {e.orig}",
        )
    except SQLAlchemyError as e:
        raise HTTPException(status_code=503, detail=f"No se pudo eliminar en {table}: {e}")
