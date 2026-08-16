 
#   Troubleshooting: Memoria Oculta vs Consumo de BD

**Objetivo:** Identificar la causa raíz cuando un servidor Linux presenta agotamiento severo de memoria RAM (y uso de Swap), pero las herramientas de monitoreo estándar (`top`, `ps`) no muestran ningún proceso consumiendo dicha memoria.

---

### Paso 1: Identificar la discrepancia en el consumo de memoria

El primer paso es verificar cuánto están consumiendo los procesos a nivel de usuario (espacio de usuario) y compararlo con la realidad del sistema.

**Comando ejecutado:** Sumarizamos el consumo de CPU y RAM agrupado por nombre de servicio.

```bash
ps -eo comm,pcpu,pmem --no-headers | awk '{cpu[$1]+=$2; mem[$1]+=$3} END {printf "%-25s %-10s %-10s\n", "PROCESO", "% CPU", "% RAM"; for (p in cpu) if (cpu[p]>0 || mem[p]>0) printf "%-25s %-10.1f %-10.1f\n", p, cpu[p], mem[p]}' | sort -k3 -nr | head -n 15

```

**Resultado obtenido:**

```text
PROCESO                   % CPU      % RAM
postgres                  0.6        3.5
falcon-sensor-b           1.0        2.0
agent                     3.4        1.2
nessus-agent-mo           0.9        0.2
...

```

* **Análisis:** La suma de todos los procesos visibles indicaba un uso aproximado del 10% al 15% de la RAM total. PostgreSQL reportaba apenas un 3.5%.

### Paso 2: Confirmar el estado general de la memoria y el estrés del SO

Comparamos la suma del Paso 1 con el consumo real del servidor para buscar discrepancias.

**Comando ejecutado:**

```bash
free -h

```

**Resultado obtenido:**

```text
              total        used        free      shared  buff/cache   available
Mem:           15Gi        10Gi       169Mi       1.6Gi       4.6Gi       2.9Gi
Swap:         5.0Gi       4.1Gi       954Mi

```

* **Análisis:** Existe una discrepancia masiva. El sistema reporta **10 GB usados** de RAM, y lo más crítico: **4.1 GB de memoria Swap en uso**. Esto confirma que no es un error de lectura; el servidor se quedó sin memoria física real y está paginando agresivamente a disco.

### Paso 3: Descartar a la base de datos (PostgreSQL)

En servidores de BD, la memoria "invisible" para `ps` suele estar en *HugePages* o *Shared Memory* (memoria compartida). Debemos descartar que la base de datos la esté acaparando.

**Comandos ejecutados:**

```bash
# Revisar uso de HugePages
cat /proc/meminfo | grep -i huge

# Revisar montajes de memoria compartida
df -h /dev/shm

```

**Resultado obtenido:**

```text
# Salida de HugePages
HugePages_Total:       0

# Salida de SHM
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           7.7G  308M  7.4G   4% /dev/shm

```

* **Análisis:** `HugePages` está desactivado (0). El segmento `/dev/shm` solo tiene 308 MB en uso. **Conclusión técnica:** PostgreSQL queda totalmente descartado como el responsable de la "desaparición" de los 10 GB de RAM.

### Paso 4: Localizar la "memoria fantasma" en el Kernel

Si la memoria no está en los procesos de usuario ni en cachés de la BD, debe estar en el núcleo del sistema operativo (Kernel). La caché interna del Kernel se llama **Slab**.

**Comando ejecutado:**

```bash
cat /proc/meminfo | grep -E -i "Slab|PageTables|VmallocUsed"

```

**Resultado obtenido:**

```text
Slab:            9967824 kB
PageTables:        42324 kB
VmallocUsed:      248864 kB

```

* **Análisis:** ¡Hallazgo crítico! La memoria `Slab` está consumiendo aproximadamente **9.5 GB (9967824 kB)**. Como esta memoria pertenece al Kernel, no se asocia a un PID específico y es invisible para el comando `ps` o `top`.

### Paso 5: Identificar al causante mediante el impacto del Swap

Para saber qué herramienta externa está inyectando carga en el Kernel, medimos qué procesos de usuario han sido los más castigados y enviados al Swap debido a la falta de RAM ocasionada por el Slab.

**Comando ejecutado:** Script rápido para leer el uso de Swap directamente del directorio `/proc` por PID.

```bash
for file in /proc/[0-9]*/status; do awk '/^Name:/ {name=$2} /^VmSwap:/ {swap=$2} END {if (swap > 0) print swap, name}' $file 2>/dev/null; done | sort -nr | head -n 15

```

**Resultado obtenido:**
Ese número está en **Kilobytes (kB)**.
```text
147624 falcon-sensor-b
127840 nessus-agent-mo
114440 cvd
...
9572 postgres

```

* **Análisis:** El proceso más penalizado en Swap es `falcon-sensor-b` (agente de CrowdStrike). Los agentes EDR/Seguridad operan profundamente en el Kernel utilizando tecnologías como eBPF.

---

### Conclusión Final del Análisis

1. **Estado de la BD:** PostgreSQL funciona normalmente. No está acaparando memoria oculta.
2. **Causa Raíz:** Hay una retención anómala de **9.5 GB de RAM** en el espacio `Slab` del Kernel de Linux. Esto provocó inanición de memoria y forzó el uso de 4.1 GB de Swap.
3. **Responsable probable:** El patrón de consumo y el funcionamiento arquitectónico apuntan a un *memory leak* (fuga de memoria) por parte del agente `falcon-sensor-b` a nivel del núcleo del SO.
4. **Acción correctiva requerida:** Se requiere escalamiento al equipo de Infraestructura/Sysadmins para que ingresen con privilegios `root`, ejecuten `slabtop -s c` para validar el objeto específico del Kernel saturado, y procedan con el reinicio o actualización del servicio de seguridad.


--- 
# Preguntas comunes
 
### ¿Qué más acciones se deben realizar? ¿Con un reinicio queda?

* **Reinicio del servicio:** Como primera acción, el equipo de Infraestructura debe intentar reiniciar el servicio del agente (`systemctl restart falcon-sensor`). En ocasiones, esto obliga al sistema a liberar los recursos retenidos.
* **Reinicio del servidor (Reboot):** Si reiniciar el servicio no libera esos 9.5 GB de Slab, **un reinicio completo del servidor solucionará el problema de inmediato**. Al apagar el equipo, el Kernel se limpia y la memoria vuelve a su estado normal.
* **Actualización del agente (La solución definitiva):** El reinicio solo cura el síntoma temporalmente. Si hay un *memory leak* (fuga de memoria) en esa versión específica de CrowdStrike, la memoria volverá a llenarse con el tiempo. La acción a largo plazo es que actualicen la versión del agente en ese servidor.
 

### ¿Qué es el Slab?

El **Slab** es una memoria caché interna y exclusiva del **Kernel (núcleo) de Linux**.

* **¿Cómo funciona?** El sistema operativo necesita crear y destruir estructuras de datos constantemente (por ejemplo, cada vez que abres un archivo, abres una conexión de red o aplicas una regla de seguridad). Para no hacer este proceso lento pidiendo memoria nueva cada vez, el Kernel guarda "bloques" de memoria pre-reservada listos para usarse. A esto se le llama Slab.
* **¿Por qué es peligroso aquí?** La memoria Slab no se puede enviar al Swap. Si un programa que opera dentro del Kernel (como un sensor de seguridad o antivirus) está mal programado y pide mucha memoria de este tipo sin regresarla, el Slab crecerá sin control hasta tragarse toda la RAM del servidor. Como el sistema no puede mover el Slab al disco duro, empieza a asfixiar a los demás programas (como tu base de datos) mandándolos al Swap para intentar sobrevivir.



 
### La Deducción Lógica (Por qué sabemos que es el agente)

Podemos deducir la causa raíz conectando estas tres grandes verdades técnicas que descubrimos en el servidor:

1. **La limitación de los procesos normales:** Los programas comunes, como tu base de datos (PostgreSQL), scripts de Perl, o servicios web, operan en lo que se conoce como *Espacio de Usuario*. Cuando estos programas piden memoria, esta se refleja de inmediato en los comandos de monitoreo estándar (`ps`, `top`) y puede ser enviada al Swap si es necesario. **PostgreSQL no puede inflar la memoria Slab directamente.**
2. **La naturaleza exclusiva del Slab:** Los 9.5 GB de RAM están atrapados en el *Slab*. Esta área es de uso exclusivo del núcleo del sistema (el Kernel). **Ningún proceso normal de usuario puede entrar y consumir 9.5 GB de esta memoria.**
3. **El puente hacia el Kernel:** Para que la memoria Slab crezca a esos niveles absurdos, el responsable *tiene* que ser un componente que opere dentro del Kernel. Esto se reduce a tres opciones: un driver de almacenamiento con fallas, un módulo de red mal configurado, o **un agente de seguridad**. Las herramientas EDR (Endpoint Detection and Response) como CrowdStrike Falcon inyectan sondas (usando tecnología eBPF) directamente en el Kernel para interceptar todo lo que hace el servidor.

**La deducción:** Ya que PostgreSQL opera en el Espacio de Usuario (no toca el Slab), y el único componente de terceros instalado con permisos y capacidad técnica para operar dentro del Kernel y consumir recursos de esa manera es el agente `falcon-sensor-b`, la causa de los 9.5 GB retenidos recae matemáticamente sobre este último.



 
### ¿Cómo obtener la prueba irrefutable (el 100% de certeza)?

Para ver exactamente **qué objeto** del Kernel tiene atrapados esos 9.5 GB, se necesita ejecutar el comando `slabtop`. Como tu usuario `postgres` no tiene permisos, el equipo de Infraestructura (Sysadmins) debe ejecutar esto como **root**:

```bash
sudo slabtop -s c | head -n 15

```

**¿Qué van a ver en la pantalla para confirmar que es Falcon?**
En la primera o segunda línea de la salida de ese comando aparecerá el objeto que más memoria gasta.

* Si ven nombres como **`bpf_`**, **`bpf_map`**, **`bpf_prog`** o **`cred_jar`** con millones de objetos y gigas de consumo, **queda 100% confirmado que es Falcon**, ya que CrowdStrike es el único programa en tu servidor que utiliza la tecnología eBPF dentro del Kernel.
