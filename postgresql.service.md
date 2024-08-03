
> [!IMPORTANT]
> Una vez que integras postgresql con systemctl no se debe de usar el pg_ctl u otra herramienta para restart,start,stop y reload ya que desincroniza el estatus del systemctl 

# Comandos 
 ```sql
vim /lib/systemd/system/postgresql.service

 sudo -l 
 
sudo /usr/bin/systemctl start postgresql-11.service  
sudo /usr/bin/systemctl stop postgresql-11.service 
sudo /usr/bin/systemctl restart postgresql-11.service
sudo /usr/bin/systemctl reload postgresql-11.service

sudo /usr/bin/systemctl enable postgresql-11.service
sudo /usr/bin/systemctl disable postgresql-11.service

sudo /usr/bin/systemctl status postgresql-11.service
 sudo /usr/bin/systemctl edit postgresql-11.service  --full
 
 ls -lhtra /lib/systemd/system/ | grep postg

 systemctl list-unit-files | grep post
 
 
  ```

# Ejemplo de configuración de postgresql.service
 ```sql
Description=PostgreSQL database server
After=network.target

[Service]
Type=idle
User=postgres
Group=postgres

PIDFile=/sysx/data16/postmaster.pid
ExecStart=/usr/local/pgsql/bin/pg_ctl start -o -i -D /sysx/data -w -t 120
RemainAfterExit=true

#---valida si los archivos de postgresql estan corruptos 
#/usr/pgsql-11/bin/postgresql-11-check-db-dir /sysx/data11

ExecReload=/usr/local/pgsql/bin/pg_ctl reload -s -D /sysx/data
RemainAfterExit=true

ExecStop=/usr/local/pgsql/bin/pg_ctl stop -m fast -s -D /sysx/data
RemainAfterExit=true

Restart=on-abnormal

# Due to PostgreSQL's use of shared memory, OOM killer is often overzealous in
# killing Postgres, so adjust it downward
OOMScoreAdjust=-200

[Install]
WantedBy=multi-user.target
 ```










# Ejemplo #2 de configuración de postgresql.service
 ```sql

[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking

User=postgres
Group=postgres

# Where to send early-startup messages from the server (before the logging
# options of postgresql.conf take effect)
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000
# ... but allow it still to be effective for child processes
# (note that these settings are ignored by Postgres releases before 9.5)
Environment=PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
Environment=PG_OOM_ADJUST_VALUE=0

# Maximum number of seconds pg_ctl will wait for postgres to start.  Note that
# PGSTARTTIMEOUT should be less than TimeoutSec value.
Environment=PGSTARTTIMEOUT=270

Environment=PGDATA=/usr/local/pgsql/data


ExecStart=/usr/local/pgsql/bin/pg_ctl start -D ${PGDATA} -s -w -t ${PGSTARTTIMEOUT}
ExecStop=/usr/local/pgsql/bin/pg_ctl stop -D ${PGDATA} -s -m fast
ExecReload=/usr/local/pgsql/bin/pg_ctl reload -D ${PGDATA} -s

# Give a reasonable amount of time for the server to start up/shut down.
# Ideally, the timeout for starting PostgreSQL server should be handled more
# nicely by pg_ctl in ExecStart, so keep its timeout smaller than this value.
TimeoutSec=300

[Install]
WantedBy=multi-user.target

 ```

1. **Bibliografías**:
    ```sql
    https://www.postgresql.org/docs/current/server-start.html
    https://unix.stackexchange.com/questions/220362/systemd-postgresql-start-script
    ```
