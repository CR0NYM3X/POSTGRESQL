 

## PROTOCOLO DE CONVERSIÓN Y MIGRACIÓN: DE SQL_ASCII A CLOUD SQL

Este proceso asume que el servidor actual seguirá operando mientras hacemos la prueba de concepto. No tocaremos los datos originales.

1. **Auditoría Forense de Bytes :** Descubrir qué hay realmente en la base de datos.
El primer paso es averiguar cómo insertó los datos la aplicación original. Si la base de datos es `SQL_ASCII`, pero todos los clientes (Windows, Linux, Web) insertaban texto usando `LATIN1` (ISO-8859-1) o `WIN1252`, entonces los bytes almacenados son `LATIN1` disfrazados de ASCII. Si los usuarios solo ingresaron caracteres en inglés (sin acentos ni eñes), el texto ya es compatible con UTF8.


2. **Extracción Lógica Forzada :** Generar el volcado de cuarentena.
No vamos a conectar Cloud SQL directamente a esta bomba de tiempo. Vamos a extraer los datos a un archivo de texto plano. Si sabemos que la aplicación original escribía en `LATIN1`, forzamos la conversión durante la extracción usando el parámetro `-E` de PostgreSQL:

`pg_dump -U tu_usuario -d tu_base_datos_ascii -E UTF8 -f dump_migracion.sql`

*Nota de Pedro:* Si PostgreSQL logra hacer la conversión al vuelo sin lanzar errores, significa que los bytes eran consistentes. Si falla, pasamos al Paso 3.


3. **Descontaminación Manual con Iconv (Si el Paso 2 falla):** Conversión a nivel de sistema operativo.
Si la base de datos tiene una "sopa de bytes" (múltiples codificaciones mezcladas), extraemos el volcado tal cual está (`SQL_ASCII`) y usamos el sistema operativo Linux para forzar la conversión de los caracteres corruptos hacia UTF8.

1. Extraer en crudo: `pg_dump -U tu_usuario -d tu_base_datos_ascii -f dump_crudo.sql`
2. Convertir con `iconv`: `iconv -f LATIN1 -t UTF-8 dump_crudo.sql > dump_utf8_limpio.sql`


4. **Despliegue y Aprovisionamiento :** Preparar la pista de aterrizaje en GCP.
En Google Cloud Platform, aprovisionamos la instancia de Cloud SQL for PostgreSQL 16. Por diseño, Cloud SQL nace en `UTF8`. Creamos la base de datos receptora con la configuración de intercalación (`LC_COLLATE` y `LC_CTYPE`) estándar: `en_US.UTF8` o `es_ES.UTF8` dependiendo de las reglas de negocio de tu cliente.


5. **Inyección de Datos y Validación:** Restaurar el volcado limpio.
Conectamos nuestra terminal al endpoint de Cloud SQL e inyectamos el archivo descontaminado:

`psql -h [IP_CLOUD_SQL] -U [usuario_cloud] -d [base_datos_nueva] -f dump_utf8_limpio.sql`

Si el archivo tiene un solo byte que no pertenezca a la tabla UTF8 válida, la inyección fallará. Este es nuestro mecanismo de defensa para asegurar que no entra basura a la nube.


---

### ⚠️ EL VETO  (Gatekeeper)

> "No le digas al cliente que la migración está lista hasta que hayas importado el dump en un entorno de **Staging** y hayas hecho un `SELECT` a las tablas principales buscando caracteres extraños (como los famosos  o diamantes negros con signos de interrogación). Si veo un solo texto mutilado en Cloud SQL, la migración es considerada un fracaso. Haz la prueba de fuego antes de tocar producción."

## Nota 
A Nivel Técnico (PostgreSQL): Son el mismo mapa de bytes. La única diferencia es semántica. ISO-8859-1 es el nombre del estándar en los libros de informática, y LATIN1 es el comando exacto que PostgreSQL te obliga a teclear en la terminal para aplicarlo.



----






## **iconv multi procesos**

 **`iconv` es estrictamente monohilo (single-threaded).** Por diseño de su binario en Linux, procesa el flujo de texto de forma secuencial. Si tienes un volcado de base de datos de 100 GB y un servidor con 32 núcleos, `iconv` va a saturar un solo núcleo al 100% mientras los otros 31 núcleos se quedan cruzados de brazos. Esto es inaceptable en ventanas de mantenimiento críticas.

Para llevar la conversión al límite físico de tu hardware, tenemos que aplicar el principio de "Divide y Vencerás" (MapReduce manual). No vamos a modificar `iconv`; vamos a usar las herramientas nativas de Linux (`split` y `xargs`) para despedazar el archivo, disparar múltiples procesos paralelos de `iconv` simultáneamente y volver a ensamblar los datos.

### ⚠️ REGLA DE SUPERVIVENCIA (El Veto de Samuel)

**Jamás cortes el archivo por tamaño de bytes (`split -b`).** Aunque `LATIN1` usa un byte por carácter, si en el futuro usas esto con codificaciones variables, cortar por bytes puede partir un carácter a la mitad y corromper el volcado. **Siempre cortaremos por líneas (`split -l`).**

Aquí tienes el protocolo táctico para saturar todos los núcleos de tu CPU en la conversión:

1. **División por Bloques (Split):** Despedazar el volcado original.
Vamos a dividir tu volcado gigante en archivos más pequeños, por ejemplo, de 500,000 líneas cada uno. El comando `split` es extremadamente rápido y eficiente en disco.

```bash
split -l 500000 dump_crudo.sql chunk_

```

Esto generará múltiples archivos llamados `chunk_aa`, `chunk_ab`, `chunk_ac`, etc.


2. **Ejecución Paralela Masiva (xargs):** Ataque de fuerza bruta con todos los núcleos.
Aquí es donde encendemos los motores. Usaremos `xargs` con la bandera `-P` (procesos concurrentes) y el comando `nproc` (que detecta dinámicamente cuántos núcleos físicos tiene tu servidor) para lanzar un `iconv` por cada núcleo disponible al mismo tiempo.

```bash
ls chunk_* | grep -v "\.utf8$" | xargs -n 1 -P $(nproc) -I {} sh -c 'iconv -f LATIN1 -t UTF-8 "{}" > "{}.utf8"'

```

*Nota:* Si tu servidor tiene 16 núcleos, este comando procesará 16 pedazos exactamente al mismo tiempo.


3. **Fusión Ordenada (Cat):** Reconstruir la línea de tiempo.
Una vez que los núcleos terminen, tendrás los pedazos originales y los pedazos convertidos (con extensión `.utf8`). Vamos a concatenar los archivos convertidos en orden alfabético para reconstruir el volcado SQL perfecto.

```bash
cat chunk_*.utf8 > dump_utf8_limpio.sql

```


4. **Limpieza Táctica (Rm):** Recuperación de almacenamiento.
El proceso consumirá el triple de espacio en disco temporalmente (el original, los pedazos y los pedazos convertidos). Una vez que verifiques que `dump_utf8_limpio.sql` existe y tiene un tamaño lógico, destruye la basura temporal.

```bash
rm chunk_*

```


---

### El Resultado en la Trinchera

Si tu disco tiene buenas velocidades de lectura/escritura (SSD/NVMe), este método reduce una conversión de 4 horas a tan solo 15 o 20 minutos, dependiendo del número de núcleos de tu servidor.
