PostgreSQL tiene soporte nativo para usar conexiones SSL para cifrar las comunicaciones entre cliente y servidor
para mayor seguridad. Esto requiere que OpenSSL esté instalado tanto en los sistemas cliente como servidor y
que el soporte en PostgreSQL esté habilitado en el momento de la compilación.



# Pre-requisitos  
```
    openssl version  # --> OpenSSL igual o mayo a 1.1.1 
    openssl version -d  # --> OPENSSLDIR: "/etc/pki/tls"  Establece valores predeterminados para varios campos en los certificados.
```
 
### Versiones compatibles de SSL/TLS con OpenSSL


| **Versión de OpenSSL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** |
|------------------------|-----------|-----------|-------------|-------------|-------------|-------------|
| **OpenSSL 1.0.x**      | disable   | disable   | true        | true        | true        | false       |
| **OpenSSL 1.1.x**      | false     | false     | true        | true        | true        | false       |
| **OpenSSL 1.1.1**      | false     | false     | true        | true        | true        | true        |
| **OpenSSL 3.0.x**      | false     | false     | true        | true        | true        | true        |

 

### Versiones compatibles de SSL/TLS con PostgreSQL 

| **Versión de PostgreSQL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** | **ssl_min_protocol_version** | **ssl_max_protocol_version** |
|---------------------------|-----------|-----------|-------------|-------------|-------------|-------------|-----------------------------|-----------------------------|
| **9.4**                   | false     | false     | true        | true        | true        | false       | N/A                         | N/A                         |
| **12**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **13**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **14**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **15**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **16**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **17**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
