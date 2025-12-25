# pg_rewind
La herramienta **`pg_rewind`** en PostgreSQL se utiliza para **sincronizar un servidor que estuvo en modo primario con su réplica después de un failover o promoción**, sin necesidad de copiar toda la base de datos desde cero.

### ✅ ¿Para qué sirve?

Cuando ocurre un **failover** y una réplica se convierte en el nuevo primario, el antiguo primario queda desfasado. Si quieres reintegrarlo como réplica, normalmente tendrías que hacer un `pg_basebackup` completo, lo cual puede ser muy costoso en tiempo y espacio.  
**`pg_rewind`** evita esto: analiza las diferencias entre el timeline del nuevo primario y el antiguo, y **aplica solo los cambios necesarios** para que el antiguo primario pueda volver a ser réplica.

***

### 🔍 ¿Cómo funciona?

*   Compara los archivos del antiguo primario con los del nuevo primario.
*   Identifica los bloques modificados desde que se separaron.
*   Copia únicamente esos bloques y ajusta el timeline.
*   Requiere que el antiguo primario tenga habilitado **`wal_log_hints = on`** o que esté en modo **data checksums**.

***

### 📌 Casos de uso

*   **Alta disponibilidad (HA)**: Después de un failover, reintegrar el nodo antiguo sin reinstalar todo.
*   **Disaster Recovery**: Minimizar tiempo de recuperación tras una caída.
*   **Entornos grandes**: Evitar transferencias masivas de datos.

***

### ⚠️ Limitaciones

*   Solo funciona si el antiguo primario no tiene datos que el nuevo primario no conoce (es decir, no se escribieron transacciones que no estén en el nuevo timeline).
*   No reemplaza backups: es una herramienta de sincronización, no de recuperación total.
 

```bash

se usa Quieres activar funcionalidades que requieren archive_mode = on, como pg_rewind o pg_basebackup, pero no necesitas archivar WALs. Es una forma segura de "engañar" a PostgreSQL para que crea que está archivando, sin hacerlo realmente.
 Cuando usas streaming replication con replication slots, los WALs ya se retienen automáticamente mientras el standby los consume. No necesitas archive_command, pero pg_rewind sí requiere archive_mode = on. Para cumplir con esa dependencia sin copiar los WALs, se usa /bin/true.

archive_mode = on
archive_command = '/bin/true'

```
 
