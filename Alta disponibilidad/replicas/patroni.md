## 🧠 3. ¿Qué es Patroni?

**Patroni** es una herramienta de **orquestación de alta disponibilidad** para PostgreSQL. Utiliza un sistema de consenso distribuido (como **Etcd**, **Consul** o **ZooKeeper**) para coordinar qué nodo debe ser el **líder (primary)** y cuáles deben ser los **replicas (standby)**.


## ✅ 4. Ventajas de usar Patroni

| Ventaja                            | Descripción                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| 🔄 **Failover automático**         | Detecta caídas del nodo primario y promueve un standby sin intervención humana. |
| 🧩 **Integración con etcd/consul** | Usa sistemas de consenso para evitar split-brain y asegurar consistencia.       |
| 🛠️ **Configuración flexible**     | Compatible con múltiples entornos: bare metal, contenedores, Kubernetes.        |
| 📡 **API REST**                    | Expone endpoints para monitoreo y control externo.                              |
| 🔐 **Seguridad y control**         | Puede integrarse con sistemas de autenticación y cifrado.                       |


 
***
 

## 📅 7. Cuándo usar Patroni

*   Cuando necesitas **alta disponibilidad automática** sin intervención humana.
*   Cuando tu entorno requiere **replicación síncrona o asíncrona**.
*   Cuando trabajas en **Kubernetes** y necesitas una solución HA nativa.
*   Cuando tienes múltiples nodos PostgreSQL y quieres evitar el split-brain.


--- 





--- 

```conf

https://medium.com/@jramcloud1/set-up-high-availability-postgresql-cluster-using-patroni-1367c72fbedb
Patroni -> https://medium.com/@joaovic32/demystifying-high-availability-postgresql-with-patroni-and-pgpool-ii-on-ubuntu-428c91a55b1a
https://ozwizard.medium.com/postgresql-with-patroni-installation-and-configuration-49d6b8105580

*   <https://github.com/zalando/patroni>
*   <https://etcd.io/docs/>
*   <https://www.postgresql.org/docs/current/warm-standby.html>

```
