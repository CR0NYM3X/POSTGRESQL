## 🔐 **Tokenización**

### ¿Qué es?
La **tokenización y DesTokenización** es una técnica de protección de datos que consiste en **reemplazar un dato sensible por un valor alternativo (token)** que **no tiene valor fuera del sistema que lo genera**. A diferencia del cifrado, el token **no se deriva matemáticamente del dato original**, lo que lo hace inútil si se intercepta.



### ¿Para qué sirve?
- Para **proteger datos sensibles** como números de tarjeta, identificadores personales, correos, etc.
- Para **cumplir normativas** como PCI DSS sin necesidad de cifrar directamente los datos.
- Para **minimizar el riesgo** en caso de fuga de información.



### Casos de uso reales:
- **Procesamiento de pagos**: Un número de tarjeta como `4111111111111111` se reemplaza por un token como `tok_9f8a7c3b2d`.
- **Sistemas de salud**: El número de expediente `EXP123456` se tokeniza como `TKN-00123`.
- **Aplicaciones móviles**: El correo `ana.martinez@email.com` se tokeniza como `user_abc123`.



### Cumplimientos:
- ✅ **PCI DSS**: La tokenización es una técnica aprobada para proteger datos de tarjetas.
- ✅ **HIPAA**: Puede usarse para proteger datos de salud si se gestiona adecuadamente.
- ⚠️ **GDPR**: Aceptada si el token no permite reidentificación sin acceso al sistema de mapeo.



### Ventajas:
- **Alta seguridad**: El token no revela nada del dato original.
- **No requiere cifrado**: Reduce la carga computacional.
- **Flexible**: Se puede usar en múltiples sistemas sin exponer el dato real.
- **Cumple normativas**: Especialmente útil en pagos y salud.



### Desventajas:
- **No reversible sin el sistema de mapeo**.
- **Requiere infraestructura adicional** para gestionar los tokens.
- **Dependencia del proveedor** si se usa tokenización externa.


 
### Observación:
- Los tokens **no tienen relación matemática** con el dato original.
- Solo el sistema que los genera puede **mapearlos de vuelta**.
- Si se filtran, **no pueden usarse para identificar a nadie**.


 
### 🔐 ¿Cómo funciona la tokenización en bases de datos?

 
## 🔄 **Flujo de Tokenización en Base de Datos**

### 1. **Captura del dato sensible**
- El usuario o sistema ingresa un dato sensible (ej. número de tarjeta de crédito) a través de una aplicación web, móvil o backend.
- Este dato **no se guarda directamente** en la base de datos.



### 2. **Envío al servicio de tokenización**
- La aplicación envía el dato a un **servicio de tokenización**, que puede ser:
  - Una **API REST** (local o externa).
  - Un **módulo interno** en el backend.
  - Un **servicio de terceros** especializado en seguridad.



### 3. **Generación del token**
- El servicio genera un **token único** que representa el dato original.
- Este token puede mantener el formato (si se usa FPE) o ser completamente diferente.
- Se guarda una **relación segura** entre el dato original y el token en una bóveda o base de datos cifrada.



### 4. **Almacenamiento del token**
- El token se guarda en la base de datos principal, en lugar del dato original.

Ejemplo:

```sql
INSERT INTO clientes (nombre, tarjeta_token)
VALUES ('Juan Pérez', 'TK_8f3a9c1d');
```
 
### 5. **Consulta del dato (lectura)**
#### Opción A: Solo se necesita el token
- Si la aplicación solo necesita mostrar el token (ej. últimos 4 dígitos), se consulta directamente la base de datos.

#### Opción B: Se necesita el dato original
- La aplicación **consulta el token** en la base de datos.
- Luego, **envía el token al servicio de detokenización** (API).
- El servicio valida permisos y devuelve el dato original **solo si está autorizado**.

 

### 6. **Uso del dato original**
- El dato original se usa temporalmente en la aplicación (ej. para procesar un pago).
- No se guarda en la base de datos ni se expone innecesariamente.

 
## 🔐 ¿La aplicación consulta la API o la base de datos?

Depende del caso:

- **Para almacenar**: la aplicación consulta la **API de tokenización** y guarda el token en la base de datos.
- **Para consultar**:
  - Si solo se necesita el token → se consulta la **base de datos**.
  - Si se necesita el dato original → se consulta la **API de detokenización** usando el token.
