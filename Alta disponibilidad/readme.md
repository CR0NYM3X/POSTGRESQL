
### Ruta de aprendizaje 
*** Replicas *** 
- Citus - Pendiente 
- PgLogical - Pendiente
- BDR
- PostgreSQL-XL
- Patroni + etcd
- Stolon
- YugabyteDB - Open Source [Multi-Master]

*** Pool de conexiones *** 
- PgBouncer - Pendiente 

*** Balanceadores de carga *** 
- PgPool-II - Pendiente
- HaProxy - Pendiente
- Keepalived - Pendiente

*** Failover *** 
- RepGMR - Listo
- pg_auto_failover
- Patroni - Pendiente
- pglookout
- Pacemaker y Corosync
```
                +-------------------+
                |     Aplicación    |
                +-------------------+
                         │
                         ▼
                +-------------------+
                   │           │
                   ▼           ▼
           +-------------+ +-------------+
           | PgBouncer 1 | | PgBouncer 2 |  ← Balanceados + VIP
           +-------------+ +-------------+
                   │           │
                   ▼           ▼
           +-------------+ +-------------+ +-------------+
           | Pgpool-II 1 | | Pgpool-II 2 | | Pgpool-II 3 | ← Watchdog + VIP
           +-------------+ +-------------+ +-------------+
                   │           │           │
                   └────┬──────┴──────┬────┘
                        ▼             ▼
		+-----------+   +-----------+   +-----------+
		| PostgreSQL|   | PostgreSQL|   | PostgreSQL|
		|  Primario |   |  Réplica  |   |  Réplica  |
		+-----------+   +-----------+   +-----------+
```

### 🔹 **BCP – Business Continuity Plan (Plan de Continuidad del Negocio)**
Es un conjunto de estrategias y procedimientos diseñados para asegurar que una organización pueda **continuar operando durante y después de una interrupción significativa** (como desastres naturales, ciberataques, fallas técnicas, etc.).  
Incluye aspectos como:
- Procesos críticos del negocio
- Recursos mínimos necesarios
- Planes de comunicación
- Procedimientos alternativos


 
## 🧠 ¿Qué es un  **DRP – Disaster Recovery Plan (Plan de Recuperación ante Desastres)**?

Un **DRP** es un conjunto de políticas, procedimientos y herramientas diseñadas para **recuperar sistemas críticos y datos** después de un evento disruptivo (como una caída del servidor, ransomware, incendio, etc.).
, Es un subconjunto del BCP, enfocado específicamente en la **recuperación de sistemas tecnológicos y datos** después de un evento disruptivo.  
Incluye:
- Respaldos y restauración de datos
- Recuperación de servidores y redes
- Procedimientos técnicos para volver a operar


---

### 🧭 ¿Para qué sirve la documentación de un DRP?
La documentación de un **DRP (Disaster Recovery Plan)** es una herramienta esencial para garantizar la **resiliencia tecnológica** de una organización. Tener el DRP documentado no solo es una buena práctica, sino que puede **salvar tu operación** cuando todo lo demás falla. ¿Quieres que te ayude a armar una plantilla básica o revisar si tu documentación cubre lo esencial?

1. **Establece procedimientos claros** para recuperar sistemas críticos tras un desastre (fallo de hardware, ciberataque, incendio, etc.).
2. **Minimiza el tiempo de inactividad** y la pérdida de datos.
3. **Asigna responsabilidades**: quién hace qué, cuándo y cómo.
4. **Facilita auditorías y cumplimiento normativo** (por ejemplo, ISO 27001, PCI-DSS).
5. **Sirve como guía de entrenamiento** para nuevos miembros del equipo de TI o seguridad.



### 🧪 Escenarios donde es útil

- **Caída de servidores o bases de datos**: el DRP indica cómo restaurar servicios desde respaldos o sitios alternos.
- **Ataques de ransomware**: define cómo aislar sistemas, restaurar datos y comunicar el incidente.
- **Errores humanos o fallos de software**: permite revertir cambios o recuperar versiones anteriores.
- **Desastres naturales**: si tu centro de datos queda inutilizado, el DRP detalla cómo operar desde una ubicación secundaria.


### 📚 ¿Qué debe incluir la documentación?

- Inventario de sistemas críticos.
- Procedimientos de respaldo y restauración.
- Contactos de emergencia.
- Planes de comunicación interna y externa.
- Cronogramas de recuperación (RTO/RPO).
- Resultados de pruebas y simulacros.

---


---

## 🕒 ¿Qué es RPO y RTO?
No hay una fórmula matemática universal para calcular el RTO y el RPO, porque dependen de factores específicos del negocio, el tipo de servicio y el impacto que tendría una interrupción. Pero sí hay métodos estructurados para estimarlos con precisión.

### 🔁 **RPO (Recovery Point Objective)**

- **¿Qué mide?**  
Es la **cantidad máxima de datos que puedes permitirte perder** si ocurre un fallo.  
 *¿Cuánta información puedo perder sin que sea un desastre?*

### ⏱️ **RTO (Recovery Time Objective)**

- **¿Qué mide?**  
Es el **tiempo máximo que una empresa puede estar sin operar** tras un fallo antes de que haya consecuencias graves. En otras palabras:  
 *¿Cuánto tiempo puedo estar fuera de servicio sin que me cueste demasiado caro?*


###  ¿Cómo se calcula el **RTO**?


**Pasos para estimarlo:**
1. **Identifica el servicio o sistema.**
2. **Evalúa el impacto de su caída** (económico, legal, reputacional).
3. **Consulta con usuarios y responsables** cuánto tiempo pueden operar sin él.
4. **Define el tiempo máximo tolerable de inactividad.**

> Ejemplo: Si un sistema de pagos genera $10,000 por hora, y estar inactivo más de 2 horas implica pérdida de clientes, tu RTO sería **2 horas**.

 
###  ¿Cómo se calcula el **RPO**?

**Pasos para estimarlo:**
1. **Analiza la frecuencia de cambios en los datos.**
2. **Determina cuánto tiempo puedes retroceder sin perder información crítica.**
3. **Evalúa el impacto de perder datos recientes.**

> Ejemplo: Si haces respaldos cada 4 horas y puedes tolerar perder hasta 4 horas de datos, tu RPO es **4 horas**.




## 📌 ¿Por qué son importantes?

| Concepto | ¿Por qué importa? |
|----------|-------------------|
| **RPO** | Define la frecuencia de respaldos. Si tu RPO es bajo, necesitas respaldos frecuentes o replicación. |
| **RTO** | Define la velocidad de recuperación. Si tu RTO es bajo, necesitas infraestructura lista para restaurar rápido. |
| **DRP** | Asegura que todos sepan qué hacer en caso de desastre. Reduce el caos y el tiempo de inactividad. |



###  Escenario práctico: una tienda en línea

Imagina que tienes una tienda online que vende productos 24/7.

- Haces **copias de seguridad cada 6 horas**.
- Si el sistema se cae, puedes **restaurarlo en 2 horas**.

Entonces:

- **RPO = 6 horas** → podrías perder hasta 6 horas de pedidos si el sistema falla justo antes de la siguiente copia de seguridad.
- **RTO = 2 horas** → necesitas que todo vuelva a funcionar en máximo 2 horas para no perder ventas ni reputación.


### ¿Qué pasa si no cumples con esos tiempos?

- Si el **RTO** se extiende a 5 horas, podrías perder miles en ventas y clientes molestos.
- Si el **RPO** es mayor, podrías perder pedidos, datos de clientes o inventario actualizado.


## ✅ Beneficios de tener RPO, RTO y DRP bien definidos

- Menor impacto financiero.
- Protección de la reputación.
- Cumplimiento de normativas (como ISO 27001, GDPR).
- Mayor confianza del cliente y del equipo interno.

---

 ### 🔹 **CMP – Crisis Management Plan (Plan de Gestión de Crisis)**
Es el plan que define cómo una organización **responde a una crisis** (ya sea reputacional, operativa, legal, etc.) para minimizar el impacto y restaurar la normalidad.  
Incluye:
- Roles y responsabilidades del equipo de crisis
- Protocolos de comunicación interna y externa
- Escenarios de crisis y respuestas planificadas



---

# Diponibilidad 

###   **¿Por qué es importante medir la disponibilidad?**

Porque la **disponibilidad refleja de forma directa la confiabilidad real de tus servicios**. Conocer este dato te permite:

- **Cumplir con los SLAs (acuerdos de nivel de servicio)** prometidos a clientes o usuarios internos.
- **Tomar decisiones objetivas** sobre cuándo necesitas invertir en réplicas, balanceo, failover o mejoras de infraestructura.
- **Justificar el presupuesto** y el valor del área de TI: si puedes demostrar una disponibilidad del 99.98 %, estás protegiendo ingresos, productividad y reputación.
- **Simular escenarios de falla o mejora**, usando MTBF/MTTR, para reducir tiempos de recuperación o aumentar el tiempo entre fallos.
- **Prepararte para auditorías o certificaciones** de calidad y continuidad operativa.


###  Cómo obtener esos datos en la práctica

1. **Monitoreo de uptime**: Usa herramientas como Prometheus, Zabbix, Nagios o Datadog para registrar el tiempo de actividad e inactividad de tus servicios.
2. **Logs de eventos y alertas**: Revisa los registros de failover, caídas de red, reinicios inesperados, etc.
3. **SLA y reportes automáticos**: Mediante un proveedor que exige un SLA. Muchas plataformas generan reportes mensuales de disponibilidad. 
4. **Dashboards**: Grafana es ideal para visualizar la disponibilidad en tiempo real y generar históricos.

###  Consejo extra
Si ya tienes HA implementado, asegúrate de que tus herramientas de monitoreo estén midiendo la **disponibilidad del servicio final**, no solo la del nodo principal. A veces un nodo falla pero el sistema sigue funcionando gracias al failover, y eso **no debería contar como caída**.



### Fórmula 1 (MTBF y MTTR): [[1]](https://simpliroute.com/es/blog/mttr-mtbf) [[2]](https://www.emaint.com/es/mtbf-mttf-mttr-maintenance-kpis/)


Cuando usarlo: Para planificar, hacer simulaciones predictivas, justificar inversiones o diseñar alta disponibilidad, Explicar el impacto de la confiabilidad del sistema a áreas no técnicas, usa la fórmula con MTBF/MTTR.

- **MTBF (Mean Time Between Failures)** = cuánto tiempo un sistema duro funcionando correctamente antes de fallar.
- **MTTR (Mean Time To Repair)** = cuánto tiempo tarda en recuperarse un sistema después de una falla.

 
$$ 
\text{Disponibilidad} = \frac{\text{MTBF}}{\text{MTBF} + \text{MTTR}}
$$ 

- **Unidad:** también tiempo (minutos, horas, etc.), pero nuevamente, ambas deben estar en la **misma unidad**.  
- El resultado es un **número decimal** entre 0 y 1 (o lo puedes multiplicar por 100 para convertirlo en porcentaje).

**Ejemplo:**  
MTBF = 1000 horas, MTTR = 1 hora:

$$ 
\frac{1000}{1000 + 1} = 0.999 \Rightarrow 99.9\%
$$ 


### Fórmula 2:  

Cuando usarlo : Para evaluar tu desempeño actual real si ya conoces la duración exacta de interrupciones en un periodo (mes, año, semana) usa la fórmula basada en tiempo de inactividad


$$ 
\text{Disponibilidad (\%)} = \left( \frac{\text{Tiempo total} - \text{Tiempo inactivo}}{\text{Tiempo total}} \right) \times 100
$$ 

- **Unidad:** _tiempo_ (puede ser minutos, horas, días, etc.)  
- Lo importante es usar **la misma unidad** tanto en el numerador como en el denominador.  
- El resultado final es un **porcentaje (%)**.

**Ejemplo:**  
Si el mes tiene 43,200 minutos y hubo 30 minutos de caída:

$$ 
\left( \frac{43200 - 30}{43200} \right) \times 100 = 99.93\%
$$ 



 
---

 

### **Consideraciones para Réplicas:**

    * **Objetivo de Nivel de Servicio (SLO):** Define qué nivel de disponibilidad esperas para tu servicio de PostgreSQL. Por ejemplo, "99.9% de disponibilidad para la escritura y 99.99% para la lectura."
    * **Failover y Switchover:** Cuando ocurre un failover (cambio automático de primaria) o un switchover (cambio manual), habrá un período breve de indisponibilidad para la primaria original y/o para el clúster mientras se reconfigura. Tu sistema de monitoreo debe poder registrar estos eventos y el tiempo de inactividad asociado.
    * **Retraso de Replicación (Replication Lag):** Aunque un servidor esté "arriba", si su replicación está muy atrasada, podría considerarse "no disponible" para ciertas operaciones que requieren datos actualizados. Puedes monitorear `pg_stat_replication` (por ejemplo, `write_lag`, `flush_lag`, `replay_lag`) para esto y definir umbrales.

 
 
---



# 🔵 ¿Qué es la *resiliencia* en sistemas HA/DR?

La **resiliencia** es la **capacidad que tiene un sistema para resistir fallos, continuar funcionando y recuperarse rápidamente** después de un incidente, ya sea una caída parcial, total o un desastre.

En otras palabras:

 **Un sistema resiliente no solo evita caerse, sino que puede seguir operando aun cuando algo falle, y volver a su estado normal sin pérdida de datos o con impacto mínimo.**



# 🔵 ¿Para qué sirve la resiliencia en HA/DR?

La resiliencia permite que:

### ✔️ 1. **El servicio siga funcionando durante fallos**

Un sistema resiliente mantiene la operación aun cuando un nodo, disco, red o datacenter falla.

### ✔️ 2. **Los tiempos de recuperación (RTO/RPO) sean mínimos**

*   **RTO (Recovery Time Objective)**: qué tan rápido debes levantar un servicio.
*   **RPO (Recovery Point Objective)**: cuánta pérdida de datos puedes tolerar.

Un sistema resiliente busca **RTO y RPO casi cero**.

### ✔️ 3. **Evitar caídas completas**

La resiliencia combina redundancia, replicación, failover y monitoreo para prevenir interrupciones.

### ✔️ 4. **Reponerse automáticamente**

La resiliencia implica **autorreparación**, **autofailover**, y recuperación sin intervención manual.

***

# 🔵 Características de un sistema resiliente en HA/DR

Un sistema se considera resiliente si incorpora:

### **1. Redundancia**

*   Múltiples nodos
*   Sistemas replicados
*   Discos espejeados
*   Rutas de red duplicadas

### **2. Replicación**

*   Sincronizada (casi cero pérdida de datos)
*   Asincronizada (seguridad geográfica)

### **3. Tolerancia a fallos**

El sistema debe seguir funcionando cuando uno o varios componentes dejan de funcionar.

### **4. Mecanismos de Failover**

Automáticos o manuales.

### **5. Recuperación rápida (Self-healing)**

Reincorporar nodos dañados sin downtime significativo.

### **6. Distribución geográfica**

Protección ante:

*   Desastres naturales
*   Cortes eléctricos masivos
*   Fallos del datacenter completo


---

se veran temas : 

- DRP 
- Respaldos.
- Replicas Striming.
- Replicas logicas
- alta Disponibilidad 
- Distribución de carga 
 ETc 
```
https://richyen.com/postgres/2026/06/15/disaster_recovery_is_a_process.html


-- Proyecto para habilitar un HADR para la nube
https://github.com/vitabaks/autobase
https://autobase.tech/docs


Obtener información de disponibilidad -> https://uptime.is/
High Available PostgreSQL Cluster Arhitecture [PostgreSQL + Patroni |  HAProxy + Keepalived |  pgBackRest ] - https://ozwizard.medium.com/high-available-postgresql-cluster-arhitecture-c405c00c8c71 <br>
https://github.com/kashifmeo/postgreSQL/blob/main/postgreSQLPatroniCluster <br>
https://www.youtube.com/watch?v=qpxKlH7DBjU&list=PLBrWqg4Ny6vVwwrxjgEtJgdreMVbWkBz0 <br>
https://www.youtube.com/results?search_query=high+availability+postgresql <br>
https://www.youtube.com/watch?v=A_t_ytq1lpA <br>
https://www.youtube.com/watch?v=f69j5beCtU8&list=PL0oKv1pqr890hczYB903pyPIFUCIhNj40 <br>
https://www.youtube.com/watch?v=-OjhYXNJPYM&list=PLn6POgpklwWonHjoGXXSIXJWYzPSy2FeJ&index=27
PostgreSQL Disaster Recovery: Easy Steps for Effective Backup and Restoration -> https://www.mydbops.com/blog/master-postgresql-disaster-recovery-backup-restore
```

