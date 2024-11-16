



	
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

