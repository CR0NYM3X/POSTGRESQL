



	
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
