# Bibliografía 
https://supabase.com/docs/guides/database/postgres/row-level-security#policies

 
### Rules (Reglas)

**Rules** son una característica de PostgreSQL que permite interceptar y modificar consultas SQL antes de que se ejecuten. Se utilizan principalmente para reescribir consultas o para implementar restricciones personalizadas.

#### Características de Rules:
- **Reescritura de consultas**: Puedes modificar la consulta original antes de que se ejecute.
- **Flexibilidad**: Puedes definir reglas para `INSERT`, `UPDATE`, `DELETE`, y `SELECT`.
- **Complejidad**: Las reglas pueden ser complejas y difíciles de mantener en sistemas grandes.

#### Ejemplo de Uso:
- **Auditoría**: Registrar cambios en una tabla sin modificar la lógica de la aplicación.
- **Restricciones personalizadas**: Implementar restricciones que no se pueden lograr con restricciones estándar de SQL.

### Row-Level Security (RLS)

**Row-Level Security (RLS)** es una característica que permite definir políticas de seguridad a nivel de fila. Esto significa que puedes controlar qué filas pueden ser vistas o modificadas por diferentes usuarios.

#### Características de RLS:
- **Seguridad a nivel de fila**: Controla el acceso a filas específicas en una tabla.
- **Políticas de seguridad**: Define políticas que determinan qué filas pueden ser accedidas por cada usuario.
- **Simplicidad**: Más fácil de entender y mantener en comparación con las reglas.

#### Ejemplo de Uso:
- **Multi-tenant applications**: Asegurar que los datos de diferentes clientes no se mezclen.
- **Seguridad**: Implementar controles de acceso detallados basados en roles de usuario.

### Comparación y Escenarios de Uso

| Característica | Rules | RLS |
|----------------|-------|-----|
| **Propósito** | Reescritura de consultas | Seguridad a nivel de fila |
| **Complejidad** | Alta | Baja |
| **Mantenimiento** | Difícil en sistemas grandes | Más fácil |
| **Escenarios** | Auditoría, restricciones personalizadas | Multi-tenant, seguridad detallada |

### Escenarios de Uso

- **Usa Rules** cuando necesites modificar o interceptar consultas SQL para implementar lógica personalizada o auditoría.
- **Usa RLS** cuando necesites implementar controles de acceso detallados a nivel de fila, especialmente en aplicaciones multi-tenant o donde la seguridad es crítica.

 


# Aplicando rules 
```sql
CREATE TABLE datos_generales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100)
);

CREATE RULE restrict_insert AS
ON INSERT TO datos_generales
DO INSTEAD NOTHING;

CREATE RULE restrict_update AS
ON UPDATE TO datos_generales
DO INSTEAD NOTHING;

CREATE RULE restrict_delete AS
ON DELETE TO datos_generales
DO INSTEAD NOTHING;

-- No hay una regla directa para TRUNCATE, pero puedes revocar permisos
REVOKE TRUNCATE ON datos_generales FROM PUBLIC;




``` 



# aplicando RLS Row-Level Security (RLS)
```sql 
-- Crear la tabla clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    telefono VARCHAR(20),
    direccion VARCHAR(200)
);

-- Habilitar Row-Level Security
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

-- Crear el rol
CREATE ROLE cliente_user;

-- Crear políticas de seguridad
CREATE POLICY select_policy ON clientes
FOR SELECT
USING (current_user = 'cliente_user');

CREATE POLICY insert_policy ON clientes
FOR INSERT
WITH CHECK (current_user = 'cliente_user');

CREATE POLICY update_policy ON clientes
FOR UPDATE
USING (current_user = 'cliente_user');

CREATE POLICY delete_policy ON clientes
FOR DELETE
USING (current_user = 'cliente_user');

-- Aplicar las políticas
ALTER TABLE clientes FORCE ROW LEVEL SECURITY;


```
