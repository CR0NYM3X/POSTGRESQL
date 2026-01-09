
# 🐘 PostgreSQL Hijacking, `SECURITY DEFINER` y el peligro oculto de `search_path`
 
> En PostgreSQL, **no calificar esquemas** + usar `SECURITY DEFINER` + dejar el `search_path` por default **abre la puerta a hijacking**, permitiendo que un usuario redireccione una función privilegiada a objetos maliciosos (especialmente temporales) **sin modificar el código**.

***

## 📌 ¿Qué es Hijacking en PostgreSQL?

En PostgreSQL, **hijacking** ocurre cuando un usuario logra que una consulta, función o proceso utilice **un objeto distinto al que el desarrollador esperaba**, **sin cambiar el SQL original**.

Esto sucede cuando:

*   El SQL **no califica el esquema** (`SELECT * FROM pwds`)
*   El motor resuelve el objeto usando el **`search_path`**
*   Un atacante **crea un objeto con el mismo nombre** en un esquema que se busca antes

📌 *El resultado*:  
La consulta se ejecuta correctamente… pero **contra el objeto equivocado**.

Esto **NO es SQL Injection**, es **resolución maliciosa de nombres**.

***

## 🔐 ¿Para qué sirve `SECURITY DEFINER`?

Por default, las funciones son:

```sql
SECURITY INVOKER
```

Esto significa:

> La función se ejecuta **con los permisos del usuario que la llama**.

### Entonces, ¿por qué existe `SECURITY DEFINER`?

`SECURITY DEFINER` permite que una función se ejecute **con los permisos de su dueño**, no del invocador.

Se usa para:

*   Exponer operaciones privilegiadas de forma controlada
*   Encapsular lógica administrativa
*   Permitir que roles con pocos permisos realicen acciones específicas

Ejemplo típico:

*   Usuario app\_user **NO puede** insertar en una tabla
*   Función es dueña `postgres`
*   app\_user llama la función
*   ✅ La insert se ejecuta con permisos de `postgres`

👉 **Esto es exactamente lo que hace peligrosa a la combinación con `search_path`.**

***

## 🧭 ¿Qué es `search_path` y para qué sirve?

`search_path` define **el orden de búsqueda de esquemas** cuando PostgreSQL encuentra un objeto **sin esquema explícito**.

Ejemplo:

```sql
SELECT * FROM pwds;
```

PostgreSQL busca `pwds` en los esquemas definidos en `search_path`, **en orden**.

***

## ⚠️ Comportamiento real y oculto de `search_path`

### 📍 Lo que ves normalmente

```sql
SHOW search_path;
```

```text
 "$user", public
```

Esto **confunde** a muchos DBAs, porque **NO muestra todo**.

***

### 📍 El `search_path` REAL por default

Internamente PostgreSQL usa:

```text
pg_temp, pg_catalog, "$user", public
```

📌 \*\*Pero `pg_temp` y `pg_catalog NO se muestran** en `SHOW search\_path\`.

***

## 🔎 Orden real de resolución de objetos

Cuando ejecutas esto:

```sql
SELECT * FROM pwds;
```

PostgreSQL busca así:

1.  **pg\_temp**        ← ⚠️ tablas temporales del usuario
2.  **pg\_catalog**    ← objetos del sistema
3.  **"$user"**       ← esquema con el mismo nombre del usuario
4.  **public**

🔴 **El primer objeto encontrado detiene la búsqueda.**

***

## 🧪 DEMO REAL: Hijacking completo paso a paso

### 1️⃣ Crear usuario y esquema

```sql
CREATE USER user_hijacking WITH SUPERUSER PASSWORD '123123';
CREATE SCHEMA IF NOT EXISTS user_hijacking;
```

***

### 2️⃣ Conectarse como el atacante

```bash
psql -U user_hijacking -d postgres
```

***

### 3️⃣ Crear tablas `pwds` en TODOS los esquemas

```sql
CREATE TEMP TABLE pwds(username text, pwd text);
INSERT INTO pg_temp.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA pg_temp');


SET allow_system_table_mods = on;
CREATE TABLE pg_catalog.pwds(username text primary key, pwd text);
INSERT INTO pg_catalog.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA pg_catalog');


CREATE TABLE user_hijacking.pwds(username text primary key, pwd text);
INSERT INTO user_hijacking.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA user_hijacking');


CREATE TABLE public.pwds(username text primary key, pwd text);
INSERT INTO public.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA PUBLIC');
```

***

### 4️⃣ Todas existen

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'pwds';
```

Resultado:

```text
pg_catalog
pg_temp_x
user_hijacking
public
```

***

### 5️⃣ Ejecutar la misma consulta SIN esquema

```sql
SELECT * FROM pwds;
```

✅ Resultado:

```text
ESTE ES EL ESQUEMA pg_temp
```

***

### 6️⃣ Eliminar objetos y observar el fallback

```sql
DROP TABLE pg_temp.pwds;
SELECT * FROM pwds;
-- pg_catalog

DROP TABLE pg_catalog.pwds;
SELECT * FROM pwds;
-- user_hijacking

DROP TABLE user_hijacking.pwds;
SELECT * FROM pwds;
-- public
```

📌 **Misma consulta, mismo SQL, distinto origen de datos.**
