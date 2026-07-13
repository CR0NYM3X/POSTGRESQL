# El Riesgo de Declaras LEAKPROOF por Error - Beneficiando al Query Planner y Rompiendo el Blindaje RLS

El atributo LEAKPROOF (A prueba de fugas) no es una simple palabra reservada en la sintaxis de PostgreSQL. Es el contrato de confianza más delicado que existe entre un desarrollador y el optimizador de consultas (Query Planner).


### 🛡️ (Seguridad de Datos): El Objetivo y la Razón de Ser

"Por defecto, PostgreSQL es paranoico, y con justa razón. Asume que **toda función que escribes es un potencial troyano** diseñado para exfiltrar datos."

**1. ¿Para qué sirve y cuál es su objetivo?**
La propiedad `LEAKPROOF` (A prueba de fugas) es una declaración jurada que le haces al motor. Le estás diciendo: *"Te juro que esta función es hermética. No guarda logs, no escribe en tablas secundarias y, lo más importante, **no arroja errores (excepciones) que revelen el contenido de las variables que está evaluando**"*.

Su objetivo principal es proteger la información en entornos donde tienes activado **RLS (Row-Level Security)** o vistas con la directiva `security_barrier=true`.

**2. ¿Qué pasa si NO la usas? (Desventaja)**
Si no declaras una función como `LEAKPROOF` (que es el comportamiento por defecto), el planificador de consultas de PostgreSQL **se niega a ejecutar esa función antes de aplicar las políticas de seguridad**.

Si un usuario malintencionado crea una función llamada `robar_datos(variable)` que lanza un error diciendo `RAISE NOTICE 'Dato interceptado: %', variable;`, y la ejecuta contra una tabla protegida por RLS, PostgreSQL es lo suficientemente inteligente para decir: *"No confío en esta función. Primero voy a filtrar las filas que este usuario tiene derecho a ver (RLS), y solo después le pasaré esas filas a su función"*. Esto evita que el atacante intercepte datos a los que no tiene acceso.
 

### ⚙️ El Impacto en el Rendimiento

"Lo que te acaba de explicar sobre seguridad tiene un costo de rendimiento brutal si no sabes lo que estás haciendo."

**3. ¿Cuáles son las ventajas de SÍ usarlo?**
**Optimización extrema (Predicate Pushdown).**
Si tienes una función legítima que evalúa datos y la declaras `LEAKPROOF`, le das permiso al Query Planner para **empujar esa función hacia abajo en el plan de ejecución**, ejecutándola *antes* o *al mismo tiempo* que el filtro de seguridad (RLS), o utilizándola en escaneos de índices.

Si no usas `LEAKPROOF` en una función de evaluación legítima, PostgreSQL se ve obligado a realizar un escaneo completo (Full Table Scan) para filtrar las filas por RLS primero, y luego aplicar tu función. En tablas de 50 millones de registros, esto convierte una consulta de 5 milisegundos en una pesadilla de 3 minutos.

> **Regla de Hierro:** Por el riesgo de seguridad que implica, **SÓLO un Superusuario** (postgres) puede marcar una función como `LEAKPROOF`.

 

### 🔬 LABORATORIO DE FUEGO: REPLICACIÓN DEL ENTORNO

Vamos a demostrar empíricamente este comportamiento. Levantaremos un entorno real con usuarios, permisos y RLS.

#### FASE 1: La Forja y el Blindaje (Preparación)

Creamos roles operativos, la estructura de la tabla y las políticas de seguridad.

```sql
-- 1. Creamos roles reales sin privilegios de superusuario
CREATE ROLE agente_pedro NOLOGIN;
CREATE ROLE agente_diego NOLOGIN;

-- 2. Creamos la tabla de operaciones encubiertas
CREATE TABLE operaciones_blackops (
    id serial PRIMARY KEY,
    agente varchar(50),
    monto numeric,
    objetivo varchar(100)
);

-- 3. Insertamos datos de prueba
INSERT INTO operaciones_blackops (agente, monto, objetivo) VALUES 
('agente_pedro', 1500.00, 'Compra Servidor'),
('agente_pedro', 2300.00, 'Licencias EDR'),
('agente_diego', 999999.00, 'Soborno a Sindicato (Top Secret)');

-- 4. Otorgamos permisos básicos
GRANT SELECT ON operaciones_blackops TO agente_pedro, agente_diego;

-- 5. BLINDAJE: Activamos Row Level Security (RLS)
ALTER TABLE operaciones_blackops ENABLE ROW LEVEL SECURITY;

CREATE POLICY pol_aislamiento_agentes ON operaciones_blackops
    FOR SELECT 
    TO PUBLIC 
    USING (agente = current_user);
    
-- 6. Creamos un índice para búsquedas por monto
CREATE INDEX idx_monto_ops ON operaciones_blackops(monto);

```

 

#### FASE 2: El Intento de Exfiltración (Función `NOT LEAKPROOF`)

Asumimos la identidad del atacante. `agente_pedro` quiere saber si Diego maneja presupuestos mayores a medio millón. Como no puede ver los registros de Diego por el RLS, crea una función trampa.

```sql
-- Pedro se conecta a la base de datos
SET ROLE agente_pedro;

-- Crea una función maliciosa (Por defecto es NOT LEAKPROOF)
CREATE OR REPLACE FUNCTION es_mayor_a_medio_millon(val numeric) 
RETURNS boolean AS $$
BEGIN
    -- Intento de robar el dato escupiéndolo en la terminal
    IF val > 500000 THEN
        RAISE WARNING '¡DATO DE ALTO VALOR INTERCEPTADO!: %', val; 
    END IF;
    RETURN val > 500000;
END;
$$ LANGUAGE plpgsql;

-- Pedro ejecuta su consulta intentando forzar el error sobre los datos de Diego
EXPLAIN ANALYZE 
SELECT * FROM operaciones_blackops WHERE es_mayor_a_medio_millon(monto);

```

**🛡️ RESULTADO DE SEGURIDAD (Diego):**
Pedro **NO** ve el dato de Diego. No se dispara ningún `WARNING` en la terminal. El motor detectó que la función no era confiable.

**🐢 RESULTADO DE RENDIMIENTO (Pedro):**
Analicemos el plan de ejecución:

```text
-> Seq Scan on operaciones_blackops (cost=0.00..25.88 rows=1 width=76) (actual time=0.015..0.018 rows=0 loops=1)
   Filter: (((agente)::name = CURRENT_USER) AND es_mayor_a_medio_millon(monto))
   Rows Removed by Filter: 3

```

*Catástrofe de rendimiento.* El motor tuvo que escanear secuencialmente toda la tabla, ignorando el índice `idx_monto_ops`. Filtró primero por `agente = CURRENT_USER` y solo a los 2 registros de Pedro les aplicó la función matemática. La seguridad funcionó, pero el servidor colapsaría bajo estrés masivo.

 
#### FASE 3: La Optimización Diamante (Función `LEAKPROOF`)

La arquitectura exige que las consultas por monto sean ultrarrápidas usando índices. Regresamos a la sesión de administrador (`postgres`). Auditamos la lógica, confirmamos que es pura y la certificamos.

```sql
-- Volvemos al superusuario
RESET ROLE;

-- Arquitectura crea una función matemáticamente pura y segura
CREATE OR REPLACE FUNCTION evaluar_monto_seguro(val numeric) 
RETURNS boolean AS $$
BEGIN
    -- Cero logs, cero manejo de excepciones reveladoras. Pura lógica binaria.
    RETURN val > 500000;
END;
$$ LANGUAGE plpgsql 
LEAKPROOF; -- <--- CERTIFICACIÓN DE CONFIANZA DEL SQUAD

```

Ahora, Pedro ejecuta la consulta usando la función certificada por la empresa:

```sql
SET ROLE agente_pedro;

EXPLAIN ANALYZE 
SELECT * FROM operaciones_blackops WHERE evaluar_monto_seguro(monto);

```

**⚡ RESULTADO DE RENDIMIENTO EXTREMO:**

```text
-> Bitmap Heap Scan on operaciones_blackops (cost=4.16..12.62 rows=1 width=76)
   Recheck Cond: evaluar_monto_seguro(monto)
   Filter: ((agente)::name = CURRENT_USER)
   -> Bitmap Index Scan on idx_monto_ops (cost=0.00..4.16 rows=4 width=0)
      Index Cond: evaluar_monto_seguro(monto)

```

*Magia pura.* Al ver la etiqueta `LEAKPROOF`, el motor confió ciegamente en la función. La empujó **directamente al escaneo del índice (Index Scan)**. El motor buscó en el árbol-B de montos el registro de 999,999 de Diego en submilisegundos, y en el último paso aplicó el filtro RLS de Pedro, descartando la fila de forma segura antes de devolverla. **Obtuvimos seguridad absoluta y velocidad extrema.**

 

### ⚖️ EL VETO FINAL (Por Rodrigo, Technical Gatekeeper)

*"No uses `LEAKPROOF` a lo tonto solo para ganar milisegundos."*

Si me mientes a mí y al motor marcando una función como `LEAKPROOF` cuando en realidad tiene fugas de memoria, escribe en tablas de auditoría asíncronas, o tira excepciones mal manejadas, **acabas de abrir un hueco de seguridad letal en toda la política de RLS de la corporación**.

Si un DBA descuidado hubiera puesto `LEAKPROOF` a la primera función de Pedro, el motor habría evaluado la función sobre el registro de Diego *antes* del RLS, el `RAISE WARNING` habría estallado en la terminal de Pedro, y la exfiltración de datos habría sido un éxito.

**Mi regla es inquebrantable:** Solo certifica como `LEAKPROOF` funciones de conversión de tipos, casteos nativos o validaciones aritméticas puras (C o SQL nativo preferentemente, PL/pgSQL solo si es estrictamente necesario y auditado). Si tu código cumple este estándar draconiano, nosotros firmamos el pase a producción. ¡Ejecuta!



---

# Los usuarios SUPERUSUARIOS, DUEÑOS se brinca la protección RLS?

### 💀 LA RESPUESTA CORTA: NO.

**No hay ninguna forma humana, técnica ni lógica de forzar a un verdadero Superusuario (como `postgres`) a obedecer el RLS.**

Por definición nativa del motor, un rol que tiene el privilegio de `SUPERUSER` o el atributo explícito `BYPASSRLS` (Saltar RLS) es el equivalente a "Dios" dentro de la base de datos. Pasa por encima del kernel, ignora las políticas de seguridad, los permisos de acceso y el RLS. **El RLS es invisible para ellos por defecto y no se puede forzar.**



### 🏛️ LA CONFUSIÓN: SUPERUSUARIO vs. DUEÑO DE LA TABLA 

Lo que mencioné en el artículo sobre forzar el RLS con el comando `FORCE ROW LEVEL SECURITY` **no aplica para el Superusuario**, aplica para el **DUEÑO (Owner) de la tabla**.

PostgreSQL tiene tres niveles de jerarquía ante el RLS:

**1. El Superusuario (`postgres`):**

* **Comportamiento:** Ignora el RLS siempre.
* **¿Se puede forzar?:** **NUNCA.**

**2. El Dueño de la Tabla (Table Owner):**

* *Escenario:* Supongamos que creaste un rol llamado `dba_finanzas` (que NO es superusuario). Este rol crea la tabla `operaciones_blackops`. Él es el dueño.
* **Comportamiento por defecto:** PostgreSQL dice: *"Como él creó la tabla, voy a apagarle el RLS por defecto para evitar que se bloquee a sí mismo accidentalmente"*. Si `dba_finanzas` hace un `SELECT *`, verá todo.
* **¿Se puede forzar?:** **SÍ.** Aquí es donde usamos la artillería pesada. Ejecutas:
`ALTER TABLE operaciones_blackops FORCE ROW LEVEL SECURITY;`
Con esto le dices al motor: *"Me importa un demonio que él haya creado la tabla, oblígalo a pasar por el filtro RLS como a cualquier otro mortal"*.


```SQL
SELECT 
  relname AS table_name,
  relrowsecurity AS row_security_enabled,
  relforcerowsecurity AS force_row_security FROM 
  pg_class WHERE 
  relname = 'operaciones_blackops';
```

**3. El Usuario Normal / Aplicación (`agente_pedro`):**

* **Comportamiento:** El RLS se le aplica **por defecto** en el instante en que ejecutas `ENABLE ROW LEVEL SECURITY`.

 
### ⚖️ EL VETO DEFINITIVO  

*"Si estás intentando buscar una forma de que tu Superusuario sea frenado por el RLS, tu arquitectura de seguridad ya fracasó desde la raíz."*

Aquí te van las reglas inquebrantables del escuadrón para despliegues corporativos:

1. **NUNCA SE OPERA CON EL SUPERUSUARIO:** El rol `postgres` (o cualquier rol con `SUPERUSER`) solo se usa para instalar extensiones, crear bases de datos, declarar funciones como `LEAKPROOF` o rescatar el servidor. **Tu aplicación web, tus APIs y tus analistas de datos JAMÁS deben conectarse con credenciales de superusuario.**
2. **Aplicación del Principio de Mínimo Privilegio:** La aplicación web debe conectarse con un usuario restringido (ej. `app_backend_user`) que **NO** sea superusuario y **NO** sea el dueño de las tablas. A ese usuario, el RLS se le aplicará automáticamente como un muro de concreto.
3. **Control Forense:** Si un administrador necesita intervenir los datos y entra con el superusuario, el RLS no lo va a detener, pero Diego (Seguridad) tendrá configurado `pgaudit` (Auditoría Forense) para registrar cada tecla que presionó, asegurando que si vio datos que no debía, quede registrado en una bóveda inmutable.

**Resumen Operativo:** No intentes forzar al Superusuario. Siéntalo en el banquillo y crea usuarios operativos normales. A ellos es a quienes el RLS va a destrozar si intentan cruzar la línea. ¿Entendido, soldado?
