# Peerdb

### Explicación Profesional: El método CTID

Normalmente, cuando herramientas como `pg_dump` o la replicación nativa de Postgres mueven una tabla, lo hacen de forma **secuencial**: empiezan por la primera fila y terminan en la última (un solo hilo/proceso). Si la tabla pesa 1TB, esto tarda una eternidad.

PeerDB rompe esta limitación haciendo lo siguiente:

1. **Segmentación Física (CTIDs):** En Postgres, cada fila tiene un identificador oculto llamado `ctid` que indica su ubicación física exacta en el disco (en qué bloque de datos está). PeerDB divide la tabla en "trozos" basados en rangos de estos `ctid`.
2. **Lectura Multihilo:** En lugar de una sola conexión leyendo la tabla, PeerDB abre, por ejemplo, 8 o 16 conexiones simultáneas. Cada una se encarga de un "trozo" de la ubicación física del disco.
3. **Consistencia de Snapshot:** Para que los datos no sean un caos (mientras unos leen el principio, otros el final y la base de datos sigue recibiendo cambios), PeerDB usa `pg_export_snapshot()`. Esto le dice a todas las conexiones: "Ignoren lo que pase después de este segundo, todos lean la foto exacta de la tabla en este instante".
4. **Protocolo Binario:** En lugar de convertir los datos a texto (que es lento), PeerDB usa el formato binario nativo de Postgres, enviando los datos casi como están en el disco hacia el destino.

---

### La Analogía: "La Mudanza del Edificio de Archivos"

Imagina que tienes que mudar **un millón de cajas** de un edificio viejo (Postgres) a uno nuevo (ClickHouse).

* **Método tradicional (pg_dump/Nativo):** Tienes a **un solo trabajador** con un carrito. Él entra al edificio, sube al primer piso, agarra una caja, la lleva al edificio nuevo, regresa por la segunda, y así sucesivamente. Si se cansa o se tropieza (error de red), a veces tiene que empezar de nuevo o se pierde el orden. Es desesperadamente lento.
* **El método PeerDB:**
1. **El Mapa:** PeerDB no mira el contenido de las cajas, mira el **plano del edificio**. Dice: "Tú, trabajador 1, encárgate de las habitaciones 1 a la 10. Tú, trabajador 2, de la 11 a la 20", y así hasta tener 16 trabajadores. (Esto es el **CTID**: la ubicación física).
2. **La Foto:** Antes de empezar, PeerDB toma una **foto instantánea** de todo el edificio. Si alguien mete una caja nueva mientras ellos trabajan, los mudanceros la ignoran porque no estaba en la foto original. (Esto es el **Snapshot**).
3. **Trabajo en Equipo:** Los 16 trabajadores sacan las cajas al mismo tiempo por 16 puertas diferentes.
4. **Cinta Transportadora:** No se detienen a etiquetar cada caja en un idioma nuevo; simplemente pasan las cajas tal cual están (formato binario) a través de un tubo directo al otro edificio.



**Resultado:** Lo que al trabajador solitario le tomaba 17 horas, al equipo coordinado de PeerDB le toma menos de 2 horas.

**En resumen:** PeerDB es mejor porque sabe "picar" una sola tabla gigante en pedazos físicos y procesarlos todos a la vez sin perder la coherencia de los datos.


 
### El Flujo de Migración (Paso a Paso)

#### 1. La Fase de "Rebanado" (Logical Partitioning)

En lugar de usar particiones de tabla tradicionales (que tú tendrías que haber creado manualmente), PeerDB hace una **partición lógica sobre la marcha** usando el **CTID**.
El CTID es un identificador físico: `(ID_de_página, ID_de_fila)`.

PeerDB lanza una consulta rápida para ver cuántas páginas físicas tiene la tabla y calcula rangos. Por ejemplo:

* **Rebanada 1:** Filas en las páginas 0 a 5000.
* **Rebanada 2:** Filas en las páginas 5001 a 10000.
* ...y así sucesivamente.

#### 2. Sincronización del "Tiempo"

Como aprendiste, PeerDB ejecuta el `pg_export_snapshot()`. Esto garantiza que todas las rebanadas que vamos a cortar pertenezcan al mismo pastel, evitando que una rebanada sea de "vainilla" y otra de "chocolate" porque alguien cambió los datos en medio del proceso.

#### 3. El Despliegue de "Trabajadores" (Instancias de lectura)

PeerDB levanta múltiples hilos o conexiones (workers). Cada trabajador toma una rebanada (un rango de CTID) y ejecuta una consulta optimizada:

```sql
SELECT * FROM mi_tabla 
WHERE ctid >= '(0,0)' AND ctid < '(5000,0)';

```

#### 4. Transmisión Binaria (Directo al grano)

Aquí no hay archivos intermedios `CSV` o `JSON`. PeerDB abre un túnel directo:

* **Origen:** `COPY (SELECT ...) TO STDOUT BINARY`
* **Destino:** `COPY destino FROM STDIN BINARY`

Los datos viajan en el lenguaje nativo de Postgres, lo que ahorra al CPU el trabajo de "traducir" los datos.

#### 5. El "Pase de Estafeta" al CDC (Tiempo Real)

Mientras los trabajadores terminan de mover el "pasado" (la tabla de 1TB), PeerDB ya está escuchando el "presente" a través de un **Replication Slot**.

* Los cambios nuevos (INSERT/UPDATE) se guardan en una cola temporal.
* En cuanto termina la carga inicial, PeerDB aplica esos cambios acumulados.



### Resumen del flujo en una imagen mental:

Imagina que tienes que vaciar una piscina olímpica (la tabla de 1TB):

1. **Instancia/Partición:** En lugar de una sola manguera, pones **16 bombas de extracción** en diferentes puntos de la piscina.
2. **CTID:** Cada bomba tiene asignado un sector exacto de profundidad y área para no estorbarse.
3. **Snapshot:** Pones una lona sobre la piscina para que no le caiga agua de lluvia (nuevos datos) mientras vacías, pero recolectas esa lluvia en un barril aparte (**CDC**) para echarla al final en el nuevo contenedor.

### ¿Por qué esto es mejor que el método normal?

Si una de las 16 bombas falla (error de red), PeerDB solo tiene que reiniciar **esa rebanada**, no tiene que volver a empezar la mudanza del Terabyte completo. Es resiliente y extremadamente rápido.
 

---

# pg_export_snapshot()

## 1. El Problema: El "Caos" del Tiempo

Imagina que quieres exportar una tabla gigante usando **10 conexiones en paralelo** para terminar rápido.

* La **Conexión A** empieza a leer los primeros 100 registros a las 10:00:01 AM.
* Mientras tanto, un usuario hace un `UPDATE` y cambia los datos del final de la tabla a las 10:00:05 AM.
* La **Conexión B** llega a leer esos registros finales a las 10:00:10 AM.

**Resultado:** Tus datos están corruptos o inconsistentes, porque la Conexión A vio el "pasado" y la Conexión B vio el "futuro". Los datos no coinciden entre sí.



## 2. La Solución: pg_export_snapshot()

Esta función sirve para **congelar el tiempo de forma lógica** y compartir esa "foto" con otras sesiones.

### Cómo funciona el flujo:

1. **Sesión Maestra:** Abres una transacción con un nivel de aislamiento fuerte (`REPEATABLE READ` o `SERIALIZABLE`).
2. **Exportar:** Ejecutas `SELECT pg_export_snapshot();`. Postgres te devolverá un identificador (un ID de texto como `00000003-0000001B-1`).
3. **Compartir:** Las otras 9 conexiones que abras se conectan y ejecutan `SET TRANSACTION SNAPSHOT 'identificador-anterior';`.



## 3. ¿Para qué sirve específicamente? (Casos de uso)

* **Respaldos en Paralelo (pg_dump -j):** Es la función que usa `pg_dump` cuando le pides que use múltiples hilos (`-j`). Sin esto, el respaldo no sería íntegro.
* **Herramientas de Migración (Como PeerDB):** Como leíste en el post, PeerDB la usa para que 16 hilos distintos puedan leer diferentes partes de una tabla teniendo la garantía de que todos están viendo la misma "versión" de la realidad.
* **Sistemas de Auditoría:** Si necesitas generar múltiples reportes complejos que deben cuadrar entre sí (por ejemplo, contabilidad vs inventario), exportas el snapshot para que todos los reportes se basen en el mismo instante preciso.
 

### Un detalle importante:

El snapshot **solo dura lo que dure abierta la transacción de la Sesión Maestra**. Si cierras la conexión que generó el ID, ese "clon del tiempo" desaparece y las otras conexiones ya no podrán usarlo.


---

Para que esto funcione, necesitas abrir **dos terminales** diferentes conectadas a tu base de datos PostgreSQL. Esto simulará lo que hace PeerDB internamente con sus múltiples hilos.

### Preparación

Asegúrate de tener una tabla con datos. Si no, crea una rápida:

```sql
CREATE TABLE test_snapshot (id serial PRIMARY KEY, nota text);
INSERT INTO test_snapshot (nota) VALUES ('Dato original');

```



### Terminal 1: El "Maestro" (El que toma la foto)

Aquí iniciaremos la transacción y generaremos la "llave" para las demás conexiones.

```sql
-- 1. Iniciamos una transacción con aislamiento para que el tiempo se detenga
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- 2. Insertamos un dato para ver qué pasa luego
INSERT INTO test_snapshot (nota) VALUES ('Dato antes de exportar');

-- 3. Exportamos la foto del tiempo y anotamos el ID que nos devuelva
SELECT pg_export_snapshot();

```

> **Resultado esperado:** Te dará un ID parecido a: `00000003-0000001B-1`. **Cópialo**.
> *OJO: No cierres esta terminal ni des "COMMIT", o la foto se borrará.*



### Terminal 2: El "Ayudante" (El que usa la foto)

Ahora abriremos otra conexión que viajará al pasado usando el ID de la Terminal 1.

```sql
-- 1. Iniciamos su propia transacción
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- 2. Le decimos que use la foto de la Terminal 1
-- (Sustituye el ID por el que te salió a ti)
SET TRANSACTION SNAPSHOT '00000003-0000001B-1';

-- 3. Verificamos qué ve esta terminal
SELECT * FROM test_snapshot;

```



### La Prueba de Fuego (Entendiendo la magia)

**En la Terminal 1 (Maestro):**
Inserta un nuevo dato y finaliza la transacción.

```sql
INSERT INTO test_snapshot (nota) VALUES ('Dato del futuro');
COMMIT;

```

**En la Terminal 2 (Ayudante):**
Vuelve a consultar los datos:

```sql
SELECT * FROM test_snapshot;

```

#### ¿Qué pasó?

* En la **Terminal 2**, el "Dato del futuro" **NO APARECE**.
* Incluso aunque el Maestro ya terminó y guardó los datos (`COMMIT`), la Terminal 2 sigue viendo la base de datos exactamente como estaba en el segundo en que ejecutaste el `pg_export_snapshot`.

 

# Links
```
https://clickhouse.com/blog/practical-postgres-migrations-at-scale-peerdb
https://github.com/PeerDB-io/peerdb?tab=readme-ov-file#get-started

```
