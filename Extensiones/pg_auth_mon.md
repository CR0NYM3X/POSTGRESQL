
# pg_auth_mon : es una extensión para PostgreSQL que facilita el monitoreo de los intentos de autenticación de usuarios 
 

### Validar si esta instalada la extensión :
     rpm -qa | grep pg_auth_mon  # pg_auth_mon_16-2.0-1.rhel8.x86_64 
 
 
### Instalación de pg_auth_mon en caso de que no se tenga en el repositorio 


1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/RafiaSabih/pg_auth_mon.git
   ```
2. **Ingresar al directorio del proyecto**:
   ```bash
   cd pg_auth_mon
   ```
3. **Compilar e instalar la extensión**:
   ```bash
   make
   sudo make install
   ```
4. **Agregar la extensión a tu base de datos**:
   ```sql
   CREATE EXTENSION pg_auth_mon;
   ```

### Uso de pg_auth_mon

Una vez instalada, pg_auth_mon comenzará a registrar los intentos de autenticación en una tabla específica. Puedes consultar esta tabla para revisar los intentos de inicio de sesión:

```sql
SELECT * FROM pg_auth_mon_log;
```

### Beneficios de usar pg_auth_mon

- **Monitoreo en tiempo real**: Te permite ver quién intenta acceder a tu base de datos y desde dónde.
- **Seguridad mejorada**: Ayuda a identificar y responder rápidamente a posibles intentos de acceso no autorizados.
- **Auditoría**: Mantiene un registro detallado de todos los intentos de autenticación, útil para auditorías de seguridad.
 
 
### limitaciones que debes tener en cuenta:

1. **Compatibilidad**: Puede haber problemas de compatibilidad con ciertas versiones de PostgreSQL. Por ejemplo, se han reportado problemas con PostgreSQL 13.2³.
2. **Rendimiento**: Al registrar cada intento de autenticación, puede generar una sobrecarga adicional en el sistema, especialmente en bases de datos con un alto volumen de conexiones.
3. **Almacenamiento**: La extensión almacena los intentos de autenticación en una tabla, lo que puede llevar a un crecimiento significativo del tamaño de la base de datos si no se gestionan adecuadamente los registros antiguos.
4. **Funcionalidad limitada**: Aunque es útil para monitorear intentos de autenticación, no ofrece funcionalidades avanzadas de seguridad como la detección de patrones de ataque o la integración con sistemas de alerta.
5.- En caso de que el usuario que intento iniciar session no exista en la vista pg_roles,   la tabla  pg_auth_mon registrará el usuario nombre de usuario,  y se suman en la columna other_auth_failures en una única fila con el oid en cero, siempre se sumara y solo en una sola fila los usuarios que no existan 
