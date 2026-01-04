

### 1. El Objetivo 

El objetivo es **desmitificar el funcionamiento de PostgreSQL**. El autor quiere que entiendas que `VACUUM` no es una herramienta para "limpiar archivos y recuperar espacio en el disco duro", sino un mecanismo interno para **gestionar la reutilización de espacio** dentro de la base de datos. El título "es una mentira" se refiere a que el nombre sugiere una limpieza total (como una aspiradora), pero la realidad es más compleja.

### 2. El Problema: El "Bloat" (Hinchazón)

PostgreSQL utiliza un sistema llamado **MVCC** (Control de Concurrencia Multiversión). Esto significa que:

* Cuando **actualizas** una fila, Postgres no cambia los datos existentes; crea una copia nueva y marca la vieja como "muerta" (dead tuple).
* Cuando **eliminas** una fila, esta no se borra del disco; simplemente se marca como "muerta".
* **Consecuencia:** El archivo de la base de datos sigue creciendo y ocupando espacio en tu disco, aunque hayas borrado millones de registros. A este espacio desperdiciado (filas muertas que ocupan sitio) se le llama **Bloat**.

**El malentendido:** Muchos creen que ejecutar `VACUUM` devolverá ese espacio libre al sistema operativo (por ejemplo, que tu disco pase de 100GB usados a 80GB). **Esto casi nunca sucede.**

### 3. La Solución (y cómo funciona realmente)

El post explica que la "solución" no es recuperar espacio en el disco, sino entender cómo `VACUUM` ayuda a Postgres a no seguir creciendo infinitamente:

* **Lo que hace VACUUM estándar:** Escanea las tablas buscando "filas muertas" y las marca como espacio disponible **solo para Postgres**. La próxima vez que insertes datos, Postgres usará esos huecos en lugar de pedirle más espacio al sistema operativo. El archivo en el disco sigue midiendo lo mismo, pero ahora tiene "huecos" que Postgres sabe llenar.
* **La solución al rendimiento:** Mantener un `autovacuum` agresivo. Si el proceso de limpieza corre frecuentemente, los huecos se reutilizan rápido y el archivo en disco deja de crecer descontroladamente.
* **Si realmente necesitas recuperar espacio en disco:** El autor menciona que la única forma oficial es `VACUUM FULL`, pero advierte que es peligroso porque **bloquea la tabla totalmente** (nadie puede leer ni escribir) y básicamente reescribe la tabla de cero. Una alternativa moderna que menciona es usar herramientas externas como `pg_repack`.

### Resumen ejecutivo:

* **El Problema:** Borrar datos no libera espacio en el disco; crea "bloat" (espacio muerto).
* **La Mentira:** Creer que `VACUUM` encogerá tus archivos en el disco.
* **La Solución:** `VACUUM` simplemente permite que Postgres **reutilice** el espacio interno para que el archivo no siga creciendo. Para que sea efectivo, debe configurarse para que sea constante y no una tarea manual de último minuto.

--- 
### Links 
```
https://boringsql.com/posts/vacuum-is-lie/
```
