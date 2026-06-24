 # Funciones vs Procedimientos
 
### 1. La Diferencia Fundamental

* **Función (`FUNCTION`):** Está diseñada para calcular y **devolver un resultado** (un valor simple, un registro o una tabla). Se ejecuta *dentro* de la transacción de quien la llama. **No puedes hacer `COMMIT` ni `ROLLBACK**` dentro de ella. Se llama usando `SELECT`.
* **Procedimiento (`PROCEDURE`):** Está diseñado para ejecutar una acción o tarea. No devuelve un valor directamente (aunque puede usar parámetros `INOUT`). Su superpoder es que **puede iniciar, confirmar (`COMMIT`) o deshacer (`ROLLBACK`) transacciones** dentro de su propio código. Se llama usando `CALL`.

---

### 2. Laboratorio Real: El Escenario Bancario

Imagina el sistema de un banco. Tenemos una tabla de `cuentas`.

**El Caso de Uso:**

1. Necesitamos calcular el interés de una cuenta (ideal para una **Función**).
2. Necesitamos procesar transferencias masivas a fin de mes, guardando los cambios por cada transferencia exitosa para que, si el sistema falla a la mitad, no perdamos el progreso anterior (ideal para un **Procedimiento**).

#### Código del Laboratorio

```sql
-- 1. Tabla de prueba
CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY,
    saldo NUMERIC NOT NULL
);
INSERT INTO cuentas VALUES (1, 1000.00), (2, 500.00), (3, 2000.00);

-- ==========================================
-- USO CORRECTO DE FUNCIÓN: Calcular algo
-- ==========================================
CREATE OR REPLACE FUNCTION calcular_interes(monto NUMERIC)
RETURNS NUMERIC 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Retorna el 5% del monto
    RETURN monto * 0.05;
END;
$$;

-- Se usa así:
-- SELECT id_cuenta, saldo, calcular_interes(saldo) FROM cuentas;


-- ==========================================
-- USO CORRECTO DE PROCEDIMIENTO: Lógica transaccional
-- ==========================================
CREATE OR REPLACE PROCEDURE procesar_transferencia(origen INT, destino INT, monto NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Restamos del origen
    UPDATE cuentas SET saldo = saldo - monto WHERE id_cuenta = origen;
    
    -- Sumamos al destino
    UPDATE cuentas SET saldo = saldo + monto WHERE id_cuenta = destino;
    
    -- ¡EL SUPERPODER! Hacemos commit de esta transacción específica
    COMMIT; 
    
    RAISE NOTICE 'Transferencia procesada y guardada en disco.';
EXCEPTION
    WHEN OTHERS THEN
        -- Si hay error (ej. fondos insuficientes), deshacemos SOLO esta operación
        ROLLBACK;
        RAISE NOTICE 'Error en transferencia, cambios revertidos.';
END;
$$;

-- Se usa así:
-- CALL procesar_transferencia(1, 2, 200.00);

```

---

### 3. ¿Qué pasa si los intercambiamos? (El desastre)

**Escenario A: Usar una FUNCIÓN para la transferencia (en vez del Procedimiento)**

* **Qué pasa:** Si tienes que transferir dinero a 10,000 clientes en un bucle, la función meterá todo en **una sola transacción gigante**.
* **El problema:** Como no puedes hacer `COMMIT` por cada registro, si la transferencia número 9,999 falla, **todo se hace ROLLBACK**. Las 9,998 transferencias anteriores se pierden. Además, consumirás muchísima memoria RAM y bloquearás las filas (locks) de la tabla por demasiado tiempo, afectando a otros usuarios.

**Escenario B: Usar un PROCEDIMIENTO para calcular el interés (en vez de la Función)**

* **Qué pasa:** Un procedimiento no retorna valores de forma natural (requiere trucos con parámetros `INOUT`) y no se puede llamar dentro de un `SELECT`.
* **El problema:** No podrías hacer algo tan simple como `SELECT nombre, calcular_interes(saldo) FROM clientes;`. Tendrías que llamar al procedimiento (`CALL`) fila por fila en tu backend, destruyendo el rendimiento por completo debido a los constantes viajes de red entre tu app y la base de datos.

---

### 4. ¿Qué pasa con el COMMIT y el ROLLBACK?

| Característica | En una Función (`FUNCTION`) | En un Procedimiento (`PROCEDURE`) |
| --- | --- | --- |
| **Contexto de Transacción** | Es un bloque atómico. Se acopla a la transacción que hizo el `SELECT`. | Puede romper la transacción en múltiples partes más pequeñas. |
| **`COMMIT` explícito** | **Error fatal.** Si escribes `COMMIT;`, PostgreSQL lanzará un error de sintaxis/ejecución. | **Funciona perfecto.** Cierra la transacción actual y abre una nueva automáticamente. |
| **`ROLLBACK` explícito** | **Error fatal.** Igual que el commit, no está permitido. | **Funciona perfecto.** Revierte los cambios desde el último commit o el inicio del procedure. |
| **Manejo de Errores (Exceptions)** | Un bloque `EXCEPTION` hace un "rollback implícito" al inicio de ese bloque, pero sigue en la misma transacción global. | Puedes atrapar el error, hacer `ROLLBACK` explícito y luego seguir procesando el resto del código sin abortar la ejecución completa. |

---

### 5. Resumen de Ventajas y Desventajas

#### Funciones

* **Ventajas:** Se pueden integrar en sentencias DML (`SELECT`, `WHERE`, `JOIN`). Son extremadamente rápidas para cálculos y filtrado de datos. Aseguran atomicidad (todo o nada).
* **Desventajas:** No sirven para procesamientos por lotes (batch) largos porque no liberan bloqueos (locks) ni memoria hasta que terminan por completo.

#### Procedimientos

* **Ventajas:** Ideales para scripts de mantenimiento, migraciones de datos pesadas, y procesos batch. Liberan bloqueos y recursos progresivamente gracias al `COMMIT` interno.
* **Desventajas:** No se pueden usar en sentencias `SELECT`. Son más rígidos para devolver conjuntos de datos complejos a la aplicación.

**Regla de oro de un DBA experto:** Si necesitas calcular y devolver datos, usa **FUNCTIONS**. Si necesitas mover muchos datos, automatizar tareas de mantenimiento o procesar lotes largos que necesiten guardarse por partes, usa **PROCEDURES**.
