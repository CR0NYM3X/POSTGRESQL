### Replicación Física (Physical Replication)
Esta replicación se basa en la copia de los archivos de datos binarios (WAL - Write-Ahead Logging)  se envían en tiempo real desde el servidor principal a los servidores de réplica mediante una conexión persistente

- **Objetivo**: Mantener una copia exacta de la base de datos principal (primaria) en una o más bases de datos secundarias (réplicas).
- **Funcionamiento**: Utiliza los archivos de registro de escritura adelantada (WAL) para enviar cambios en tiempo real desde la base de datos primaria a las réplicas.

### Herramientas y técnicas adicionales
```
1. **pgpool-II**:
   - Una herramienta que proporciona balanceo de carga, replicación y conmutación por error para PostgreSQL.

2. **Slony-I**:
   - Un sistema de replicación maestro-esclavo para PostgreSQL que permite replicar datos entre múltiples servidores.

3. **Bucardo**:
   - Una herramienta de replicación multi-maestro que permite la replicación bidireccional entre múltiples servidores PostgreSQL
   
4.- **pg_stat_replication**
   - Vista interna de PostgreSQL que muestra el estado de las conexiones de replicación.
```

# Conceptos que se usan en las replicas 
```sql

```



# Preguntas frecuentes 

``` 
¿Se puede usar Streaming Replication Sin Slot?
  R: En muchas situaciones, puedes operar una replicación por streaming sin usar replication slots, especialmente si tienes una red estable y las réplicas están configuradas para mantenerse relativamente cerca del primario en términos de sincronización.


```



**BIBLIOGRAFIAS**
```sql
 https://www.postgresql.fastware.com/blog/two-phase-commits-for-logical-replication-publications-subscriptions

[ pg_ctl restart -D /sysx/data11/DATANEW/17](https://docs.google.com/document/d/1dhRb2ZCVfBXCU9HAfG-1NfK4IXQUJFeL/edit

******* Rango de 1-10 dependiendo de lo bueno que es la documentacion
https://es.linux-console.net/?p=322#gsc.tab=0 ---- 10 
https://hevodata.com/learn/postgresql-streaming-replication/ --- 10
https://gist.github.com/encoreshao/cf919b300497ca863d54383455578906 ----- 10
https://gist.github.com/kpirliyev/c840e32df1619ab5875911286521c75b --- 9
https://gist.github.com/hiren-serpentcs/e23137b06b67a50c5774be76b9247390 ---- 8
https://gist.github.com/farhad0085/391258c40ff86da093945db63a48badf ----- 7
https://gist.github.com/cristianrasch/4f08b914088b5bc99c2d6466749acaa9 ---- 7
https://gist.github.com/tcpipuk/f68fb199ea8b1c1bdf48833fde86b418 --- docker replication califi 6
https://gist.github.com/vvitad/4157ab5928b751b89fc6cd63aed3c4a7 ----- calificacion 5
https://gist.github.com/anilpratti/434bcefaa9f10ca1d99b8bcd20bcb145 --- 3 
https://gist.github.com/dolezel/050f26769ec4c03f0ad075c7be2b3bc9 --- script 
https://momjian.us/main/writings/pgsql/hot_streaming_rep.pdf
https://www.postgresql.eu/events/pgconfeu2023/sessions/session/4773/slides/427/A%20journey%20into%20postgresql%20logical%20replication.pdf
https://p2d2.cz/files/PostgreSQL_LogicalReplication_LessonsLearned_v08.pdf
https://kinsta.com/blog/postgresql-replication/

https://emiliopm.com/2014/03/replicacion-en-postgresql/
https://e-mc2.net/blog/hot-standby-y-streaming-replication/#:~:text=Ficheros%20WAL%3A%20PostgreSQL%20utiliza%20los,en%20la%20base%20de%20datos.

What is WAL - https://www.postgresql.org/docs/13.0/wal-intro.html
Streaming Replication - https://www.postgresql.org/docs/13/warm-standby.html#STREAMING-REPLICATION
Replication Slots - https://hevodata.com/learn/postgresql-replication-slots/
)
```

