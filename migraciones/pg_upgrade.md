 
## 🚀 Guía Definitiva de `pg_upgrade`: ¿La mejor forma de actualizar Postgres?

### ¿Qué es y para qué sirve?

`pg_upgrade` es una utilidad de línea de comandos que permite actualizar los datos almacenados en una instancia de PostgreSQL a una versión mayor (por ejemplo, de la v13 a la v17) sin necesidad de un volcado de datos (`pg_dump`). Su función principal es transformar los archivos de control y metadatos del sistema para que sean compatibles con el nuevo binario.

### 🛠️ ¿Cómo funciona? (El truco del "Link")

A diferencia de otros métodos, `pg_upgrade` puede funcionar de dos formas:

1. **Copia (Default):** Copia físicamente cada archivo de datos. Requiere el doble de espacio en disco.
2. **Modo Link (`--link`):** ¡El favorito de los DBAs! En lugar de copiar, crea *hard links* entre los archivos de la versión vieja y la nueva. Esto permite actualizar terabytes de datos en apenas **segundos o minutos**, ya que no hay movimiento real de datos.

---

### ✅ Ventajas vs. ❌ Desventajas

| Ventajas | Desventajas |
| --- | --- |
| **Velocidad extrema:** Con el modo `--link`, el tiempo de inactividad es mínimo. | **Incompatibilidad de extensiones:** Si una extensión fue eliminada (como `adminpack` en v17), el proceso fallará. |
| **Eficiencia de espacio:** No necesitas espacio extra en disco si usas links. | **No hay vuelta atrás fácil:** Una vez que inicias el nuevo cluster en modo link, el viejo queda invalidado. |
| **Integridad:** Realiza chequeos previos (`--check`) para asegurar que la migración sea viable. | **Riesgo de corrupción:** Si el hardware falla durante el proceso de linking, puedes comprometer ambos clusters. |

---

### 🚫 Lo que NO puede hacer

* **Actualizar el Sistema Operativo:** `pg_upgrade` solo actualiza el motor de la base de datos, no el OS.
* **Cambiar la arquitectura:** No puedes pasar de un Postgres de 32 bits a uno de 64 bits.
* **Limpieza de datos:** A diferencia de `pg_dump`, no elimina la fragmentación ni el "bloat" de las tablas; los archivos pasan tal cual están.

---

### 🏆 Casos de Uso "Top" (Escenarios Reales)

1. **Bases de Datos de Multi-Terabytes:** Cuando tienes 10TB de datos, un `pg_dump` tardaría días. Aquí `pg_upgrade --link` es la única opción viable para mantener el SLA del negocio.
2. **Entornos de Nube (AWS RDS / Azure):** Los proveedores de nube utilizan internamente mecanismos basados en `pg_upgrade` para sus "In-place upgrades" automáticos.
3. **Actualizaciones de Seguridad Urgentes:** Cuando necesitas subir de versión rápidamente para parchar una vulnerabilidad crítica sin detener la operación por horas.

---

### 💡 Tip Pro para tu post: El paso previo indispensable

Antes de ejecutar la migración real, siempre se debe correr:

```bash
pg_upgrade --check

```

Este comando analiza si hay tipos de datos obsoletos, bibliotecas faltantes o extensiones conflictivas (como las que ya no existen en la versión 17 o 18) antes de tocar un solo bit de información.

---

# Ejemplo básico

`pg_upgrade` no adivina; es un comando que requiere ser alimentado con las rutas de ambas instalaciones (la vieja y la nueva) simultáneamente.

Para que `pg_upgrade --check` funcione, **ambas versiones de PostgreSQL deben estar instaladas en el servidor** al mismo tiempo.

Aquí te explico cómo el comando "sabe" qué comparar:

### Los parámetros clave

El comando utiliza banderas (*flags*) específicas para identificar el origen y el destino:

* **`-d` (old_datadir):** La ruta a la carpeta de datos de tu versión actual (ej. v13).
* **`-D` (new_datadir):** La ruta a la carpeta de datos de la versión nueva (ej. v17).
* **`-b` (old_bindir):** La ruta a los ejecutables (bin) de la versión vieja.
* **`-B` (new_bindir):** La ruta a los ejecutables de la versión nueva.

### Ejemplo de ejecución de un chequeo

Si estuvieras migrando de la versión 13 a la 17 en un sistema Linux, el comando se vería algo así:

```bash
pg_upgrade \
  --old-datadir /var/lib/postgresql/13/main \
  --new-datadir /var/lib/postgresql/17/main \
  --old-bindir /usr/lib/postgresql/13/bin \
  --new-bindir /usr/lib/postgresql/17/bin \
  --check

```

### ¿Qué hace realmente el `--check`?

Cuando ejecutas esto, el binario de la versión nueva (el `pg_upgrade` de la v17) "viaja" a la carpeta de la v13 y realiza lo siguiente:

1. **Verifica la compatibilidad de tipos:** Revisa si hay tipos de datos que ya no existen.
2. **Busca librerías compartidas:** Se asegura de que todas las extensiones que usas en la v13 (como `PostGIS`) tengan su versión correspondiente instalada en la v17.
3. **Valida nombres de funciones:** Comprueba si hay conflictos con palabras reservadas nuevas.
4. **Genera archivos `.txt`:** Si encuentra errores, crea archivos de texto detallados (como `tables_with_oids.txt` o `loadable_libraries.txt`) diciéndote exactamente qué arreglar antes de la migración real.

### El flujo de trabajo ideal :

1. **Instalar** la nueva versión (sin borrar la vieja).
2. **Inicializar** el nuevo cluster con `initdb`.
3. **Ejecutar** `pg_upgrade --check`.
4. **Corregir** errores (como el `DROP EXTENSION adminpack` que vimos antes).
5. **Ejecutar** el upgrade real (preferiblemente con `--link`).

 


---




```bash
postgres@test-server /usr/pgsql-15/bin $ $PGBIN15/pg_upgrade  --help
pg_upgrade upgrades a PostgreSQL cluster to a different major version.

Usage:
  pg_upgrade [OPTION]...

Options:
  -b, --old-bindir=BINDIR       old cluster executable directory
  -B, --new-bindir=BINDIR       new cluster executable directory (default
                                same directory as pg_upgrade)
  -c, --check                   check clusters only, don't change any data
  -d, --old-datadir=DATADIR     old cluster data directory
  -D, --new-datadir=DATADIR     new cluster data directory
  -j, --jobs=NUM                number of simultaneous processes or threads to use
  -k, --link                    link instead of copying files to new cluster
  -N, --no-sync                 do not wait for changes to be written safely to disk
  -o, --old-options=OPTIONS     old cluster options to pass to the server
  -O, --new-options=OPTIONS     new cluster options to pass to the server
  -p, --old-port=PORT           old cluster port number (default 50432)
  -P, --new-port=PORT           new cluster port number (default 50432)
  -r, --retain                  retain SQL and log files after success
  -s, --socketdir=DIR           socket directory to use (default current dir.)
  -U, --username=NAME           cluster superuser (default "postgres")
  -v, --verbose                 enable verbose internal logging
  -V, --version                 display version information, then exit
  --clone                       clone instead of copying files to new cluster
  -?, --help                    show this help, then exit

Before running pg_upgrade you must:
  create a new database cluster (using the new version of initdb)
  shutdown the postmaster servicing the old cluster
  shutdown the postmaster servicing the new cluster

When you run pg_upgrade, you must provide the following information:
  the data directory for the old cluster  (-d DATADIR)
  the data directory for the new cluster  (-D DATADIR)
  the "bin" directory for the old version (-b BINDIR)
  the "bin" directory for the new version (-B BINDIR)

For example:
  pg_upgrade -d oldCluster/data -D newCluster/data -b oldCluster/bin -B newCluster/bin
or
  $ export PGDATAOLD=oldCluster/data
  $ export PGDATANEW=newCluster/data
  $ export PGBINOLD=oldCluster/bin
  $ export PGBINNEW=newCluster/bin
  $ pg_upgrade

Report bugs to <pgsql-bugs@lists.postgresql.org>.
PostgreSQL home page: <https://www.postgresql.org/>

```
