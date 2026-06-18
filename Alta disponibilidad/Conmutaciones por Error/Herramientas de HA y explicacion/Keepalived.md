 
### ¿Qué es y para qué sirve Keepalived?

**Keepalived** es un software de enrutamiento escrito en C para sistemas Linux. Su propósito principal es doble:

1. **Alta Disponibilidad (HA - High Availability):** Evitar que haya un "punto único de fallo" (Single Point of Failure) en tu red o servicios.
2. **Balanceo de Carga:** Interactúa directamente con el módulo IPVS (IP Virtual Server) del kernel de Linux para balancear tráfico en capa 4.

En términos sencillos, sirve para asegurar que si un servidor principal (que aloja un servicio crítico) se cae, otro servidor secundario tome su lugar de manera casi instantánea y automática, sin que el usuario final note la caída.

---

### ¿Cómo funciona?

Keepalived se basa en un protocolo estándar llamado **VRRP (Virtual Router Redundancy Protocol)**.

El funcionamiento paso a paso es el siguiente:

1. **IP Virtual (VIP):** Configuras una dirección IP "flotante" que no pertenece permanentemente a la tarjeta de red (NIC) de ningún servidor físico. Los clientes siempre se conectan a esta VIP.
2. **Nodos Maestro y Respaldo:** Tienes al menos dos servidores. Uno asume el rol de *Master* (Maestro) y el otro de *Backup* (Respaldo).
3. **El Latido (Heartbeat):** El nodo Maestro transmite constantemente paquetes multicast (o unicast) a través de la red diciendo: *"Estoy vivo y tengo la VIP"*.
4. **El Failover:** Si el nodo Respaldo deja de recibir estos latidos durante un tiempo determinado (generalmente 1 o 2 segundos), asume que el Maestro ha muerto.
5. **Toma de control:** El nodo Respaldo se auto-promueve a Maestro, se asigna la VIP a su propia tarjeta de red y envía un paquete *Gratuitous ARP* a la red. Esto actualiza las tablas MAC de los switches, redirigiendo todo el tráfico de la VIP hacia el nuevo servidor.

---

### Casos de Uso Comunes

* **Alta disponibilidad para Balanceadores de Carga:** El dúo más famoso en Linux es **HAProxy + Keepalived** (o Nginx + Keepalived). Tienes dos HAProxy; si el principal falla, Keepalived mueve la IP al secundario para que el tráfico web no se detenga.
* **Alta disponibilidad de Bases de Datos:** En clústeres de MySQL o PostgreSQL (Primary/Replica). Si el servidor maestro de base de datos se cae, Keepalived mueve la IP de escritura al servidor réplica (a menudo ejecutando un script adicional para promover la réplica a maestro).
* **Routers de borde y Firewalls:** Mantener la conectividad a Internet de una red local teniendo dos firewalls (ej. pfSense o iptables) compartiendo la misma puerta de enlace (Gateway IP).
* **Clústeres de Kubernetes:** Para mantener en alta disponibilidad el *Control Plane* (API Server) en instalaciones *bare-metal* (On-Premise).

---

### Ventajas y Desventajas

| Ventajas | Desventajas |
| --- | --- |
| **Ligero y Rápido:** Consume muy pocos recursos de CPU/RAM y el cambio de IP ocurre en segundos. | **Split-Brain:** Si hay un problema de red donde ambos servidores están vivos pero no pueden verse entre sí, ambos reclamarán la VIP, causando conflictos de red severos. |
| **Nativo:** Interactúa profundamente con el kernel de Linux (Netlink y LVS). | **Limitación L2:** Tradicionalmente requiere que los nodos estén en la misma subred o dominio de broadcast (Capa 2). |
| **Fácil configuración:** Su archivo `keepalived.conf` es bastante intuitivo y declarativo. | **No replica datos:** Keepalived **solo mueve la IP**. No sincroniza archivos, sesiones web, ni datos de bases de datos. |
| **Soporte de Scripts:** Permite ejecutar *vrrp_scripts* personalizados para verificar la salud de un servicio (ej. "si el proceso de Nginx muere, suelta la VIP"). | **Problemas en la Nube:** Proveedores como AWS, Azure o GCP suelen bloquear paquetes VRRP o no permiten mover IPs a nivel de SO sin usar sus APIs. |

---

### Cuándo usarlo y cuándo NO usarlo

**✅ Cuándo SÍ usarlo:**

* En infraestructuras locales (*On-Premise*), *bare-metal* o máquinas virtuales tradicionales (VMware, Proxmox) donde tienes control total sobre la red y la Capa 2.
* Cuando necesitas un *failover* rápido de red (Capa 3/4) para servicios stateless (sin estado) o donde la replicación de datos ya está manejada por otro software (ej. replicación de base de datos nativa).
* Para arquitecturas Activo/Pasivo simples y efectivas.

**❌ Cuándo NO usarlo:**

* **En la nube pública (AWS, Azure, GCP):** Como mencioné, las redes SDN de las nubes públicas no manejan bien el ARP spoofing ni las IPs no asignadas. Usa sus balanceadores de carga administrados (ALB, NLB, Cloud Load Balancing).
* **Cuando necesitas clústeres complejos o Quorum:** Si tienes 3 o más nodos, recursos dependientes (montar discos compartidos SAN, levantar servicios en un orden específico), Keepalived se queda corto.
* **Arquitecturas Activo/Activo reales:** Keepalived en su estado más puro es Activo/Pasivo por VIP.

---

### Competencia y Alternativas

Si Keepalived no encaja en tus necesidades, el ecosistema Linux tiene otras opciones:

* **Pacemaker + Corosync:** Es la alternativa de "peso pesado". Corosync maneja la mensajería del clúster (quórum) y Pacemaker gestiona los recursos. Es mucho más complejo de configurar, pero evita el *split-brain* gracias al quórum (STONITH/Fencing) y puede gestionar servicios, discos compartidos y redes de manera orquestada.
* **UCARP / vrrpd:** Alternativas más antiguas a Keepalived para compartir IPs. Hoy en día están prácticamente en desuso porque Keepalived se ha convertido en el estándar de facto.
* **Kube-VIP / MetalLB:** Si estás en el mundo de Kubernetes *bare-metal*, estas herramientas modernas están reemplazando a Keepalived para proveer IPs virtuales y balanceo de carga nativo mediante BGP o ARP.




 ---




# Capa 2  o Capa 7
la herramienta cambia drásticamente dependiendo de la capa en la que estés trabajando (red vs. datos) y del nivel de criticidad del negocio.
 
### La Elección de la Comunidad (Startups, PyMEs y Tech Companies)

La comunidad Open Source, DevOps y Sysadmin elige por abrumadora mayoría **Keepalived** frente a alternativas como Pacemaker, **siempre y cuando se trate de la capa de red o balanceo de carga (stateless)**.

**¿Por qué eligen Keepalived?**

* **El principio KISS (Keep It Simple, Stupid):** Pacemaker y Corosync son bestias complejas. Configurar el quórum, los agentes de recursos y el *Fencing* (apagar un nodo a la fuerza si no responde) lleva días de diseño y pruebas. Keepalived se configura con un solo archivo de 30 líneas en 10 minutos.
* **Mantenimiento:** Un clúster de Pacemaker requiere mantenimiento constante y conocimiento especializado. Si algo falla, el clúster puede bloquearse a sí mismo (para proteger los datos). Keepalived es predecible; si el maestro cae, la IP pasa al esclavo, fin de la historia.
* **El estándar Web:** Para servidores web y APIs de microservicios, si un nodo se duplica (Split-Brain) a nivel de red, el impacto suele ser bajo (simplemente el balanceo se vuelve ineficiente temporalmente). Por ello, el combo **HAProxy + Keepalived** o **Nginx + Keepalived** es el estándar de facto.
 

### Entornos Financieros Críticos (Bancos, Fintechs, Trading)

En la banca y las finanzas, un escenario de **Split-Brain** (donde dos servidores creen ser el maestro al mismo tiempo) es el peor de los miedos. Si dos bases de datos están escribiendo transacciones simultáneamente de forma aislada, hay corrupción de datos, cuadrar los saldos es imposible y la empresa pierde millones (además de enfrentar multas regulatorias).

Por lo tanto, en el sector financiero, las herramientas se dividen estrictamente por capas:

#### 1. En la Capa de Entrada y Red (Edge / Load Balancing)

Aquí **SÍ se usa Keepalived**, pero a menudo compite con hardware dedicado.

* **Hardware Especializado (F5 BIG-IP, A10):** Muchos bancos prefieren pagar licencias millonarias por appliances físicos. Estos equipos tienen chips (ASICs) dedicados a manejar tráfico gigantesco, mitigar ataques DDoS y ofrecer Alta Disponibilidad propietaria e infalible.
* **Software (Keepalived):** Si el banco tiene una arquitectura moderna basada en software o nube privada, utilizan HAProxy o Nginx Enterprise junto con Keepalived. Al no haber bases de datos en esta capa, un pequeño fallo de red es tolerable frente al riesgo de corrupción de datos.

#### 2. En la Capa de Datos (Bases de Datos Core)

Aquí **NUNCA se confía únicamente en Keepalived**. Las arquitecturas financieras exigen **Sistemas de Quórum Estricto y Fencing**.

* **Pacemaker + Corosync:** Si usan bases de datos tradicionales en Linux, implementan esto junto con **STONITH** (Shoot The Other Node In The Head). Si hay un problema de red, el nodo sano envía una señal a la tarjeta de administración (iLO/iDRAC) del servidor defectuoso y le corta la energía eléctrica físicamente. Esto garantiza al 100% que el nodo caído no escribirá datos, evitando el Split-Brain.
* **Orquestadores de Consenso Modernos:** Para bases de datos Open Source críticas, se usan herramientas basadas en el protocolo Raft. Por ejemplo, en PostgreSQL financiero el estándar absoluto es **Patroni + etcd** o **Consul**. Estos sistemas requieren al menos 3 nodos (para tener mayoría o quórum de votos) para decidir quién es el maestro.
* **Soluciones Privativas:** En el núcleo bancario (Core Banking) tradicional, todavía domina **Oracle RAC (Real Application Clusters)** o sistemas IBM Mainframe, que tienen su propio software de alta disponibilidad extremadamente robusto y costoso.

En resumen: la comunidad ama la simplicidad de Keepalived para mover IPs rápidamente. Pero cuando el dinero real está en juego a nivel de base de datos, el sector financiero sacrifica esa simplicidad para implementar clústeres de quórum puro (Pacemaker/Patroni) o hardware especializado (F5) que garanticen matemáticamente la integridad de los datos.





----

# En que capa traba Keepalived

Keepalived es una herramienta fascinante porque no se limita a una sola capa del modelo OSI, sino que "baila" entre varias para lograr su objetivo.

Principalmente, Keepalived opera en las **Capas 2, 3 y 4**, y toca ligeramente la Capa 7 solo para tareas de monitoreo.

Aquí tienes el desglose exacto de lo que hace en cada capa:

### 1. Capa 2 (Enlace de Datos) - La magia del Failover

Aquí es donde Keepalived hace el trabajo sucio cuando un servidor se cae.

* **Gratuitous ARP:** Cuando el nodo Respaldo asume el control y toma la IP Virtual (VIP), envía un paquete *Gratuitous ARP* (Address Resolution Protocol) a la red de Capa 2.
* **El objetivo:** Le grita a todos los switches físicos y virtuales: *"¡Oye! Esta dirección IP ahora pertenece a mi dirección MAC, actualiza tus tablas"*. Sin esta acción en Capa 2, el tráfico seguiría yendo al servidor muerto.

### 2. Capa 3 (Red) - El Latido y las IPs

Esta es la capa donde vive su protocolo principal.

* **VRRP (Virtual Router Redundancy Protocol):** Los mensajes de "latido" (heartbeats) que los nodos de Keepalived se envían entre sí viajan en Capa 3. Utilizan paquetes IP multicast (generalmente a la dirección `224.0.0.18`) para saber quién está vivo y quién tiene la prioridad.
* **Gestión de IPs:** Keepalived interactúa directamente con la pila de red del kernel de Linux para agregar o eliminar direcciones IP en las interfaces de red físicas (`eth0`, `ens33`, etc.).

### 3. Capa 4 (Transporte) - El Balanceo de Carga

Si utilizas Keepalived no solo para alta disponibilidad, sino también como **balanceador de carga**, es aquí donde brilla.

* **Módulo IPVS:** Keepalived configura el módulo IPVS (IP Virtual Server) integrado en el kernel de Linux. Este módulo intercepta el tráfico y lo distribuye a los servidores traseros basándose en puertos TCP o UDP (por ejemplo, recibiendo tráfico en el puerto 80 y repartiéndolo).
* **Health Checks de Transporte:** Puede hacer comprobaciones TCP (intentar abrir un socket en un puerto específico) para saber si un servidor backend está sano antes de enviarle tráfico.

### 4. Capa 7 (Aplicación) - Solo para Monitoreo

Es importante aclarar: **Keepalived NO enruta tráfico en Capa 7**. No lee cabeceras HTTP, no mira cookies y no inspecciona certificados SSL (para eso debes usar HAProxy o Nginx detrás de Keepalived).

* **Scripts de Salud (Health Checks):** Lo único que hace en Capa 7 es *verificar* el estado de tus aplicaciones. Puede lanzar una petición HTTP GET a una URL para asegurarse de que devuelva un código `200 OK`, o ejecutar un script de bash/python personalizado que verifique la integridad de una base de datos. Si la verificación de Capa 7 falla, Keepalived suelta la VIP o saca al servidor del pool de balanceo.

 

En resumen: Keepalived usa la **Capa 3** para hablar con sus compañeros (VRRP), la **Capa 2** para robarse la IP (ARP) cuando el maestro falla, y la **Capa 4** para balancear el tráfico TCP/UDP hacia otros servidores.


