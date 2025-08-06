## 🔐 1. Cifrado FPE (Format-Preserving Encryption)

### ¿Qué es?
Es un tipo de cifrado de los datos que **mantiene el formato original**  (por ejemplo, longitud y tipo) y lo transforma de forma segura. Es **reversible** si se tiene la clave.
Utiliza algoritmos como FF1 o FF3 definidos por NIST y Requiere una clave secreta para cifrar y descifrar

### ¿Para qué sirve?
- Para proteger datos sensibles **sin alterar el esquema** de la base de datos.
- Ideal en sistemas que requieren que el dato cifrado **parezca válido** (por ejemplo, tarjetas de crédito, CURP, etc.).

### Casos de uso reales:
- Bancos cifran números de tarjeta sin cambiar su longitud.
- Gobiernos cifran identificadores personales (CURP, RFC).
- Empresas de salud cifran números de expediente manteniendo el formato.

### Cumplimientos:
- ✅ **PCI DSS**: Aceptado si se gestiona correctamente la clave.
- ⚠️ **GDPR**: Solo si el dato no puede revertirse fácilmente.
- ✅ **HIPAA**: Permitido si se protege adecuadamente.

### Ventajas:
- Reversible.
- Compatible con sistemas existentes.
- No requiere rediseñar la base de datos.

### Desventajas:
- Requiere gestión segura de claves.
- No elimina completamente el riesgo de reidentificación.
- Implementación más compleja.


### Ejemplos:
- **Número de tarjeta**: `4111111111111111` → `4928374659283746`  
- **Correo electrónico**: `ana.martinez@email.com` → `xqz.lwqjv@qzjv.mom`  
- **CURP**: `MARA800101HDFRNN09` → `XKTL920304JGHZTT83`

🔸 *Observación*: El formato se mantiene (misma longitud, estructura), pero el contenido está cifrado. Es reversible si tienes la clave.


---

## 🔐 **Flujo de Cifrado FPE en Base de Datos**

La técnica FPE permite cifrar datos **manteniendo su formato original**. Por ejemplo, un número de tarjeta de crédito cifrado con FPE sigue pareciendo un número de tarjeta, lo que facilita la integración con sistemas existentes.



### 🧩 1. **Generación del dato sensible**
El dato original (por ejemplo, CURP, tarjeta, RFC, etc.) se captura en la aplicación.



### 🔄 2. **Cifrado con FPE**
El dato se envía a un **motor de cifrado FPE**, que puede estar implementado como:

- **Librería local** (por ejemplo, usando algoritmos como FF1 o FF3 de NIST).
- **API de cifrado** (puede ser interna o de un proveedor como AWS, Thales, etc.).

El motor devuelve el dato cifrado **con el mismo formato**.

Ejemplo:
- Original: `4111 1111 1111 1111`
- Cifrado FPE: `4927 3846 9283 1029`



### 🗃️ 3. **Almacenamiento**
El dato cifrado se guarda directamente en la base de datos, **reemplazando el original** o en una columna separada.

Ejemplo de tabla:

| ID | Nombre | Tarjeta_FPE         |
|----|--------|---------------------|
| 1  | Ana    | 4927 3846 9283 1029 |

No se necesita una bóveda ni mapeo como en la tokenización.



### 🔍 4. **Consulta de datos**
- Si se necesita el dato original, se descifra usando el mismo motor FPE.
- El sistema debe tener acceso a la **clave de cifrado** y al **algoritmo** usado.
- Se puede hacer búsquedas si se cifra el dato de forma **determinista** (el mismo dato produce el mismo cifrado).



### ✅ Ventajas sobre la tokenización

- **No requiere bóveda** ni mapeo.
- **Formato preservado**, útil para validaciones y compatibilidad.
- **Puede ser reversible** si se tiene la clave.
- **Más eficiente** en consultas si se usa cifrado determinista.


### ⚠️ Consideraciones importantes

- La **gestión de claves** es crítica. Si se pierde la clave, se pierde el acceso a los datos.
- Debes usar algoritmos FPE **aprobados por NIST** para cumplir con normativas.
- No todos los formatos son compatibles fácilmente (por ejemplo, textos largos o estructuras complejas).
