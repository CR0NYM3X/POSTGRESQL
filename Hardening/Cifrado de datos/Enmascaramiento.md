## 🎭 3. Enmascaramiento

### ¿Qué es?
Ocultamiento parcial o total del dato, puede ser **reversible o no**, dependiendo del método. este metodo utiliza UDF para realizar estas acciones 

### ¿Para qué sirve?
- Para mostrar datos parcialmente ocultos en interfaces.
- Para pruebas con datos simulados.

### Casos de uso reales:
- Dashboards muestran solo parte del número de tarjeta.
- QA usa datos enmascarados para pruebas.
- Atención al cliente ve solo parte del correo o teléfono.

### Cumplimientos:
- ⚠️ **PCI DSS**: Aceptado si es irreversible.
- ⚠️ **GDPR**: Depende del riesgo residual.
- ⚠️ **HIPAA**: Solo si no hay riesgo de reidentificación.

### Ventajas:
- Fácil de implementar.
- Útil para visualización y pruebas.
- Puede ser reversible si se controla el acceso.

### Desventajas:
- No protege datos en reposo.
- No siempre cumple con normativas.
- No sirve para cifrado fuerte.


### Ejemplos:
- **Número de tarjeta**: `4111111111111111` → `4111********1111`  
- **Correo electrónico**: `ana.martinez@email.com` → `a***@email.com`  
- **CURP**: `MARA800101HDFRNN09` → `MARA80******FRNN09`

🔸 *Observación*: Se oculta parte del dato. Puede ser reversible si se controla el acceso o se usa en tiempo real.
