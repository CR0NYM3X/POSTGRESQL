# Beneficios kerberos GSSAPI 

Si estás utilizando Active Directory en tu entorno y quieres proporcionar autenticación de usuarios de forma segura y eficiente en PostgreSQL, te recomendaría utilizar la autenticación Kerberos (GSSAPI) en lugar de LDAP. Aquí hay algunas razones para considerar la autenticación Kerberos:
<br><br>
Seguridad mejorada: Kerberos ofrece un nivel más alto de seguridad en comparación con LDAP, ya que las credenciales de los usuarios no se transmiten en texto plano durante el proceso de autenticación. Esto reduce el riesgo de ataques de escucha de red y compromiso de credenciales.
<br><br>
Integración con Active Directory: La autenticación Kerberos se integra estrechamente con Active Directory, lo que significa que puedes aprovechar las cuentas de usuario existentes y la infraestructura de seguridad de tu entorno de Active Directory sin necesidad de duplicar la administración de usuarios.
<br><br>
Simplicidad de configuración: Configurar la autenticación Kerberos en PostgreSQL es relativamente sencillo una vez que tienes configurado Kerberos en tu entorno. Una vez configurado, los usuarios pueden autenticarse en PostgreSQL utilizando sus credenciales de Active Directory sin necesidad de proporcionar una contraseña adicional.
<br><br>
Eficiencia: Kerberos utiliza tokens de autenticación (tickets) para la autenticación, lo que puede proporcionar un proceso de autenticación más eficiente en comparación con LDAP, especialmente en entornos con una gran cantidad de usuarios y autenticaciones frecuentes.

 

# 1. Instalar los paquetes necesarios
sudo apt-get install krb5-user libpam-krb5 postgresql-contrib

## Escenario de ejemplo:
- Dominio AD: EMPRESA.LOCAL
- Servidor PostgreSQL: pgsql.empresa.local (IP: 192.168.1.100)
- Servidor AD: ad.empresa.local (IP: 192.168.1.10)
- Usuario de servicio: svc_postgres@EMPRESA.LOCAL
- Sistema Operativo del servidor PostgreSQL: Ubuntu 22.04 LTS
- PostgreSQL versión: 15

1. Preparación del sistema:

```bash
# Instalación de paquetes necesarios

```

Para Debian/Ubuntu:
```
sudo apt update
sudo apt install -y  krb5-user libpam-krb5 libpq-dev
```

Para Red Hat/CentOS/Fedora:
```
sudo dnf install krb5-workstation   postgresql-contrib cyrus-sasl-gssapi
```

2. Configuración de Kerberos (/etc/krb5.conf):

```ini
[libdefaults]
    default_realm = EMPRESA.LOCAL
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    EMPRESA.LOCAL = {
        kdc = ad.empresa.local
        admin_server = ad.empresa.local
    }

[domain_realm]
    .empresa.local = EMPRESA.LOCAL
    empresa.local = EMPRESA.LOCAL
```

3. Crear el Service Principal Name (SPN) en Active Directory:
```powershell
# Ejecutar en el servidor AD como administrador
setspn -A postgres/pgsql.empresa.local@EMPRESA.LOCAL svc_postgres
```

4. Generar el keytab:
```powershell
# En el servidor AD
ktpass -princ postgres/pgsql.empresa.local@EMPRESA.LOCAL ^
       -mapuser svc_postgres@EMPRESA.LOCAL ^
       -crypto AES256-SHA1 ^
       -ptype KRB5_NT_PRINCIPAL ^
       -pass * ^
       -out C:\postgres.keytab
```

5. Transferir y configurar el keytab en el servidor PostgreSQL:
```bash
# Copiar el keytab al servidor PostgreSQL
sudo mv postgres.keytab /var/lib/postgresql/15/main/
sudo chown postgres:postgres /var/lib/postgresql/15/main/postgres.keytab
sudo chmod 600 /var/lib/postgresql/15/main/postgres.keytab
```

6. Configurar PostgreSQL (postgresql.conf):
```ini
listen_addresses = '*'
krb_server_keyfile = '/var/lib/postgresql/15/main/postgres.keytab'
ssl = on
ssl_cert_file = '/etc/postgresql/14/main/server.crt'
ssl_key_file = '/etc/postgresql/14/main/server.key'
```

7. Configurar la autenticación (pg_hba.conf):
```plaintext
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all            all             0.0.0.0/0              reject
hostgssenc all         all             192.168.1.0/24         gss include_realm=0 krb_realm=EMPRESA.LOCAL
```

8. Crear usuarios en PostgreSQL:
```sql
-- Conectar como postgres
CREATE USER "USER1" WITH LOGIN;
GRANT CONNECT ON DATABASE mydb TO "USER1";
```

9. Verificación en el cliente:
```bash
# Obtener ticket Kerberos
kinit usuario@EMPRESA.LOCAL

# Verificar ticket
klist

# Intentar conexión
psql -h pgsql.empresa.local -d mydb -U USER1
```

10. Configuración del cliente PostgreSQL (.pg_service.conf):
```ini
[myapp]
host=pgsql.empresa.local
dbname=mydb
user=USER1
```

11. Script de prueba de conexión (test_connection.py):
```python
import psycopg2

conn_string = "host=pgsql.empresa.local dbname=mydb user=USER1 gssencmode=require"

try:
    conn = psycopg2.connect(conn_string)
    print("Conexión exitosa!")
    
    cur = conn.cursor()
    cur.execute("SELECT current_user")
    result = cur.fetchone()
    print(f"Usuario conectado: {result[0]}")
    
    conn.close()
except Exception as e:
    print(f"Error: {e}")
```

12. Troubleshooting:
```bash
# Verificar estado del servicio
sudo systemctl status postgresql

# Ver logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log

# Probar autenticación Kerberos
kinit -V usuario@EMPRESA.LOCAL

# Verificar SPN
kvno postgres/pgsql.empresa.local@EMPRESA.LOCAL
```

13. Monitoreo de seguridad (agregar al postgresql.conf):
```ini
log_connections = on
log_disconnections = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

Para probar la configuración:

1. Reiniciar PostgreSQL:
```bash
sudo systemctl restart postgresql
```

2. Probar conexión con usuario de dominio:
```bash
# Obtener ticket
kinit usuario@EMPRESA.LOCAL

# Conectar
psql "host=pgsql.empresa.local dbname=mydb user=USER1 gssencmode=require"
```

3. Verificar conexión cifrada:
```sql
SELECT ssl_is_used();
```

Consideraciones de seguridad adicionales:

1. Rotación de keytab:
```bash
# Crear script de renovación
cat > /usr/local/sbin/rotate_keytab.sh << 'EOF'
#!/bin/bash
# Renovar keytab
# Agregar lógica de renovación
systemctl restart postgresql
EOF
chmod +x /usr/local/sbin/rotate_keytab.sh
```

2. Monitoreo de tickets:
```bash
# Crear script de monitoreo
cat > /usr/local/sbin/check_krb_tickets.sh << 'EOF'
#!/bin/bash
klist -s
if [ $? -ne 0 ]; then
    logger -t postgres-krb "Kerberos tickets expired"
    kinit -k -t /var/lib/postgresql/15/main/postgres.keytab postgres/pgsql.empresa.local@EMPRESA.LOCAL
fi
EOF
chmod +x /usr/local/sbin/check_krb_tickets.sh
```

# iniciar servicios  
```
ls -lhtr /lib/systemd/system/ | grep -Ei krb

 

sudo systemctl stop krb*
sudo systemctl start krb*
sudo systemctl enable krb*
sudo systemctl disable krb*
sudo systemctl edit krb*  --full
sudo systemctl status krb*

```

# Bibliogradías 
```
https://community.microstrategy.com/s/article/Use-case-for-Kerberos-against-PostgreSQL-on-MSTR?language=en_US

https://www.crunchydata.com/blog/windows-active-directory-postgresql-gssapi-kerberos-authentication

https://idrawone.github.io/2020/03/11/PostgreSQL-GSSAPI-Authentication-with-Kerberos-part-1/
https://idrawone.github.io/2020/03/12/PostgreSQL-GSSAPI-Authentication-with-Kerberos-part-2/
https://idrawone.github.io/2020/03/15/PostgreSQL-GSSAPI-Authentication-with-Kerberos-part-3/

https://medium.com/@yosra.dridi270/configuration-of-postgresql-authentication-with-kerberos-16b66948a2c3


https://docs.redhat.com/en/documentation/red_hat_directory_server/11/html/administration_guide/configuring_kerberos#Configuring_Kerberos
https://docs.redhat.com/en/documentation/red_hat_amq/2020.q4/html/using_amq_streams_on_rhel/assembly-kerberos_str#kerberos-setting-up_str
https://docs.redhat.com/es/documentation/red_hat_data_grid/6.6/html/security_guide/active_directory_authentication_using_kerberos_gssapi#Active_Directory_Authentication_Using_Kerberos_GSSAPI


https://github.com/SamerBenMim/kerberos-postgres-auth-gssapi
https://www.enterprisedb.com/blog/how-set-kerberos-authentication-using-active-directory-postgresql-database
https://www.percona.com/blog/postgresql-database-security-external-server-based-authentication/
https://docs.vmware.com/en/VMware-Greenplum/7/greenplum-database/admin_guide-kerberos.html
https://www.cockroachlabs.com/docs/stable/gssapi_authentication
https://stackoverflow.com/questions/63469679/log-connection-failed-during-start-up-processing-user-database-fatal-gssapi


https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://www.initmax.cz/wp-content/uploads/2024/06/enterprise-solution-in-postgresql_efficient-and-flexible-access-management.pdf&ved=2ahUKEwjgv7LW0c6JAxU44ckDHV0AMB04FBAWegQIDhAB&usg=AOvVaw2iinqg22Cj0OtAul2x5asI

https://www.google.com/urlsa=t&source=web&rct=j&opi=89978449&url=https://h50146.www5.hpe.com/products/software/oe/linux/mainstream/support/lcc/pdf/PostgreSQL16Beta1_New_Features_en_20230528_1.pdf&ved=2ahUKEwjgv7LW0c6JAxU44ckDHV0AMB04FBAWegQIEBAB&usg=AOvVaw2uE9LdDvwbLsVjo3oLjyiw
https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://postgresconf.org/system/events/document/000/000/183/pgconf_us_v4.pdf&ved=2ahUKEwjrx-Pxyc6JAxUa_8kDHRBNAZgQFnoECBAQAQ&usg=AOvVaw3vBedmi7_ltyjwuVVAgYt-





```
