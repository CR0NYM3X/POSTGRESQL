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


 ## 📘 **1. ISO/IEC 9075 – Estándar SQL**

- **Organismo**: ISO (International Organization for Standardization) / IEC (International Electrotechnical Commission)
- **Contenido**: Define el lenguaje SQL en múltiples partes (Foundation, Triggers, XML, Temporal, etc.).
- **Aplicación**: Es el estándar **oficial para el diseño lógico y físico** de bases de datos relacionales.
- **Justificación**: Adoptado también por ANSI como estándar nacional.
- **Referencia**: ISO/IEC 9075

---

## 📘 **2. ISO/IEC 25012 – Modelo de Calidad de Datos**

- **Organismo**: ISO/IEC
- **Contenido**: Define 15 características de calidad de datos (exactitud, completitud, consistencia, accesibilidad, etc.).
- **Aplicación**: Se usa para evaluar la calidad del modelo conceptual y los datos que se almacenan.
- **Justificación**: Parte de la familia de normas ISO/IEC 25000 sobre calidad de software y datos.
- **Referencia**: [ISO/IEC 25012](https://www.iso25000.com/index.php/normas-iso-25000/iso-25012) [1](https://www.iso25000.com/index.php/normas-iso-25000/iso-25012)

---

## 📘 **3. ISO/IEC 9126-3 – Calidad del Modelo Conceptual**

- **Organismo**: ISO/IEC
- **Contenido**: Establece criterios para evaluar la calidad del modelo conceptual en el ciclo de vida de una base de datos.
- **Aplicación**: Se usa para validar que el modelo conceptual cumple con los requisitos del negocio y técnicos.
- **Referencia**: [Aplicación del estándar ISO/IEC 9126-3](http://scielo.org.co/scielo.php?script=sci_arttext&pid=S0121-11292013000200010) [2](http://scielo.org.co/scielo.php?script=sci_arttext&pid=S0121-11292013000200010)

---

## 📘 **4. Arquitectura ANSI-SPARC (Modelo de 3 Niveles)**

- **Organismo**: ANSI (American National Standards Institute)
- **Contenido**: Define tres niveles de abstracción para bases de datos:
  - **Nivel externo**: vistas de usuario
  - **Nivel conceptual**: estructura lógica global
  - **Nivel interno**: almacenamiento físico
- **Aplicación**: Base teórica para el diseño conceptual, lógico y físico.
- **Justificación**: Aunque no se formalizó como estándar ISO, es ampliamente aceptado y utilizado en la industria.
- **Referencia**: [Arquitectura ANSI-SPARC](https://es.wikipedia.org/wiki/Arquitectura_ANSI-SPARC) [3](https://es.wikipedia.org/wiki/Arquitectura_ANSI-SPARC)

---

## 📘 **5. Estándares ANSI SQL (SQL-86, SQL-89, SQL-92, SQL:1999, SQL:2003, etc.)**

- **Organismo**: ANSI / ISO
- **Contenido**: Evolución del lenguaje SQL desde sus primeras versiones hasta las actuales.
- **Aplicación**: Define cómo estructurar, manipular y controlar datos en bases de datos relacionales.
- **Justificación**: Base de todos los motores SQL modernos (PostgreSQL, Oracle, SQL Server, MySQL).
- **Referencia**: [Estándares ANSI SQL](http://www.coninteres.es/sql/material/Estandares_ANSI-SQL.pdf) [4](http://www.coninteres.es/sql/material/Estandares_ANSI-SQL.pdf)

---

## 📘 **6. Manual AGETIC – Estándares de Modelado de Base de Datos Relacional**

Este documento fue aprobado por la **Agencia de Gobierno Electrónico y Tecnologías de Información y Comunicación (AGETIC)** mediante resolución administrativa AGETIC/RA/0101/2022. Es un estándar **oficial y normativo** para el diseño de modelos de datos en sistemas gubernamentales y empresariales.

- **Contenido**: Manual oficial con normas de nomenclatura, estructura, tipos de datos, documentación y auditoría.
- **Aplicación**: Diseño físico y lógico de bases de datos relacionales en entornos gubernamentales y empresariales.
- **Justificación**: Aprobado por resolución administrativa oficial.


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
