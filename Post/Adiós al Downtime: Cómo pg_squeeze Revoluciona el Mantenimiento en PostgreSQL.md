# Adiós al Downtime: Cómo `pg_squeeze` Revoluciona el Mantenimiento en PostgreSQL

Si administras bases de datos en PostgreSQL, seguramente conoces a su mayor enemigo silencioso: el **"bloat"** (espacio desperdiciado). Debido a la arquitectura de Control de Concurrencia Multiversión (MVCC) de Postgres, cuando actualizas o borras una fila, la base de datos no elimina la anterior de inmediato; simplemente la marca como "invisible".

Con el tiempo, tu tabla de 10 GB puede inflarse a 100 GB, consumiendo tu disco y destrozando el rendimiento de tus consultas.

La solución oficial de Postgres es el temido `VACUUM FULL`. ¿El problema? Exige un bloqueo exclusivo (`ACCESS EXCLUSIVE`). Durante las horas que tarde en limpiar esos 100 GB, tu aplicación no podrá leer ni escribir un solo dato. En un entorno de producción 24/7, **eso es inaceptable**.

Durante años, la industria usó extensiones como `pg_repack` (basada en triggers) para solucionar esto. Pero hoy, existe una herramienta más moderna, limpia y nativa: **`pg_squeeze`**.

---

## ¿Qué es `pg_squeeze`?

`pg_squeeze` es una extensión que elimina el espacio desperdiciado de tus tablas e índices en vivo, **sin bloquear las lecturas ni las escrituras**.

A diferencia de las herramientas antiguas que penalizan el rendimiento del disco escribiendo el doble (Write Amplification) a través de triggers, `pg_squeeze` utiliza la **Decodificación Lógica (Logical Decoding)** de PostgreSQL. Trabaja de forma silenciosa en segundo plano mediante funciones puramente SQL.

## La Magia bajo el capó: ¿Cómo logra copiar sin bloquear?

Copiar una tabla de 100 GB en vivo suena imposible. Si los usuarios siguen insertando datos mientras copias, el nuevo archivo nacería obsoleto. `pg_squeeze` resuelve esto usando dos mecanismos trabajando en equipo:

1. **La Fotografía (Copia Base):** `pg_squeeze` crea un archivo físico oculto y toma un *Snapshot* (Instantánea) de la base de datos. Congela el tiempo y copia únicamente las filas válidas (sin basura) hacia el nuevo archivo. Esto puede tardar horas, pero no bloquea nada.
2. **La Grabadora (Replication Slot):** Mientras ocurre la copia masiva, un Replication Slot vigila el registro central de transacciones (WAL) y anota todos los `INSERT`, `UPDATE` y `DELETE` que los usuarios están haciendo en tiempo real.
3. **El Catch-up:** Al terminar la copia masiva, `pg_squeeze` reproduce todos los cambios recientes guardados en la grabadora sobre el archivo nuevo a una velocidad altísima, poniéndolo exactamente al día.

---

## El Miedo del DBA: ¿Qué pasa con mis Triggers, Rules y Foreign Keys?

Esta es la pregunta del millón. Si `pg_squeeze` está moviendo mis datos a un archivo nuevo, ¿se rompe la integridad referencial? ¿Tengo que recrear mis vistas?

La respuesta es **NO. Todo se conserva intacto.**

Para entender por qué, hay que conocer un secreto de la arquitectura de PostgreSQL: **la separación entre la identidad lógica y el archivo físico.**
Toda tabla en Postgres tiene dos identificadores:

* **El OID (Identidad Lógica):** Es el "alma" de la tabla. Tus Foreign Keys, Triggers, Vistas y Permisos están amarrados a este número.
* **El Relfilenode (Archivo Físico):** Es el archivo real en el disco duro donde viven los datos.

En la fracción de segundo final del proceso, `pg_squeeze` ejecuta un **Intercambio (Swap)**. Pide un bloqueo de milisegundos y le dice al catálogo de Postgres: *"A partir de ahora, el OID original leerá sus datos de este nuevo Relfilenode limpio"*.

Como la identidad lógica (el OID) jamás cambió, el resto de la base de datos ni siquiera se entera de que los datos se movieron de lugar. Tus llaves foráneas y reglas siguen funcionando perfectamente.

---

## El "Premio" Oculto: Reconstrucción Total de Índices

Cuando pasas una tabla por `pg_squeeze`, no solo limpias la tabla; **te llevas una desfragmentación total de sus índices de regalo**.

En Postgres, un índice guarda el valor (ej. "Juan") y su ubicación física en el disco (el número de página y línea). Como `pg_squeeze` mueve todas tus filas a un archivo físico nuevo, las ubicaciones cambian. Por obligación arquitectónica, la extensión debe reconstruir todos los índices desde cero apuntando a las nuevas direcciones.

¿El resultado? Tus índices B-Tree, GIN o GiST nacen 100% compactados, balanceados y rapidísimos, ahorrándote la necesidad de ejecutar comandos `REINDEX` posteriores.

---

## Seguridad ante Desastres

¿Qué pasa si el servidor se apaga a la mitad del proceso? Absolutamente nada.
La filosofía de `pg_squeeze` es atómica. Hasta que no se llega al 100% y se hace el intercambio de milisegundos, tu tabla original no sufre **ninguna** alteración. Si ocurre un error, Postgres aborta la operación, tira a la basura los archivos temporales ocultos, y tu tabla original sigue operando como si nada hubiera pasado.

### ⚠️ Lo que debes tener en cuenta (Limitaciones)

* **Requiere Identidad:** Tu tabla **debe** tener una Llave Primaria (Primary Key) o un Índice Único (`REPLICA IDENTITY`). Sin esto, el motor de replicación no sabe qué fila específica están actualizando los usuarios.
* **Cuidado con el Disco:** Si tienes un volumen de escrituras masivo (miles de transacciones por segundo) y el proceso es lento, los logs de transacciones (WAL) pueden acumularse en el disco mientras el Replication Slot espera ser procesado. Requiere monitoreo en bases de datos extremas.

## Conclusión

Para entornos modernos en la nube (como Google Cloud SQL o AWS RDS) donde no siempre tienes acceso por consola para ejecutar scripts externos complejos, **`pg_squeeze`** brilla con luz propia.

Al ser 100% nativo de la base de datos y contar con su propio motor de planificación tipo Cron (`squeeze.tables`), te permite automatizar la guerra contra el *bloat* en la madrugada, garantizando el rendimiento de tus aplicaciones sin sacrificar un solo segundo de disponibilidad.



# Link 
```
https://github.com/cybertec-postgresql/pg_squeeze
https://www.cybertec-postgresql.com/en/products/pg_squeeze/
https://www.cybertec-postgresql.com/en/introducing-pg_squeeze-a-postgresql-extension-to-auto-rebuild-bloated-tables/
```
