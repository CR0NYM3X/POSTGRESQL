

PostgreSQL es increíble, hasta que dejas de usar la columna de fecha en una tabla de 1TB particionada por rangos. En ese momento, el motor se vuelve ciego y tu consulta de milisegundos pasa a durar segundos. Aquí te enseño cómo los arquitectos senior resolvemos esto sin esperar a que existan los índices globales nativos.

 
### Escenario Real (Tabla de Mapeo): Plataforma de Facturación Electrónica Global 

**El Problema:**
Imagina una plataforma que procesa **500 millones de facturas al año**.

* **Estrategia de Particionado:** Por `fecha_emision` (mensual), para facilitar purgas legales y reportes anuales.
* **El Caos:** Los clientes llaman a soporte técnico con un `id_factura` (un UUID o un BigInt secuencial) para reclamar un error. Soporte busca el ID en el panel administrativo.
* **El Impacto:** La consulta `SELECT * FROM facturas WHERE id_factura = 'ABC-123'` tarda **8 segundos** porque Postgres tiene que escanear los índices de las 60 particiones (5 años de data). Multiplica esto por 1,000 agentes de soporte: la base de datos colapsa por I/O.

---

### La Solución: Arquitectura de Indexación Indirecta (Mapping Table)

Vamos a crear una **"Shadow Table"** (Tabla Espejo) extremadamente delgada que actúe como nuestro "Índice Global Manual".

#### 1. Creación de las tablas

```sql
-- 1. Tabla Principal Particionada
CREATE TABLE facturas (
    id_factura BIGINT NOT NULL,
    fecha_emision DATE NOT NULL,
    cliente_id INT,
    monto NUMERIC(15,2),
    datos_xml TEXT
) PARTITION BY RANGE (fecha_emision);

-- 2. Tabla de Mapeo (Nuestra solución crítica)
-- Esta tabla NO está particionada para que la búsqueda sea O(1)
CREATE TABLE facturas_lookup (
    id_factura BIGINT PRIMARY KEY,
    fecha_emision DATE NOT NULL
);

```

#### 2. Automatización con Triggers (Bajo Impacto)

Necesitamos que cada vez que se cree una factura, se registre en el mapa. Usaremos una función de trigger optimizada.

```sql
CREATE OR REPLACE FUNCTION fn_sync_facturas_lookup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO facturas_lookup (id_factura, fecha_emision)
    VALUES (NEW.id_factura, NEW.fecha_emision);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_facturas_lookup
AFTER INSERT ON facturas
FOR EACH ROW EXECUTE FUNCTION fn_sync_facturas_lookup();

```

---

### 3. La Consulta de "Arquitecto Senior"

Aquí es donde resolvemos el problema. En lugar de una consulta simple, usamos una **Common Table Expression (CTE)** o un **Subquery** que obligue al optimizador a hacer *Partition Pruning*.

**Consulta Ineficiente (El error común):**

```sql
SELECT * FROM facturas WHERE id_factura = 998877; 
-- Resultado: Scan en todas las particiones. Lento.

```

**Consulta Optimizada (La Solución Real):**

```sql
-- Usamos la tabla de mapeo para inyectar la fecha y activar el PRUNING
SELECT f.*
FROM facturas f
WHERE f.fecha_emision = (SELECT l.fecha_emision FROM facturas_lookup l WHERE l.id_factura = 998877)
  AND f.id_factura = 998877;

```
[NOTA] -> Tambien puedes crear una funcion que fecilite esta consulta 

**¿Qué pasa internamente en Postgres?**

1. El motor ejecuta primero el subquery sobre `facturas_lookup`. Como es un `PRIMARY KEY`, tarda **< 1ms**.
2. Obtiene la fecha (ej. `2024-05-15`).
3. El motor de ejecución recibe: `SELECT * FROM facturas WHERE fecha_emision = '2024-05-15' AND id_factura = 998877`.
4. **Partition Pruning activo:** Postgres ignora las otras 59 particiones y va directo a la partición de mayo 2024.

---

### 4. Análisis de Criticidad: ¿Qué pasa con el almacenamiento?

Como arquitecto, debes preocuparte por el crecimiento.

* **La tabla de mapeo es "Lightweight":** Solo contiene un `BIGINT` (8 bytes) y un `DATE` (4 bytes).
* Incluso con **100 millones de registros**, la tabla de mapeo ocuparía aproximadamente **4-5 GB** incluyendo el índice. Es un costo mínimo comparado con tener la base de datos bloqueada por búsquedas ineficientes.

### Ventaja adicional en desastres

Si alguna vez necesitas mover una partición vieja a un "Cold Storage" (como un Tablespace en discos lentos), esta tabla de mapeo te dirá exactamente dónde está el registro sin importar qué tan lejos lo hayas movido físicamente.

 
