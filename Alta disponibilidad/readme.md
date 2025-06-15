
### Ruta de aprendizaje 
*** Replicas *** 
- Citus - Pendiente 
- PgLogical - Pendiente
- BDR
- PostgreSQL-XL
- Patroni + etcd

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

## 🕒 ¿Qué es RPO y RTO?

### 🔁 **RPO (Recovery Point Objective)**

- **¿Qué mide?**  
Es la **cantidad máxima de datos que puedes permitirte perder** si ocurre un fallo.  
 *¿Cuánta información puedo perder sin que sea un desastre?*

### ⏱️ **RTO (Recovery Time Objective)**

- **¿Qué mide?**  
Es el **tiempo máximo que una empresa puede estar sin operar** tras un fallo antes de que haya consecuencias graves. En otras palabras:  
 *¿Cuánto tiempo puedo estar fuera de servicio sin que me cueste demasiado caro?*

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

 

se veran temas : 

- DRP 
- Respaldos.
- Replicas Striming.
- Replicas logicas
- alta Disponibilidad 
- Distribución de carga 
 ETc 

https://github.com/kashifmeo/postgreSQL/blob/main/postgreSQLPatroniCluster <br>
https://www.youtube.com/watch?v=qpxKlH7DBjU&list=PLBrWqg4Ny6vVwwrxjgEtJgdreMVbWkBz0 <br>
https://www.youtube.com/results?search_query=high+availability+postgresql <br>
https://www.youtube.com/watch?v=A_t_ytq1lpA <br>
https://www.youtube.com/watch?v=f69j5beCtU8&list=PL0oKv1pqr890hczYB903pyPIFUCIhNj40 <br>
https://www.youtube.com/watch?v=-OjhYXNJPYM&list=PLn6POgpklwWonHjoGXXSIXJWYzPSy2FeJ&index=27



