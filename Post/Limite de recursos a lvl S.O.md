 
## 1. ¿Qué es `cat /proc/<PID>/limits`?


```
[postgres@server-dev]$ pgrep -f "postgres -D"
9045
[postgres@server-dev]$  cat /proc/9045/limits
Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        629145600            unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             10240                10240                processes
Max open files            100000               100000               files
Max locked memory         65536                65536                bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       62897                62897                signals
Max msgqueue size         819200               819200               bytes
Max nice priority         0                    0
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us
```

En Linux, cada proceso tiene una "ficha técnica" en el sistema de archivos virtual `/proc`. El archivo `limits` te muestra los **Límites de Recursos (Resource Limits)** que tiene asignados ese proceso específico en tiempo real.

Sirve para saber hasta dónde tiene permitido llegar un proceso antes de que el kernel le diga "detente". Se dividen en dos tipos:
* **Soft Limit:** El límite que el proceso tiene actualmente. El proceso mismo puede aumentarlo si lo desea, pero nunca por encima del Hard Limit.
* **Hard Limit:** El techo máximo absoluto. Solo el usuario `root` puede subir este valor.

### Ejemplo de interpretación:
Si en tu comando viste:
* **Max open files: 100000**: Postgres puede abrir hasta 100k archivos simultáneamente (logs, tablas, conexiones).
* **Max processes: 10240**: El usuario `postgres` puede lanzar hasta 10k hilos o subprocesos.

> **Dato clave:** Si tu comando `COPY FROM PROGRAM` lanza un subproceso que intenta abrir más archivos de los permitidos aquí, el sistema lanzará un error de "Too many open files", pero no necesariamente un **Signal 9**. El Signal 9 suele venir de una capa superior... **Systemd**.

---

## 2. Límites con Systemd (Cgroups)

La mayoría de las bases de datos modernas no se lanzan "solas", las gestiona **Systemd**. Systemd usa una tecnología del kernel llamada **Control Groups (cgroups)**.

A diferencia de los límites individuales de `/proc`, los cgroups son como una "caja" de seguridad. Si el proceso (o sus hijos, como tu comando de shell) intenta salirse de esa caja, Systemd lo mata inmediatamente.

### ¿Para qué sirve?
Sirve para evitar que una consulta mal escrita o un proceso de mantenimiento (como tu análisis de logs) consuma toda la RAM del servidor y deje fuera de combate a otros servicios o al propio acceso SSH.

### Ejemplos de límites en Systemd:
Si editas el servicio de Postgres (`systemctl edit postgresql`), podrías ver o configurar esto:

* **`MemoryMax=2G`**: Si Postgres + tu script de Bash intentan usar 2.1GB, el kernel envía un **SIGKILL (Signal 9)**. Aquí es donde suele morir tu comando.
* **`CPUQuota=50%`**: No permite que el proceso use más de la mitad de un núcleo.
* **`TasksMax=1000`**: Limita el número total de procesos hijos.

---

## 3. ¿Cómo ver si Systemd está limitando a Postgres?

No lo verás en el archivo `limits` que me mostraste arriba (porque ese es el límite del proceso, no de la "caja" cgroup). Para verlo, usa este comando:

```bash
systemctl show postgresql | grep -E "Memory(Current|Max|Limit)"
```

* **MemoryCurrent:** Cuánta RAM está usando Postgres ahora mismo.
* **MemoryMax:** El límite real que, si se toca, provoca el **Signal 9**.

---

## Resumen de la Jerarquía de Control

| Nivel | Herramienta | Acción al excederlo |
| :--- | :--- | :--- |
| **Individual** | `/proc/PID/limits` | El sistema devuelve un error (ej. "Out of memory") pero el proceso sigue vivo. |
| **Contenedor** | **Systemd (Cgroups)** | El kernel envía un **SIGKILL (Signal 9)**. El proceso muere instantáneamente. |
| **Global** | **OOM Killer (Kernel)** | El kernel mata el proceso más "molesto" para salvar al sistema operativo. |

### Conclusión para tu caso:
Como viste que tus límites en `/proc` son "unlimited", pero recibes un **Signal 9**, la evidencia apunta a que:
1.  **Systemd** tiene un `MemoryMax` o `MemoryLimit` configurado.
2.  Tu comando, al procesar el log y guardar variables pesadas, golpea ese límite.
3.  Systemd decide que es más seguro matar a ese proceso hijo que dejar que agote la RAM.
 
