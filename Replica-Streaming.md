


### Habilita el recolector de logs.
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

