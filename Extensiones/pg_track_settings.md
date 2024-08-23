

# ** pg_track_settings**
Esta extensión permite rastrear cambios en configuraciones y podría adaptarse para monitorear roles y permisos.  captura el estado actual de las configuraciones de tu base de datos en un momento específico. Es como tomar una “foto” la primera vez de cómo están configurados todos los parámetros en ese instante y despues tomar otra foto y comparar los resultados.

### Instalación y Configuración



1. **Instalar la extensión**:
   ```sql
   CREATE EXTENSION pg_track_settings;
   ```
 
 
3. **Historial de Configuraciones**:
   - Para ver el historial de un parámetro específico:
     ```sql
     SELECT * FROM pg_track_settings_log('password_encryption');
     ```

 **Automatización**:
   - Puedes automatizar la captura de snapshots usando `cron` o herramientas como `PoWA` (PostgreSQL Workload Analyzer). Por ejemplo, para tomar un snapshot cada hora:
     ```bash
     0 * * * * psql -U tu_usuario -d tu_base_de_datos -c "SELECT pg_track_settings_snapshot();"
     ```

### Ejemplo Completo

Supongamos que quieres rastrear cambios en las configuraciones de tu base de datos:

1. **Tomar el primer snapshot**:
   ```sql
   SELECT pg_track_settings_snapshot();
   ```

2. **Realizar cambios en la configuración**:
   ```sql
   ALTER SYSTEM SET work_mem = '64MB';
   SELECT pg_reload_conf();
   ```

3. **Obtener las diferencias de los snapshot**:
   ```sql
   SELECT pg_track_settings_snapshot();
   ```

4. **Ver los cambios realizados**:
   ```sql
   SELECT * FROM pg_track_settings_diff(now() - interval '1 hour', now());
   ```
 

# Bibliografía 
https://github.com/rjuju/pg_track_settings

