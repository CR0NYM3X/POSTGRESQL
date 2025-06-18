**Pgpool-II** es una herramienta intermedia (middleware) que se coloca entre tus aplicaciones cliente y uno o varios servidores **PostgreSQL**. Su propósito es mejorar el rendimiento, la disponibilidad y la escalabilidad de tu base de datos sin necesidad de modificar tu aplicación ni PostgreSQL. 

 
###   ¿Qué puede hacer Pgpool-II?

#### **1. Pooling de Conexiones**
- Reutiliza conexiones existentes a PostgreSQL para evitar el costo de abrir/cerrar conexiones constantemente.
- Mejora el rendimiento en aplicaciones con muchas conexiones concurrentes.

#### **2. Balanceo de Carga**
- Distribuye automáticamente las consultas **SELECT** entre múltiples réplicas de PostgreSQL.
- Reduce la carga del servidor maestro y mejora la escalabilidad de lectura.

#### **3. Alta Disponibilidad (HA)**
- Detecta fallos en los nodos y puede redirigir las conexiones a nodos disponibles.
- Con el módulo **Watchdog**, puede gestionar una IP virtual (VIP) y evitar puntos únicos de falla.

#### **4. Failover Automático**
- Si el nodo maestro falla, Pgpool-II puede promover una réplica a maestro automáticamente.
- También puede ejecutar scripts personalizados para manejar la conmutación por error.

#### **5. Recuperación en Línea**
- Permite reintegrar nodos fallidos al clúster sin detener el servicio.
- Usa scripts como `recovery_1st_stage` y `recovery_2nd_stage`.

#### **6. Caché de Consultas en Memoria**
- Puede almacenar resultados de consultas SELECT en memoria.
- Si se repite la misma consulta, responde desde la caché sin consultar a PostgreSQL.

#### **7. Administración vía PCP y SQL**
- Usa comandos como `pcp_attach_node`, `pcp_node_info`, etc., para administrar nodos.
- Con la extensión `pgpool_adm`, puedes ejecutar estas acciones desde SQL.

#### **8. Control de Conexiones Excedidas**
- Si se alcanza el límite de conexiones, puede ponerlas en cola en lugar de rechazarlas inmediatamente.

#### **9. Soporte para Replicación y Paralelismo**
- Puede trabajar en modos de replicación nativa, streaming replication o consultas paralelas.

 
###   ¿Qué no hace Pgpool-II?
- No reemplaza a PostgreSQL.
- No realiza balanceo de carga de escritura (solo lectura).
- No es un sistema de respaldo ni de monitoreo por sí solo (aunque puede integrarse con ellos).


### NOTAS 

- Cuando Pgpool-II está balanceando consultas, las **sentencias SELECT** se envían a réplicas (nodos esclavos), mientras que las de modificación (DML) van al nodo maestro.  Pgpool-II detecta que no es un SELECT**, y por defecto **lo enruta al nodo maestro** (el único que acepta escrituras).

- Pgpool-II no requiere PostgreSQL instalado en el mismo servidor donde se ejecuta
 
- Puedes instalar Pgpool-II en el mismo servidor donde corre PostgreSQL, y de hecho, es bastante común en entornos de desarrollo o laboratorios de prueba. pero no se recomienda en servidores productivos ya que compiten por CPU, RAM y disco. En producción, esto puede degradar el rendimiento.

- Si Pgpool-II **solo se usará como balanceador de carga**, **no necesitas configuraciones de failover, HA ni recuperación de nodos**.  
✅ **Enfócate en balanceo de carga** → `load_balance_mode = on`  
❌ **Desactiva failover y watchdog**  
❌ **Ignora comandos PCP de recuperación**  

- **No necesitas instalar extensiones en postgresql si solo usas:**. **Balanceo de carga** ,  **Pooling de conexiones** , **Routing de consultas de lectura/escritura**
-   **sí necesitas extensiones si usas:** <br>
     **1. Recuperación en línea (Online Recovery)** Para que Pgpool-II pueda ejecutar scripts de recuperación automática y reintegrar nodos fallidos, necesitas instalar la extensión pgpool_recovery.Esta extensión permite que los scripts como `recovery_1st_stage` y `recovery_2nd_stage` funcionen correctamente desde Pgpool-II.  <br>
      **2. Administración PgPool vía SQL** Si quieres ejecutar comandos PCP desde SQL  puedes instalar pgpool_adm, te permite administrar Pgpool-II desde una sesión SQL, sin tener que usar comandos externos como pcp_node_info o pcp_attach_node.

### ** `watchdog` en Pgpool-II**
El **watchdog** es un **subproceso de Pgpool-II** que agrega **Alta Disponibilidad (HA)**. Su función principal es **monitorear el estado de Pgpool-II** y **manejar el failover automático** en caso de fallos.

**¿Qué hace el watchdog?**
- **Monitorea la salud de Pgpool-II**, enviando consultas a PostgreSQL.
- **Detecta fallos** en el servicio y **promueve otro nodo** como activo.
- **Gestiona direcciones IP virtuales (VIP)** para que el servicio siga disponible.
- **Evita el problema de "split-brain"**, asegurando que solo un Pgpool-II sea el activo.




### Rutas de pgpool 
```
--- Directorio de cofiguracion 
ls -lhtr /etc/pgpool-II/ # Directorio generico de pgpool
ls -lhtr /etc/pgpool-II-13 # Se recomienda usar el directorio enfocado a la versión de postgresql, ya que cuenta con script personalizados  para la versión

--- binarios de la herramienta
ls -lhtr /usr/pgpool-13/bin

-- Archivos que se configuran 
vim /etc/pgpool-II-13/pgpool.conf.sample
vim /etc/pgpool-II-13/pgpool.conf.sample-stream
```

## ** laboratorio**


## Bibliografía
```
PostgreSQL High Availability complete setup using pgpool as LoadBalancer between nodes -> https://tarunratan.medium.com/1-simplifying-postgresql-high-availability-with-pgpool-83f492841681
Introduction to Database Clustering using PostgreSQL , Docker and Pgpool-II -> https://medium.com/@tirthraj2004/introduction-to-database-clustering-using-postgresql-docker-and-pgpool-ii-ac2a7bf96a5f
Configuration the PostgreSQL database for metadata using PGPool on lab environment -> https://awslife.medium.com/configuration-the-postgresql-database-for-metadata-using-pgpool-on-lab-environment-f30367562916
PostgreSQL pgpool -> https://kimdubi.github.io/postgresql/postgresql_pgpool/
Pgpool Installation + Connection Test With Python -> https://medium.com/@c.ucanefe/pgpool-installation-connection-test-with-python-c2ef7501a174
Step By Step: Use pgpool to achieve load balance & separation of read/write on Mac -> https://zzdjk6.medium.com/step-by-step-use-pgpool-to-achieve-load-balance-separation-of-read-write-on-mac-e1b8b21af159
PgPool: How to setup PostgreSQL Load Balancer on Kubernetes Cluster -> https://8grams.medium.com/pgpool-how-to-setup-postgresql-load-balancer-on-kubernetes-cluster-b5f4eb06cde3
PGPOOL PostgreSQL — SSL Configuration to Connect Database -> https://demirhuseyinn-94.medium.com/postgresql-ssl-configuration-to-connect-database-114f867d96e0
High Availability in Postgres ->  https://medium.com/@usman.khan9805/high-availibility-in-postgres-3210fb232f82
“Relation does not exist”- Understanding Pgpool-II Connection pooling -> https://medium.com/@ashish15/relation-does-not-exist-understanding-pgpool-ii-connection-pooling-25d60aab77fe


https://www.pgpool.net/docs/latest/en/html/tutorial.html
https://www.pgpool.net/mediawiki/index.php/Documentation
https://www.pgpool.net/docs/latest/en/html/runtime-config-backend-settings.html

```
