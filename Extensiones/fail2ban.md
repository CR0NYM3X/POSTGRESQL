



	
	Configura un filtro para PostgreSQL en Archivo
	/etc/fail2ban/filter.d/postgresql.conf:
	
	
	
	[postgres@SERVER_TEST fail2ban]$ ls -lhtr
	total 84K
	-rw-rw-r--. 1 root root  25K Apr 14  2021 jail.conf
	-rw-r--r--. 1 root root  930 Apr  1  2023 paths-fedora.conf
	-rw-r--r--. 1 root root 2.7K Apr  1  2023 paths-common.conf
	-rw-r--r--. 1 root root  26K Apr  1  2023 jail.conf.rpmnew
	-rw-r--r--. 1 root root 3.0K Apr  1  2023 fail2ban.conf
	drwxr-xr-x. 2 root root    6 Apr  1  2023 fail2ban.d
	drwxr-xr-x. 3 root root 4.0K Apr 18  2023 filter.d
	drwxr-xr-x. 2 root root   49 Apr 18  2023 jail.d
	drwxr-xr-x. 2 root root 4.0K Apr 18  2023 action.d
	
	 
	[Definition]
	failregex = FATAL: password authentication failed for user .*
	
	[postgresql]
	enabled = true
	port = 5432
	filter = postgresql
	logpath = /var/log/postgresql/postgresql*.log
	maxretry = 5
	
	Reinicia el servicio:
	
	sudo systemctl restart fail2ban




FATAL:  password authentication failed for user "postgres"
DETAIL:  Connection matched file "/sysx/data16/pg_hba.conf" line 119: "host    all             all             127.0.0.1/32            scram-sha-256"

 /usr/bin/python3.6 -s /usr/bin/fail2ban-server -xf start
 
 ----  vim /lib/systemd/system/fail2ban.service  ----

 [Unit]
Description=Fail2Ban Service
Documentation=man:fail2ban(1)
After=network.target iptables.service firewalld.service ip6tables.service ipset.service nftables.service
PartOf=firewalld.service

[Service]
Type=simple
Environment="PYTHONNOUSERSITE=1"
ExecStartPre=/bin/mkdir -p /run/fail2ban
ExecStart=/usr/bin/fail2ban-server -xf start
# if should be logged in systemd journal, use following line or set logtarget to sysout in fail2ban.local
# ExecStart=/usr/bin/fail2ban-server -xf --logtarget=sysout start
ExecStop=/usr/bin/fail2ban-client stop
ExecReload=/usr/bin/fail2ban-client reload
PIDFile=/run/fail2ban/fail2ban.pid
Restart=on-failure
RestartPreventExitStatus=0 255

[Install]
WantedBy=multi-user.target
~

--------------- 


 ```sql

/var/log/fail2ban.log
/etc/fail2ban/jail.d/postgresql.conf ---  port = 5432


--> sudo nano /etc/fail2ban/action.d/postgres-action.conf
[Definition]
actionban = /usr/local/bin/postgres_set_role_nologin
actionunban = /usr/local/bin/postgres_set_role_login

 ```

 
 
 Bibliografías:
 ```sql
https://gist.github.com/rc9000/fd1be13b5c8820f63d982d0bf8154db1
 https://github.com/rc9000/postgres-fail2ban-lockout  
 https://blog.unixpad.com/2023/05/26/bloquear-accesos-no-autorizados-en-postgres-usando-fail2ban/
 https://warlord0blog.wordpress.com/2022/09/14/fail2ban-postgresql/
 https://jpcarmona.github.io/web/blog/fail2ban/
 
 https://docs.iredmail.org/fail2ban.sql.html
 https://www.saas-secure.com/online-services/read-fail2ban-ip-from-database-and-lock.html
 https://confluence.atlassian.com/conf89/using-fail2ban-to-limit-login-attempts-1387596371.html
 https://serverfault.com/questions/627169/how-to-secure-an-open-postgresql-port
 
 
 https://serverfault.com/questions/1032015/fail2ban-postgresql-filter-not-working
 https://github.com/fail2ban/fail2ban/discussions/3660
 https://www.reddit.com/r/sysadmin/comments/16dklqn/fail2ban_regex_filter_for_postgresql/?rdt=61321
 
 
 
 https://talk.plesk.com/threads/howto-secure-a-standard-postgres-port-with-fail2ban.355984/
 
 ```


 
