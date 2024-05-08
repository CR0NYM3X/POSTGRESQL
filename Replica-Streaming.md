

### PG_WALL
 
**"pg_wal"** se refiere a la carpeta o directorio donde se almacena el registro de transacciones, también conocido como "Write-Ahead Log" o WAL por sus siglas en inglés. El registro de transacciones es una característica fundamental en los sistemas de gestión de bases de datos para garantizar la durabilidad y la integridad de los datos, incluso en casos de fallos o caídas del sistema. <br>

En PostgreSQL, el "pg_wal" funciona de manera similar. En lugar de escribir directamente los cambios en la base de datos cada vez que se realiza una operación (como una inserción, actualización o eliminación), PostgreSQL primero anota los cambios en el registro de transacciones (WAL). Esto garantiza que, si ocurre un fallo repentino del sistema (como un corte de energía), la base de datos pueda recuperarse utilizando la información almacenada en el registro de transacciones.





### Promover un servidor a primario 
 un servidor secundario puede ser promovido a primario para evitar interrupciones en el servicio. ya que una vez que se promueve un servidor secundario a primario, 
 el antiguo servidor primario (que ahora es secundario) perderá su estatus de primario y no podrá recibir escrituras hasta que se restablezca la replicación y se configure nuevamente como primario.
```
/usr/local/pgsql/bin/pg_ctl promote -D /sysx/data/
```

### Pasos 

```
------------ WAL SENDER ------------
.- Hacer copia de pg_hba.conf y  postgresql.conf 
.-  Promover servidor 
.- Cambiar hot_standby a off en postgresql.conf
.- Reload

------------ WAL Receiver ------------

.- nohup /usr/pgsql-13/bin/./pg_basebackup -U postgres -h 10.49.123.197 -R -P -X stream -c fast -D /sysx/data/ &
.- pg_ctl stop -D /sysx/data/ -mf
.- cd /sysx/data/ && rm -rf *
.- cd /pg_wal && rm -rf *
.- cd /pg_log && rm -rf *
chmod 700 /sysx/data/
pg_ctl start -D /sysx/data/ -o -i
tail -f  nohup.out


```

### Validar walls  
herramienta para ver que es lo que contiene los wall 
```
pg_waldump  --- 
pg_waldump /var/lib/pgsql/data/pg_wal/0000000100000002000000C9
```

