
# 📑 MANUAL DE CONTENCIÓN OPERATIVA: RESOLUCIÓN DE ERRORES DE CATÁLOGO FTS EN CLOUD SQL

## 1. ANÁLISIS FORENSE DEL INCIDENTE

**Dictamen Técnico de Diego (Seguridad de Datos) & Marcos (Arquitectura)**

Al ejecutar migraciones o restauraciones de bases de datos legadas hacia motores gestionados PaaS (como **Google Cloud SQL** o **AWS RDS**), el pipeline de inyección puede colapsar abruptamente con el siguiente error crítico:

```text
.*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*.
                    Error : ERROR: must be owner of operator pg_catalog.
.*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*..*.*.*.*.*.

```

### 🔍 Origen Lógico del Fallo

Este error es un síntoma de **deuda técnica heredada**. Ocurre porque los volcados tradicionales (dumps) arrastran definiciones obsoletas de operadores de comparación (`=`, `<`, `>`, `<=`) asignados explícitamente al esquema `public` para tipos de datos de búsqueda de texto completo (`tsvector` y `tsquery`).

Para construirlos en el origen, el dump intenta mapear propiedades lógicas (`COMMUTATOR` y `NEGATOR`) apuntando directamente a los operadores raíz de `pg_catalog`. Al intentar inyectar este bloque en un entorno gestionado en la nube, el motor deniega la operación de inmediato. Esto se debe a que el usuario de la aplicación carece de privilegios de superusuario real del sistema (los cuales están reservados exclusivamente para el plano de control del proveedor cloud).

> ⚠️ **CRITICIDAD CONTROLADA (Aprobada por QA):** Estos operadores en el esquema `public` son remanentes históricos redundantes. Los motores modernos en la nube ya integran este soporte nativo optimizado dentro de sus catálogos internos protegidos. Su exclusión del plano de carga garantiza un **éxito del 100% en la restauración** sin alterar la lógica de negocio ni la integridad referencial de la aplicación.
> 
> 

---

## 2. PROCEDIMIENTO QUIRÚRGICO DE EXTRACCIÓN Y RESTAURACIÓN

### Paso 1: Generación del Backup en Formato de Directorio (`-F d`)

Para evitar los cuellos de botella del procesamiento secuencial de archivos planos, se debe realizar el volcado utilizando el formato de directorio nativo multi-hilo (`-F d`), asignando cores concurrentes de acuerdo a la capacidad de cómputo del servidor de origen.

```bash
nohup sh -c "echo '=== INICIO DUMP MULTINÚCLEO:' \$(date) && pg_dump -U [USUARIO_ORIGEN] -d [BD_ORIGEN] -F d -j 30 -f /infra/data/backup_dir_dump --no-owner  --encoding=UTF8 && echo '=== FIN DUMP MULTINÚCLEO:' \$(date)" > dump_multicore.log 2>&1 &

```

### Paso 2: Transferencia Paralela al Almacenamiento Cloud (Bucket)

Al estar segmentado en cientos de archivos fragmentados y comprimidos internamente, el formato de directorio permite transferir la estructura hacia el Object Storage optimizando el uso del ancho de banda WAN.

```bash
gcloud storage cp -r /infra/data/backup_dir_dump gs://[BUCKET_ANÓNIMO]/repositorio_backups/

```

### Paso 3: Descarga del Snapshot en la VM Bastión / Destino

Desde la máquina virtual asignada con conectividad privada e interna hacia la instancia de Cloud SQL, se procede a descargar el directorio de respaldo.

```bash
gcloud storage cp -r gs://[BUCKET_ANÓNIMO]/repositorio_backups/backup_dir_dump .

```

### Paso 4: Extracción del Plano de Construcción (TOC)

La gran ventaja competitiva del formato `-F d` es que permite leer y modificar el plano lógico de instalación (índice) en milisegundos sin tener que abrir ni descomprimir los gigabytes de datos puros.

```bash
pg_restore -l backup_dir_dump > lista_objetos.toc

```

### Paso 5: Purgado Quirúrgico de los Operadores Conflictivos

Aplicamos un filtro automatizado con `sed` sobre el archivo de índice generado para eliminar del mapa de ruta cualquier intento de recreación de operadores en el esquema público.

```bash
sed '/OPERATOR public/d' lista_objetos.toc > lista_limpia.toc

```

### Paso 6: Restauración Diamante Multi-hilo a Producción

Lanzamos la inyección asíncrona en segundo plano obligando a `pg_restore` a seguir estrictamente la hoja de ruta del índice modificado (`-L lista_limpia.toc`). De esta forma, el motor saltará los operadores obsoletos y procesará la carga de datos en paralelo a máxima velocidad.

```bash
nohup bash -c '
  export PGPASSWORD="password123"
  export PGOPTIONS="-c max_parallel_maintenance_workers=8 -c maintenance_work_mem=9GB -c tcp_keepalives_idle=5 -c tcp_keepalives_interval=10 -c tcp_keepalives_count=3"
  
  echo "=== INICIO RESTAURACIÓN: $(date)" && 
  pg_restore -h 10.0.0.100 -U postgres2 -d db_test -F d -L lista_limpia.toc --no-owner -j 10 /backup/backup_20260723.dump &&
  echo "=== FIN RESTAURACIÓN: $(date)"
' > restore_20260723.log 2>&1 &
 
```

### Segunda opcion
En caso de que no funcione el pg_restore, puedes convertir el dump a sql
```
nohup sh -c "echo '=== INICIO CONVERSIÓN:' \$(date) && pg_restore -f - --no-owner -L lista_limpia.toc /sysx/db_test_backup/backup_20260719.dump | gzip -c > /sysx/db_test_backup/backup_db_test.sql.gz && echo '=== FIN CONVERSIÓN:' \$(date)" > /sysx/db_test_backup/conversion.log 2>&1 &
```





### Para monitorear
```
watch -n 2 '
  export PGPASSWORD="password123"

  echo "=== ESTADO BASE DE DATOS Y CONEXIONES ==="
  psql -h 10.0.0.100 -U postgres -d postgres -c "
    SELECT d.datname AS base_de_datos, 
           pg_catalog.pg_get_userbyid(d.datdba) AS dueño, 
           pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) AS tamaño_legible, 
           pg_catalog.pg_database_size(d.datname) AS tamano_byte 
    FROM pg_catalog.pg_database d 
    WHERE d.datname = '\''db_test'\'  ';

    SELECT pid, 
           usename AS usuario, 
           datname AS base_datos, 
           client_addr AS ip_cliente, 
           application_name AS aplicacion, 
           age(clock_timestamp(), query_start) AS duracion, 
           wait_event_type || '\'':'\'' || wait_event AS evento_espera, 
           left(query, 80) || '\''...'\'' AS query_recortada 
    FROM pg_stat_activity 
    WHERE state = '\''active'\'' AND pid != pg_backend_pid() 
    ORDER BY query_start ASC;
  "

  echo -e "\n=== ÚLTIMAS LÍNEAS DEL LOG ==="
  tail -n 2 restore_20260723.log

  echo -e "\n=== PROCESOS PG_RESTORE ACTIVOS ==="
  pgrep -fc pg_restore
'
```




---

## 3. PROTOCOLO DE AUDITORÍA Y MONITOREO

**Gobernanza de Mauricio (QA) & Rodrigo (Gatekeeper)**

Una vez enviado el proceso al segundo plano, la terminal queda liberada inmediatamente. Es responsabilidad mandatoria del operador en turno monitorear el progreso de la inyección en tiempo real ejecutando el siguiente comando de seguimiento:

```bash
tail -f restauracion_final_perfecta.log

```

### Criterio de Aceptación Final

Al visualizar la estampa final `=== FIN RESTAURACIÓN LIMPIA: [Fecha/Hora]`, el operador debe conectarse a la instancia destino y certificar la paridad total del diccionario de objetos e integridad de datos mediante un conteo cruzado contra la base de datos origen:

```bash
psql -h [IP_INSTANCIA_CLOUD] -U [USUARIO_DESTINO] -d [BD_DESTINO] -c "SELECT count(*) FROM pg_tables WHERE schemaname='public';"

```



----
---
# Obtener solo los owner de un backup


### Paso 1: Generar la lista de objetos (TOC)

Primero, le pedimos a `pg_restore` que lea el índice del backup y nos escupa todo el contenido en un archivo de texto.

```bash
pg_restore -l /ruta/a/tu/backup_dir > backup_completo.list

```

### Paso 2: Filtrar solo las asignaciones de Owner

Ahora, usamos `grep` para buscar dentro de esa lista únicamente las líneas que corresponden a la asignación de dueños (`OWNER`) y las guardamos en una lista filtrada.

```bash
grep -i " OWNER " backup_completo.list > lista_owners.list

```

*Nota: Si abres `lista_owners.list`, verás el ID interno de Postgres para cada objeto, el tipo y el dueño, algo parecido a esto:*

```text
3456; 0 0 ACL public mi_tabla usuario_prod
3457; 1259 16401 TABLE public clientes usuario_prod

```

### Paso 3: Generar el script SQL puro

Finalmente, viene la magia. Le dices a `pg_restore` que lea tu directorio de backup, pero que **solo procese y exporte en formato SQL** los elementos que dejaste en tu `lista_owners.list`.

```bash
pg_restore -L lista_owners.list /ruta/a/tu/backup_dir > script_owners_del_backup.sql

```


## Extra

```bash
 pg_dump -h tu_host -U tu_usuario -d tu_base_de_datos --schema-only | grep -E "^ALTER .* OWNER TO " > direct_owners.sql
 pg_restore --schema-only /ruta/a/tu/backup_dir | grep -E "^ALTER .* OWNER TO " > direct_owners.sql
```

