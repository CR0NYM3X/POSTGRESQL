El **Hardening de Bases de Datos** 
es el proceso de **asegurar y reforzar la configuración de una base de datos** para reducir su superficie de ataque y protegerla contra accesos no autorizados, vulnerabilidades y amenazas externas o internas.

 
### 🔐 ¿Qué implica el Hardening?

1. **Eliminar configuraciones por defecto inseguras**  
   Muchas bases de datos vienen con configuraciones predeterminadas que pueden ser explotadas si no se modifican.

2. **Restringir el acceso**  
   Solo los usuarios y servicios que realmente lo necesitan deben tener acceso, y con los mínimos privilegios necesarios.

3. **Aplicar parches y actualizaciones**  
   Mantener el software actualizado para corregir vulnerabilidades conocidas.

4. **Cifrar los datos**  
   Tanto en reposo como en tránsito, para evitar que sean leídos si se interceptan.

5. **Auditoría y monitoreo**  
   Registrar y revisar actividades sospechosas o no autorizadas.

6. **Seguridad física y de red**  
   Asegurar que los servidores estén protegidos físicamente y que la red tenga controles como firewalls y segmentación.

 
### 🎯 Objetivo del Hardening

Reducir el riesgo de:

- **Fugas de información**
- **Modificaciones no autorizadas**
- **Interrupciones del servicio**
- **Cumplimiento normativo insuficiente** (como GDPR, HIPAA,  (ISO 27001, CIS Benchmarks, etc.))


###  ¿Para qué sirve escanear PostgreSQL con Tenable-Nessus si ya tiene hardening?

1. ###  **Verificación del hardening**
   - Nessus puede ayudarte a **confirmar que las configuraciones seguras realmente están aplicadas**.

2. ###  **Detección de vulnerabilidades conocidas**
   - Aunque hayas hecho hardening, puede haber **vulnerabilidades en la versión del software** que estás usando.
   - Nessus compara tu instalación con una base de datos de vulnerabilidades (CVE) y te alerta si hay parches pendientes.

3. ###  **Evaluación de configuraciones inseguras**
   - Nessus puede detectar configuraciones que **no son recomendadas**, como:
     - Usuarios con privilegios excesivos
     - Parámetros de autenticación débiles
     - Servicios innecesarios habilitados

4. ###  **Generación de reportes para auditoría**
   - Te permite **documentar el estado de seguridad** de tu base de datos, útil para auditorías internas o externas.
  

--- 
## Temas que se veran en ente proyecto

- Enmascaramiento de datos.
- Cifrado de datos.
- TLS
- Tipos de Autenticación (LDAP, GSSAPI, KERBEROS).
- Configuración de parámetros.
- Buenas practicas.
- Tecnicas de seguridad.

```bash
https://ozwizard.medium.com/20-postgresql-security-tips-9da03310dd74
```
