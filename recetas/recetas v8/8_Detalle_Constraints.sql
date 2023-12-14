/* 
		Consulta: BPD-Detalle_Constraints
La ejecución muestra el listado de los contraints y el nombre de la tabla a la que pertenece y su relacion con las otras tablas, consultando unicamente 
la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Nombre_Esquema
- Nombre_Constraint
- Tabla_PK
- Columna_PK		
- Tabla_PK
- Columna_FK		
*/

select
t1.CONSTRAINT_SCHEMA AS Esquema, t0.CONSTRAINT_NAME as Nombre_Constraint,
t1.TABLE_NAME as Tabla_FK,
t3.COLUMN_NAME as Columna_FK,
t2.TABLE_NAME as Tabla_PK,
t4.COLUMN_NAME as Columna_PK
from 
INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS t0
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS t1 ON t0.CONSTRAINT_NAME = t1.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS t2 ON t0.UNIQUE_CONSTRAINT_NAME = t2.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE t3 ON t0.CONSTRAINT_NAME = t3.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE t4 ON t0.UNIQUE_CONSTRAINT_NAME = t4.CONSTRAINT_NAME
ORDER BY 1, 2;