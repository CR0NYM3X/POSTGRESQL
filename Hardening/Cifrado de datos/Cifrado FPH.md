## 🔐 FPH (Format-Preserving Hashing)

### ¿Qué es?
El **hashing con preservación de formato (FPH)** es una técnica que transforma un dato sensible en un valor hash que **mantiene el formato original** del dato. A diferencia del cifrado, el hash **no es reversible**, lo que significa que no se puede recuperar el dato original a partir del hash.

FPH se usa cuando se necesita proteger datos sensibles pero mantener su estructura para compatibilidad con sistemas existentes.


### ¿Para qué sirve?
- Para proteger datos sensibles como identificadores, correos, números de tarjeta, etc.
- Para cumplir normativas como **PCI DSS**, **HIPAA** o **GDPR** sin exponer los datos originales.
- Para realizar comparaciones o validaciones sin revelar el dato real.


### Casos de uso reales:
- **Autenticación**: Comparar contraseñas sin almacenarlas directamente.
- **Sistemas de salud**: Hash de números de expediente manteniendo el formato.
- **Bases de datos**: Almacenar correos o identificadores en formato hash para análisis sin comprometer la privacidad.


### Cumplimientos:
✅ **PCI DSS**: Puede usarse para proteger datos si el hash no permite reidentificación.  
✅ **HIPAA**: Aceptado si se gestiona adecuadamente y no se puede revertir.  
⚠️ **GDPR**: Aceptado si el hash no permite identificar al individuo sin acceso adicional.


### Ventajas:
- **Alta seguridad**: No se puede revertir el hash.
- **Formato preservado**: Compatible con sistemas que requieren estructura específica.
- **Menor carga computacional** que el cifrado.
- **Ideal para validaciones** sin exponer datos.


### Desventajas:
- **No reversible**: No se puede recuperar el dato original.
- **No apto para todos los casos** donde se necesita el dato original.
- **Puede ser vulnerable** si no se usa salting o algoritmos robustos.


### Observación:
- El hash generado **no tiene relación directa visible** con el dato original.
- **No se puede usar para identificar** a una persona sin acceso a datos adicionales.
- **Debe usarse con salting** para evitar ataques por diccionario o fuerza bruta.


## 🔄 Flujo de Hashing en Base de Datos

1. **Captura del dato sensible**  
   El sistema recibe un dato como un correo o número de tarjeta.

2. **Aplicación de FPH**  
   Se aplica un algoritmo de hashing que conserva el formato (ej. longitud, tipo de caracteres).

3. **Almacenamiento del hash**  
   El hash se guarda en la base de datos en lugar del dato original.

   ```sql
   INSERT INTO clientes (nombre, correo_hash)
   VALUES ('Ana Martínez', 'ana.martinez@email.com' → 'am_9f8a7c3b');
   ```

4. **Consulta y validación**  
   Para validar un dato, se aplica el mismo hash y se compara con el almacenado.
