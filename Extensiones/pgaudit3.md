Tienes **toda la razón en dudar**, y de hecho acabas de tocar una de las confusiones más comunes al trabajar con pgaudit.

La respuesta corta es: **Sí están sirviendo**, pero lo que está ocurriendo es que **tienes la auditoría configurada a nivel global (instancia)** y no a nivel granular (base de datos o rol).

Te explico exactamente por qué ya te está registrando archivos sin haber ejecutado esos comandos SQL:

---

### 1. ¿Por qué ya está auditando sin `CREATE EXTENSION`?

En `pgaudit`, los binarios y la lógica principal se cargan en la memoria de PostgreSQL mediante la directiva `shared_preload_libraries = 'pgaudit, pgauditlogtofile'`.

* **No necesitas `CREATE EXTENSION pgaudit;**` para que el motor empiece a auditar la sesión si pgaudit está en `shared_preload_libraries` y configurado en el `postgresql.conf`.
* El comando SQL `CREATE EXTENSION pgaudit;` solo es estrictamente necesario si vas a utilizar la funcionalidad de **Auditoría de Objetos** (`pgaudit.num_target`, relaciones específicas) o si quieres gestionar las funciones/vistas de catálogo que trae la extensión dentro de la base de datos.

---

### 2. ¿Por qué captura todo sin usar los `ALTER DATABASE` o `ALTER ROLE`?

En tu archivo `postgresql.conf` definiste esta línea:

```ini
pgaudit.log = 'all'

```

Al poner `pgaudit.log = 'all'` directamente en el archivo de configuración global:

1. **Sobrescribes cualquier nivel granular:** Le estás diciendo al motor: *"Audita ABSOLUTAMENTE TODO en TODAS las bases de datos y para TODOS los usuarios"*.
2. Los comandos como `ALTER DATABASE orders SET pgaudit.log = 'read,write';` sirven para **acotar/personalizar** el comportamiento por base de datos. Pero como ya le dijiste a la instancia completa que audite `all`, las reglas más específicas quedan anuladas o redundantes.

---

### 3. El peligro de tu configuración actual en Producción ⚠️

Tener `pgaudit.log = 'all'` a nivel de `postgresql.conf` funciona, pero suele ser un **riesgo alto de rendimiento y espacio en disco** por lo siguiente:

* Audita cada `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CHECKPOINT`, lectura de catálogos internos, etc., de **todos los usuarios** (incluyendo procesos internos de PostgreSQL, réplicas, herramientas de monitoreo como Zabbix/Datadog, etc.).
* El archivo `/sysx/data17/data/log/audit-20260724.log` va a crecer a una velocidad tremenda en un entorno con carga real.

---

### 🎯 ¿Cuándo SÍ sirven los comandos que mencionas?

Sirven cuando quieres aplicar el **Principio de Menor Privilegio / Auditoría Selectiva**:

#### Escenario Ideal: Auditoría Granular

1. **En `postgresql.conf**` pones una configuración base (o lo dejas desactivado por defecto):
```ini
pgaudit.log = 'none' # o 'ddl, role' para solo auditar cambios de estructura/permisos globales

```


2. **Ajustas solo la base de datos crítica (`orders`)**:
```sql
ALTER DATABASE orders SET pgaudit.log = 'read, write, ddl';

```


*(Así las demás bases de datos de la instancia no saturan el disco).*
3. **O usas Auditoría por Rol (Rol de auditoría)**:
```sql
CREATE EXTENSION pgaudit; -- Requerido para auditar objetos específicos
CREATE ROLE user_audit NOLOGIN;
GRANT SELECT ON TABLE orders.facturas TO user_audit;

-- Le dices a pgaudit que solo audite cuando intervenga este rol
ALTER DATABASE orders SET pgaudit.role = 'user_audit';

```



---

### 💡 Resumen y Recomendación

* **¿Tu configuración funciona?** Sí, al 100%. `pgauditlogtofile` está capturando el flujo global que le ordenó `pgaudit.log = 'all'`.
* **¿Es necesaria la extensión/ALTERs ahora mismo?** No, para el alcance global que configuraste, no son necesarios.
* **Recomendación de experto:** Si estás en un entorno de desarrollo o pruebas, déjalo así para validar la ingesta de logs. Si estás en **producción**, retira `pgaudit.log = 'all'` del `postgresql.conf` y usa los `ALTER DATABASE / ROLE` para auditar únicamente lo que exige tu normativa de cumplimiento, evitando degradar los IOPS del servidor.


-------------
---



Aquí tienes la respuesta técnica precisa a tus dudas de jerarquía, junto con **4 casos de uso reales de producción** aplicando las mejores prácticas de auditoría.

---

### 1. Respuestas Rápidas a tus Preguntas

#### ¿Cuál prevalece si configuras ambos?

Si dejas `pgaudit.log = 'all'` en el `postgresql.conf` y ejecutas `ALTER DATABASE orders SET pgaudit.log = 'read, write, ddl'`, **prevalece `pgaudit.log = 'all'**`.
En `pgaudit`, **las configuraciones se combinan mediante una operación lógica OR**. Es decir, si algo está activo a nivel global, no lo puedes desactivar o limitar a nivel de base de datos o usuario. Para que las reglas granulares funcionen, el valor global en `postgresql.conf` debe ser más restrictivo (por ejemplo, `pgaudit.log = 'none'` o solo `'ddl, role'`).

#### ¿Tengo que hacer `CREATE EXTENSION` si uso `ALTER DATABASE`?

**No**, no es obligatorio si solo usas auditoría de **Sesión** (`pgaudit.log`).
Solo es **estrictamente obligatorio** hacer `CREATE EXTENSION pgaudit;` cuando vas a utilizar **Auditoría de Objetos** (`pgaudit.role`).

#### ¿Qué ventaja tengo al ejecutar `CREATE EXTENSION pgaudit;`?

* **Auditoría de Objetos ultra-específica**: Puedes auditar una sola tabla o columna confidencial (ej. números de tarjeta de crédito) sin auditar todo el sistema.
* **Integración con el catálogo de Postgres**: Registra los OIDs y estructuras de objetos correctamente para consultas avanzadas.
* **Control de acceso**: Permite a usuarios sin privilegios de superusuario consultar o administrar ciertas reglas de auditoría dentro de la base de datos si les otorgas los permisos sobre las funciones de la extensión.

---

---







---

### 📋 Resumen de Buenas Prácticas

| Nivel de Auditoría | Configuración Recomendada | Uso Típico |
| --- | --- | --- |
| **Global (`postgresql.conf`)** | `pgaudit.log = 'ddl, role'` | Seguridad mínima básica para todo el servidor. |
| **Por Base de Datos (`ALTER DATABASE`)** | `pgaudit.log = 'read, write'` | Ambientes regulados donde toda la BD está en alcance de auditoría. |
| **Por Objeto (`pgaudit.role` + `GRANT`)** | `pgaudit.log = 'none'` + `pgaudit.role` | Alta densidad de transacciones donde solo 2 o 3 tablas contienen PII (Información Personal Identificable). |
| **Excepción (`ALTER ROLE ... SET`)** | `pgaudit.log = 'none'` | Excluir procesos automatizados (ETL, Datadog, Zabbix, PgBouncer) para prevenir saturación de disco. |

---
---





postgres@postgres# CREATE EXTENSION pgaudit;
CREATE EXTENSION
Time: 7.032 ms


postgres@postgres#
postgres@postgres# \dx+ pgaudit
     Objects in extension "pgaudit"
+---------------------------------------+
|          Object description           |
+---------------------------------------+
| event trigger pgaudit_ddl_command_end |
| event trigger pgaudit_sql_drop        |
| function pgaudit_ddl_command_end()    |
| function pgaudit_sql_drop()           |
+---------------------------------------+
(4 rows)



Como puedes ver en la salida de tu `\dx+ pgaudit`, la extensión solo crea **4 objetos**:

1. **`function pgaudit_ddl_command_end()`**: Función interna invocada al finalizar cualquier sentencia DDL (`CREATE`, `ALTER`, `DROP`).
2. **`event trigger pgaudit_ddl_command_end`**: El disparador global que intercepta el fin de mandos DDL para auditar qué se cambió.
3. **`function pgaudit_sql_drop()`**: Función interna que procesa la eliminación de objetos.
4. **`event trigger pgaudit_sql_drop`**: El disparador global que intercepta la caída/borrado de objetos (`DROP TABLE`, `DROP ROLE`, etc.).

---

### 🔍 ¿Por qué solo instala estos 4 objetos?

Porque el verdadero "corazón" de `pgaudit` no vive en la base de datos como tablas o vistas SQL, sino en la memoria de PostgreSQL como un **Hook de C** a través de `shared_preload_libraries`.

* **Auditoría de Sesión y Sentencias DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`)**: Ocurre directamente en el motor de Postgres a nivel C interceptando el planificador/ejecutor de consultas. No necesita objetos en la BD para esto.
* **Auditoría DDL (`CREATE TABLE`, `DROP TABLE`, etc.)**: Aquí es donde entran en juego los **Event Triggers** que acabas de listar. Postgres no tiene un *hook* nativo de C para DDLs tan granular, así que `pgaudit` instala estos Event Triggers para no perder el rastro de cuándo alguien modifica la estructura de la base de datos.




