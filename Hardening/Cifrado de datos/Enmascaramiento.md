## 🎭 3. Enmascaramiento

### ¿Qué es?
El enmascaramiento de datos es una técnica que oculta información sensible para protegerla de accesos no autorizados. Se puede aplicar de forma **dinámica**, **estática**, **parcial** o **completa**, según el caso de uso.  este metodo utiliza User-Defined Function (UDF) para realizar estas acciones 

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

---

## 🕶️ **Flujo de Enmascaramiento de Datos en Base de Datos**
 

### 🧩 1. **Captura del dato original**
El sistema recibe y almacena datos sensibles como nombres, correos, tarjetas, CURP, etc.

Ejemplo:

| ID | Nombre     | Correo               | Tarjeta             |
|----|------------|----------------------|---------------------|
| 1  | Ana López  | ana.lopez@gmail.com  | 4111 1111 1111 1111 |



### 🛡️ 2. **Aplicación del enmascaramiento**

#### 🔸 **Enmascaramiento dinámico**
- Se aplica **en tiempo real**, según el rol del usuario.
- El dato **no se modifica** en la base de datos.
- Se configura en el motor de base de datos (SQL Server, Oracle, etc.).

Ejemplo:
```sql
ALTER TABLE Clientes
ALTER COLUMN Tarjeta ADD MASKED WITH (FUNCTION = 'default()');
```

Resultado para usuario sin privilegios:
| Tarjeta             |
|---------------------|
| XXXX XXXX XXXX XXXX |


#### 🔸 **Enmascaramiento estático**
- Se aplica **antes de almacenar o exportar** los datos.
- El dato se **modifica permanentemente**.
- Ideal para entornos de desarrollo o pruebas.

Ejemplo:
```sql
UPDATE Clientes SET Correo = 'usuario@anonimo.com';
```



#### 🔸 **Enmascaramiento parcial**
- Se ocultan **solo partes del dato**, manteniendo algo visible.
- Útil para mostrar datos parcialmente sin comprometer la privacidad.

Ejemplo:
- `ana.lopez@gmail.com` → `a***@gmail.com`
- `4111 1111 1111 1111` → `4111 **** **** 1111`



#### 🔸 **Enmascaramiento completo**
- Se reemplaza **todo el dato** por un patrón genérico.
- Útil cuando no se necesita mostrar nada del dato original.

Ejemplo:
- `4111 1111 1111 1111` → `XXXX XXXX XXXX XXXX`
- `ana.lopez@gmail.com` → `********@********.***`



### 🔍 3. **Consulta de datos**
- Los usuarios con permisos ven los datos originales.
- Los usuarios restringidos ven los datos enmascarados según la política aplicada.



### 🗃️ 4. **Almacenamiento**
- En el caso de enmascaramiento dinámico, los datos **se almacenan sin cambios**.
- En el caso de enmascaramiento estático, los datos **se modifican antes de guardar**.



## ✅ Comparación rápida

| Tipo               | ¿Modifica el dato? | ¿Reversible? | ¿Basado en rol? | Uso común                      |
|--------------------|-------------------|--------------|------------------|-------------------------------|
| Dinámico           | ❌ No              | ✅ Sí         | ✅ Sí             | Producción, control de acceso |
| Estático           | ✅ Sí              | ❌ No         | ❌ No             | Desarrollo, pruebas           |
| Parcial            | ✅/❌ Depende       | ✅/❌ Depende  | ✅/❌ Depende      | Visualización controlada      |
| Completo           | ✅ Sí              | ❌ No         | ✅/❌ Depende      | Alta privacidad                |
