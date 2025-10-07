 
# 🧪 Manual Técnico: Pruebas Unitarias en PostgreSQL con pgTAP

***

## 1. 📑 Índice

1.  Objetivo
2.  Requisitos
3.  ¿Qué es pgTAP?
4.  Ventajas y Desventajas
5.  Casos de Uso
6.  Escenario simulado empresarial
7.  Estructura Semántica
8.  Visualización del flujo
9.  Procedimientos
    *   Instalación de pgTAP
    *   Creación de esquema de pruebas
    *   Datos ficticios
    *   Pruebas con funciones
    *   Ejecución de pruebas
    *   Validación de resultados
10. Consideraciones
11. Buenas prácticas
12. Tabla comparativa: pgTAP vs pruebas manuales
13. Bibliografía

***

## 2. 🎯 Objetivo

Implementar un entorno de pruebas unitarias en PostgreSQL usando pgTAP para validar funciones SQL en un entorno de QA, simulando un caso empresarial real.

***

## 3. ⚙️ Requisitos

*   PostgreSQL ≥ 13
*   Acceso al entorno de QA con permisos de superusuario
*   pgTAP instalado
*   Conocimientos básicos de funciones SQL
*   Acceso a `psql` o herramienta de administración como DBeaver o pgAdmin

***

## 4. ❓ ¿Qué es pgTAP?

pgTAP es una extensión de PostgreSQL que permite escribir pruebas unitarias en SQL, siguiendo el estilo de TAP (Test Anything Protocol). Es ideal para validar funciones, vistas, triggers y lógica de negocio directamente en la base de datos.

***

## 5. ✅ Ventajas y ❌ Desventajas

| Ventajas                                       | Desventajas                                |
| ---------------------------------------------- | ------------------------------------------ |
| Pruebas automatizadas                          | Requiere instalación adicional             |
| Integración con CI/CD                          | Curva de aprendizaje inicial               |
| Resultados legibles                            | No cubre pruebas de UI o API               |
| Permite pruebas de funciones, vistas, triggers | No reemplaza pruebas funcionales completas |

***

## 6. 🧩 Casos de Uso

*   Validación de funciones matemáticas, de negocio o de transformación de datos
*   Pruebas de triggers antes de pasar a producción
*   Validación de vistas complejas
*   QA en migraciones de versiones

***

## 7. 🏢 Escenario Simulado Empresarial

**Empresa:** AgroData S.A.\
**Caso:** Migración de funciones que calculan el rendimiento de cultivos. Se requiere validar que las funciones migradas devuelven los mismos resultados que en producción.

***

## 8. 🧠 Estructura Semántica

*   Esquema: `qa_test`
*   Función a probar: `calcular_rendimiento(cultivo_id INT)`
*   Tabla base: `cultivos`
*   Tabla de resultados esperados: `rendimiento_esperado`

***

## 9. 📊 Visualización del flujo



***

## 10. 🛠️ Procedimientos

### 🔹 Instalación de pgTAP

```bash
sudo apt install postgresql-14-pgtap
```

Activar extensión en la base de datos:

```sql
CREATE EXTENSION pgtap;
```

### 🔹 Creación de esquema de pruebas

```sql
CREATE SCHEMA qa_test;
SET search_path TO qa_test;
```

### 🔹 Datos ficticios

```sql
CREATE TABLE cultivos (
    cultivo_id SERIAL PRIMARY KEY,
    nombre TEXT,
    hectareas INT,
    produccion_kg INT
);

INSERT INTO cultivos (nombre, hectareas, produccion_kg) VALUES
('Maíz', 10, 8000),
('Trigo', 15, 12000),
('Sorgo', 8, 6000);
```

### 🔹 Función a probar

```sql
CREATE OR REPLACE FUNCTION calcular_rendimiento(cultivo_id INT)
RETURNS NUMERIC AS $$
DECLARE
    hectareas INT;
    produccion INT;
BEGIN
    SELECT hectareas, produccion_kg INTO hectareas, produccion
    FROM cultivos WHERE cultivo_id = calcular_rendimiento.cultivo_id;

    RETURN produccion::NUMERIC / hectareas;
END;
$$ LANGUAGE plpgsql;
```

### 🔹 Pruebas con pgTAP

```sql
SELECT plan(3);

-- Prueba 1: Maíz
SELECT is(
    calcular_rendimiento(1),
    800.0,
    'Rendimiento de Maíz debe ser 800 kg/ha'
);

-- Prueba 2: Trigo
SELECT is(
    calcular_rendimiento(2),
    800.0,
    'Rendimiento de Trigo debe ser 800 kg/ha'
);

-- Prueba 3: Sorgo
SELECT is(
    calcular_rendimiento(3),
    750.0,
    'Rendimiento de Sorgo debe ser 750 kg/ha'
);

SELECT * FROM finish();
```

### 🔹 Simulación de salida esperada

```text
ok 1 - Rendimiento de Maíz debe ser 800 kg/ha
ok 2 - Rendimiento de Trigo debe ser 800 kg/ha
ok 3 - Rendimiento de Sorgo debe ser 750 kg/ha
1..3
```

***

## 11. 🧠 Consideraciones

*   pgTAP no reemplaza pruebas funcionales, pero es ideal para lógica interna
*   Se puede integrar con Jenkins, GitLab CI, etc.
*   Ideal para entornos de QA y staging

***

## 12. 🧼 Buenas prácticas

*   Usar esquemas separados para pruebas
*   Automatizar ejecución en pipelines
*   Versionar los scripts de prueba
*   Validar funciones críticas antes de cada despliegue

***

## 13. 📊 Tabla comparativa: pgTAP vs pruebas manuales

| Característica             | pgTAP | Manual |
| -------------------------- | ----- | ------ |
| Automatización             | ✅     | ❌      |
| Repetibilidad              | ✅     | ❌      |
| Integración CI/CD          | ✅     | ❌      |
| Facilidad de mantenimiento | ✅     | ❌      |
| Curva de aprendizaje       | Media | Baja   |

***


## 14. 📚 Bibliografía
``` 
https://medium.com/engineering-on-the-incline/unit-testing-functions-in-postgresql-with-pgtap-in-5-simple-steps-beef933d02d3
https://medium.com/@daily_data_prep/how-can-i-test-postgressql-database-objects-using-pgtap-9541caf5e85a
https://medium.com/engineering-on-the-incline/unit-testing-postgres-with-pgtap-af09ec42795
https://lebedana21.medium.com/parametric-sql-testing-with-pgtap-find-my-way-from-toy-examples-to-practical-application-a09bd8ae549a

*   <https://github.com/theory/pgtap>
*   <https://www.postgresql.org/docs/>
*   <https://blog.justatheory.com/>

```



