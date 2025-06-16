
**1. Inconsistencia en los tiempos de replicación**  
Aunque el streaming es rápido, no es instantáneo. Las réplicas pueden tener diferente lag, lo que genera inconsistencias si una aplicación necesita datos muy recientes.  
Problema: un usuario hace una escritura en el maestro y luego lee desde una réplica con retraso, obteniendo datos desactualizados.

**2. Escrituras en réplicas read-only**  
Las réplicas por streaming solo permiten lectura. Si el balanceador o el pool de conexiones no distingue correctamente entre lecturas y escrituras, puede generarse un error.  
Problema: una aplicación mal diseñada intenta insertar datos en una réplica y falla, provocando errores visibles al usuario.

**3. Detección de nodos inactivos**  
Un balanceador debe reconocer si una réplica falla o se atrasa excesivamente.  
Problema: el balanceador sigue enviando tráfico a un nodo fuera de línea, causando demoras y errores en las consultas.

**4. Routing limitado o sin inteligencia de queries**  
No todas las consultas de lectura toleran lag. Un balanceador simple no detecta cuáles necesitan consistencia estricta.  
Problema: dashboards, reportes u operaciones críticas muestran datos antiguos o inconsistentes.

**5. Failover mal sincronizado**  
Si usas herramientas como Patroni o repmgr para failover automático, el balanceador debe detectar el nuevo maestro rápidamente.  
Problema: se siguen enviando escrituras al nodo degradado, lo que puede corromper datos o provocar pérdida total del servicio.

**6. Carga desigual entre réplicas**  
Aunque todas las réplicas sean iguales en teoría, en la práctica pueden tener diferente hardware, carga o red.  
Problema: el balanceador reparte tráfico de forma uniforme sin considerar su capacidad real, lo que lleva a saturación innecesaria de algunos nodos.

**7. Configuración de autenticación no homogénea**  
Las credenciales, certificados o configuraciones pueden estar desincronizados entre réplicas.  
Problema: los usuarios se conectan correctamente a unas réplicas, pero fallan en otras, generando errores aleatorios y difíciles de diagnosticar.

 
### Cómo lo determina PostgreSQL

PostgreSQL clasifica las funciones según su **volatilidad y tipo de acceso**:

- `IMMUTABLE`: garantiza que no cambia el estado de la base de datos ni depende de datos volátiles.
- `STABLE`: puede consultar tablas, pero no debe modificar nada.
- `VOLATILE`: puede leer o **modificar datos**, ejecutar `INSERT`, `UPDATE`, `DELETE`, o llamar otras funciones que lo hagan.

Y aparte, el tipo de función también influye:

- Si es una **function o procedure** y está declarada como **`VOLATILE`** o explícitamente usa comandos de modificación, **PostgreSQL la tratará como potencialmente peligrosa para las réplicas**.

### Escenario con balanceador y réplicas

Supongamos que tienes Pgpool-II o HAProxy balanceando consultas entre un nodo maestro y tres réplicas:

- Tu aplicación ejecuta una función llamada `procesar_orden(id_usuario)` que internamente hace `INSERT` en una tabla de órdenes.
- El balanceador **no sabe que esa función realiza escritura** (porque no analiza profundamente el código).
- Si la envía a una réplica en lugar del maestro, esa función **fallará**, ya que las réplicas en modo streaming **no permiten escritura**.

> Resultado: error inesperado en producción.

### ¿Cómo evitarlo?

1. **Clasifica correctamente tus funciones**: marca las que escriben como `VOLATILE`, o mejor aún, no pongas lógica de escritura en funciones si la aplicación las ejecutará como consultas simples.

2. **Configura tu balanceador para desactivar parseo de funciones** (si no es confiable), y enruta todo lo ambiguo al maestro.

3. **Usa etiquetas explícitas en tus aplicaciones** (como comentarios o tags) para forzar rutas específicas si tu infraestructura lo permite.


Perfecto, estás enfrentando un caso clásico en topologías de alta disponibilidad con balanceadores de carga y réplicas en PostgreSQL. El corazón del problema está en **funciones que internamente hacen escrituras**, pero el balanceador las envía a un *read-only replica*, lo que naturalmente genera errores.

---

###  1. Revisión y etiquetado correcto de funciones
PostgreSQL permite marcar funciones como `VOLATILE`, `STABLE` o `IMMUTABLE`.

- Si tus funciones hacen escrituras, **deberían estar marcadas como `VOLATILE`**. Esto ayuda a algunas herramientas de pool y balanceadores (como PgBouncer en modo `transaction`) a evitar enviar llamadas a réplicas.
- Si no están marcadas correctamente, los proxies pueden tratarlas como funciones de solo lectura.

---

###  2. Revisión y configuración del balanceador
Dependiendo de qué balanceador uses (HAProxy, Pgpool-II, etc.), deberías:

- **Detectar queries de escritura dinámicamente**, y redirigirlas al maestro.
  - En Pgpool-II, por ejemplo, puedes usar `query_cache_enabled = off` y `allow_sql_comments = on`, y apoyarte en `black_function_list` para forzar que ciertas funciones vayan al maestro.
- **Desactivar balanceo en sesiones que ejecuten funciones mixtas o complejas**, y forzarlas al nodo maestro.

---

###  3. Políticas de conexión en el pooler
Con PgBouncer, considera:

- Modo `session` en lugar de `transaction`, para que toda la sesión vaya al mismo servidor.
- Usa parámetros como `statement routing` con cuidado, o incluso **usa múltiples poolers**: uno para lectura y otro para escritura, y selecciona en tu aplicación.

---

###  4. Separación a nivel de aplicación
Esto requiere más esfuerzo, pero es sólido:

- Divide rutas de acceso a la BD: **una conexión explícita para escritura (maestro)** y otra para lectura (réplicas).
- Algunas ORMs modernas permiten definir “roles” de conexión. Úsalo para enrutar adecuadamente las funciones.



Usando solo HAProxy, también puedes manejar este problema, aunque necesitarás una lógica más explícita ya que HAProxy no entiende el contenido del SQL. Aquí algunas estrategias eficaces:

---

###  1. **Separación por puertos o backends**

Configura **dos frontends distintos** en HAProxy:

- Uno para **lecturas (SELECT)** que balancea entre esclavos.
- Otro para **escrituras (INSERT, UPDATE, DELETE, funciones VOLATILE)** que va directo al maestro.

En tu aplicación, **usa puertos diferentes** dependiendo del tipo de consulta. Algunos ORM o frameworks permiten esta separación.

---

###  2. **Uso de SQL comments para enrutar tráfico**

Una táctica popular es que tu aplicación agregue un comentario especial al inicio del query. Ejemplo:

```sql
-- read
SELECT * FROM usuarios;

-- write
/*write*/ SELECT ejecutar_funcion_que_modifica();
```

En HAProxy puedes crear ACLs como:

```haproxy
acl is_write_query req.payload(0,128) -m sub "/*write*/"
use_backend backend_master if is_write_query
default_backend backend_slaves
```

Esto requiere que HAProxy esté en modo TCP y analice el payload inicial del protocolo PostgreSQL (usando un proxy externo como `pg-proxy` o `stunnel` si es necesario).

---

###  3. **Uso de pgbouncer o una capa extra intermedia**

Si HAProxy se queda corto, podrías poner **PgBouncer entre la app y HAProxy** con reglas por sesión. Así HAProxy solo enruta conexiones, y PgBouncer decide cómo manejarlas en función del tipo de operación.



 
