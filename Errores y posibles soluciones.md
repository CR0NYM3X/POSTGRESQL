
# Error \#1 (not create shared memory)

```BASH
********** ERROR ***************
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >FATAL:  could not create shared memory segment: Invalid argument
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >DETAIL:  Failed system call was shmget(key=5432001, size=4412637184, 03600).
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >HINT:  This error usually means   that PostgreSQL's request for a shared memory segment exceeded your kernel's SHMMAX parameter.
You can either reduce the request size or reconfigure the kernel    with larger SHMMAX.  To reduce the request size (currently 4412637184 bytes),
 reduce PostgreSQL's shared_buffers parameter (currently 524288) and/or its max_connections parameter (currently 603). If the request size is already small, it's
possible that it is less than  your kernel's SHMMIN parameter, in which case raising the request size or recon   figuring SHMMIN is called for.
The PostgreSQL documentation contains more information about shared memo  ry configuration.

********** La memoria compartida sirve para :  **********
1.- Mejora el rendimiento:
2.- Soporte para múltiples conexiones:
3.- Optimización de consultas:
4.-  Mantenimiento de consistencia:
5.- Gestión de recursos 

********** Ver info de la memorio ram **********
free -m

********** para ver cuanto es lo que se esta usando de memoria compartida y el limite de conexiones  en postgres **********
cat /sysd/data/postgres.conf | grep shared_buffers
cat /sysd/data/postgres.conf | grep max_connections

SHOW shared_buffers;
SHOW max_connections;


********** para configurar el tamaño maximo y minimo en bytes  **********
sysctl -w kernel.shmmax=4412637184
sysctl -w kernel.shmall=4194304

********** Para ver el detalle  **********
sysctl kernel.shmmax
sysctl kernel.shmall

********** para ver la información  **********
/etc/sysctl.conf
/proc/sys/kernel/shmall
/proc/sys/kernel/shmmax
/proc/sys/kernel/shmmni


getconf PAGE_SIZE


********** SOLUCION RAPIDA **********
bajar la memoria compartida del /sysd/data/postgres.conf

```





# Error \#2  (LOG:  invalid primary checkpoint record, PANIC:  could not locate a valid checkpoint record)


```BASH
********** ERROR **********
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
<2024-01-02 11:53:19 MST     2291249 65945b9f.22f631 > LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > LOG:  database system was shut down at 2023-03-10 18:06:07 MST
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > LOG:  invalid primary checkpoint record
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > PANIC:  could not locate a valid checkpoint record
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  startup process (PID 2291251) was terminated by signal 6: Aborted
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  aborting startup due to startup process failure
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  database system is shut down


********** SOLUCION RAPIDA **********
# Esto lo que hace es que borra los wal 
pg_resetwal -f -D /sysx/data
pg_resetxlog -f -D  /sysx/data
```



