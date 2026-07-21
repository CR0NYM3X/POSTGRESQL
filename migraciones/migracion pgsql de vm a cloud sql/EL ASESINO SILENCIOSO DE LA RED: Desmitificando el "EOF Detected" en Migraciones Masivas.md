 
# EL ASESINO SILENCIOSO DE LA RED: Desmitificando el "EOF Detected" en Migraciones Masivas

## 1. El Escenario del Crimen

Durante la restauración masiva de una base de datos utilizando `pg_restore`, el proceso avanza perfectamente inyectando datos (`COPY`). Sin embargo, al llegar a la fase de creación de índices complejos (`CREATE INDEX`), el proceso muere abruptamente con el siguiente error en la consola del cliente:

> `pg_restore: error: could not execute query: SSL SYSCALL error: EOF detected`
> `pg_restore: error: could not execute query: no connection to the server`

**El síntoma más desconcertante:** Al revisar los registros (logs) del servidor de PostgreSQL en la nube, no hay rastro de OOM Killer, no hay fallas de CPU, no hay bloqueos. El servidor simplemente reporta que la conexión se cerró inesperadamente.

## 2. El Silencio que Nadie Notó (La Causa Raíz)

El problema no es la base de datos ni tu computadora; el problema es **el intermediario** (El Balanceador de Carga, Firewall o Proxy de la nube).

Cuando `pg_restore` envía el comando `CREATE INDEX`, el servidor de PostgreSQL recibe la orden y pone a sus procesadores a trabajar al 100% para ordenar millones de filas. Sin embargo, durante los 10, 20 o 30 minutos que tarda en construirse ese índice, **no viaja ni un solo byte de información a través del cable de red**.

Los balanceadores de carga en arquitecturas Cloud (GCP, AWS, Azure) tienen reglas estrictas para evitar ataques de denegación de servicio (DDoS) o conexiones fantasma. Al ver un canal TCP en completo silencio durante más de 5 o 10 minutos, el balanceador asume que la máquina cliente "desapareció" y **corta el cable físicamente**.

Esta es la razón por la que el log de PostgreSQL está limpio: el servidor nunca falló, simplemente el balanceador le cortó el puente de comunicación con el cliente.

## 3. La Trampa de la Direccionalidad (Por qué fallan los intentos iniciales)

El instinto natural de un DBA es buscar en la documentación de PostgreSQL y aplicar parámetros de *Keepalive* (latidos de red) para mantener la conexión despierta. Aquí es donde ocurre el error arquitectónico más común.

Existen tres formas de forzar estos latidos, pero sus impactos y puntos de origen son radicalmente distintos:

### Análisis Táctico de Soluciones de Red (TCP Keepalives)

| Comando / Variable | Nivel de Acción | ¿Quién dispara el Latido (Ping)? | Resultado ante el Balanceador Cloud | Veredicto del Escuadrón |
| --- | --- | --- | --- | --- |
| **`PGOPTIONS="-c tcp_keepalives_..."`** | Servidor (Motor BD) | El Servidor hacia el cliente. | **Falla Misión.** El balanceador solo ve que el cliente sigue en silencio y corta la conexión de tu lado. | ❌ **TRAMPA OPERATIVA.** Le estás dando la medicina al paciente equivocado. |
| **`sudo sysctl -w net.ipv4...`** | Sistema Operativo | El Kernel del Cliente hacia el Servidor DB. | **Éxito.** El balanceador ve tráfico y mantiene la red viva. | ⚠️ **NUCLEAR.** Resuelve el problema, pero altera el comportamiento de red de *todos* los programas de tu PC. |
| **`PGTCPKEEPALIVES=1...`** | Aplicación Cliente (`libpq`) | Tu comando `pg_restore` hacia el Servidor DB. | **Éxito.** El balanceador recibe latidos exclusivos de tu proceso de restauración. | ✅ **ESTÁNDAR DE ÉLITE.** Quirúrgico, seguro y no deja residuos en el sistema operativo. |

## 4. El Estándar Operativo para Migraciones Cloud (Resolución)

Para evitar que el balanceador de carga aniquile operaciones de larga duración por inactividad de red, **es obligatorio** inyectar variables de entorno directamente a la librería cliente de PostgreSQL (`libpq`) justo antes de la ejecución del comando.

**El Comando Homologado:**
Se debe envolver la ejecución de herramientas como `psql`, `pg_dump` o `pg_restore` con las siguientes variables de entorno en la misma línea:

```bash
PGTCPKEEPALIVES=1 PGTCPKEEPALIVEIDLE=5 PGTCPKEEPALIVEINTERVAL=5 PGTCPKEEPALIVECOUNT=3 pg_restore -h HOST -U USUARIO -d BASE_DATOS archivo.dump

```

**Anatomía del Blindaje de Red:**

* **`PGTCPKEEPALIVES=1`**: Enciende el motor de latidos desde el lado del cliente.
* **`PGTCPKEEPALIVEIDLE=5`**: Instruye a la herramienta a que, si pasan 5 segundos en silencio total (esperando un índice), dispare un pulso TCP.
* **`PGTCPKEEPALIVEINTERVAL=5`**: Si el pulso no es respondido, dispara otro cada 5 segundos.
* **`PGTCPKEEPALIVECOUNT=3`**: Solo declara la conexión como muerta si fallan 3 pulsos consecutivos.

**Comando final**
```SQL
PGPASSWORD='miPassword123' PGTCPKEEPALIVES=1 PGTCPKEEPALIVEIDLE=5 PGTCPKEEPALIVEINTERVAL=5 PGTCPKEEPALIVECOUNT=3 nohup sh -c "echo '=== INICIO RESTAURACIÓN:' \$(date) && pg_restore -h 10.0.0.100  -U postgres -d db_test -F d --no-owner -j 7  /sysx/backup_20260719.dump && echo '=== FIN RESTAURACIÓN:' \$(date)" > resultado_inspeccion.log 2>&1 &
```

## 5. Resumen Ejecutivo (TL;DR)

Si tu base de datos procesa una tarea masiva y la conexión muere con `EOF detected`, no busques errores en el servidor. Tu balanceador de carga cortó la conexión por inactividad. **Nunca** uses `PGOPTIONS` para solucionar cortes del cliente; la actividad debe originarse en la herramienta que espera la respuesta. Utiliza siempre las variables de entorno `PGTCPKEEPALIVES` para bombardear al balanceador con latidos y mantener el canal de comunicación abierto de forma quirúrgica y limpia.


## 📐 PARTE 1: DIFERENCIA ENTRE `pre-data`, `data` Y `post-data`

Cuando PostgreSQL realiza un respaldo en formato de directorio (`-F d`) o *Custom* (`-F c`), divide lógicamente todo el contenido de la base de datos en **3 secciones independientes**. Puedes restaurarlas juntas o por separado mediante la bandera `--section`:

```
   [ ARCHIVO DE RESPALDO / DUMP ]
                 │
   ├── 1. PRE-DATA  ──> (Crea el Cascarón / Tablas vacías)
   ├── 2. DATA      ──> (Inyecta los Gigabytes de registros)
   └── 3. POST-DATA ──> (Construye Índices, LLaves Foráneas y Triggers)

```

### Error
el error que se comete muy frecuente es usar `-j` en la etapa de `post-data`.
Las claves foráneas e índices tienen dependencias entre sí; cargarlas en paralelo con `-j` suele generar bloqueos de tablas (*locks*) y fallos de referencia.

**Para ejecutar el `post-data` correctamente:**
 **NO uses `-j`** (ejecuta en un solo hilo).


## Info extra

```

sysctl net.ipv4.tcp_keepalive_time net.ipv4.tcp_keepalive_intvl net.ipv4.tcp_keepalive_probes

# Esto forzará al sistema operativo a enviar latidos de red cada 5 segundos tras apenas 10 segundos de inactividad:
sudo sysctl -w net.ipv4.tcp_keepalive_time=60
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=10
sudo sysctl -w net.ipv4.tcp_keepalive_probes=3


```
