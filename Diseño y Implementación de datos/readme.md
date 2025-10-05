# links para hacer diagramas mas profesionales 
```
--- 
draw.io - https://app.diagrams.net/
https://miro.com/es/
https://mermaid.live 

-- diagramas de secuencia 
https://www.plantuml.com/plantuml/uml/SoWkIImgAStDuNBAJrBGjLDmpCbCJbMmKiX8pSd9JonEuN98pKi1oWC0
https://sequencediagram.org/
https://www.websequencediagrams.com/


```
 

## 📘 Manual Oficial: AGETIC – Estándares de Modelado de Base de Datos Relacional

Este documento fue aprobado por la **Agencia de Gobierno Electrónico y Tecnologías de Información y Comunicación (AGETIC)** mediante resolución administrativa AGETIC/RA/0101/2022. Es un estándar **oficial y normativo** para el diseño de modelos de datos en sistemas gubernamentales y empresariales.

### 🔹 Contenido clave del manual:
1. **Marco normativo**: Basado en leyes y decretos del Estado Plurinacional de Bolivia.
2. **Convenciones generales**:
   - Nombres en español (excepto términos técnicos en inglés).
   - Sin tildes ni “ñ”.
   - Uso de guiones bajos (_), sin preposiciones.
   - Evitar palabras reservadas de SQL.
3. **Nomenclatura de objetos**:
   - Acrónimos para sistemas.
   - Esquemas por módulo de negocio.
   - Tablespaces diferenciados para datos e índices.
   - Tablas históricas, auxiliares y temporales con reglas específicas.
4. **Columnas**:
   - Tipos de datos recomendados (evitar `char`, `money`, `enum`, `oid`).
   - Reglas para columnas numéricas (`int4`, `int8`, `numeric`).
   - Orden de columnas: PK → Auditoría → Datos.
   - Comentarios obligatorios en tablas y columnas.

📄 Puedes consultar el documento completo aquí:  
**[Manual para Estándares de Modelado de Base de Datos Relacional – AGETIC](https://agetic.gob.bo/sites/default/files/2025-02/Manual-para-Estandares-de-Modelado-de-Base-de-Datos-Relacional-firmado-firmado-firmado-firmado.pdf)** [1](https://agetic.gob.bo/sites/default/files/2025-02/Manual-para-Estandares-de-Modelado-de-Base-de-Datos-Relacional-firmado-firmado-firmado-firmado.pdf)

---

## 🌐 Normas Internacionales (ISO / IEC / ANSI / RFC)

### 🔹 **ISO/IEC 9075** – Estándar SQL
- Define el lenguaje SQL en múltiples partes:
  - Parte 1: Framework
  - Parte 2: Foundation
  - Parte 3: Call-Level Interface
  - Parte 4: Persistent Stored Modules
  - Parte 14: SQL/XML
- Reconocido por ANSI y adoptado por la mayoría de los SGBD.

### 🔹 **ISO/IEC 25012** – Calidad de Datos
- Define 15 características de calidad de datos:
  - Exactitud, Completitud, Consistencia, Credibilidad, Actualidad, Accesibilidad, etc.
- Útil para evaluar modelos conceptuales y la calidad de los datos almacenados [2](https://www.iso25000.com/index.php/normas-iso-25000/iso-25012).

### 🔹 **ISO/IEC 9126-3** – Calidad del Software
- Incluye criterios para evaluar la calidad del modelo conceptual de datos [3](http://scielo.org.co/pdf/rfing/v22n35/v22n35a10.pdf).

 

También puedo ayudarte a **adaptar estos estándares a PostgreSQL**, incluyendo ejemplos prácticos. ¿Te gustaría que avancemos con eso?
