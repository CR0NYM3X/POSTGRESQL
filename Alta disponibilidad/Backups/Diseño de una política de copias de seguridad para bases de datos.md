### Diseño de una política de copias de seguridad para bases de datos

Una vez que has adquirido todos los conocimientos presentados en este curso, ya estás preparado para **diseñar una política de copias de seguridad** para tus bases de datos.

#### Paso 1: Diseñar antes de programar

Antes de comenzar a programar scripts que realicen backups, **siéntate a diseñar la política**. Este diseño no solo se enfoca en las copias de seguridad, sino en **conocer a fondo la base de datos** que vas a proteger. Esto te permitirá planificar rutinas de mantenimiento, optimizar el rendimiento, programar actualizaciones, y mucho más.

Aunque el curso se centra en las copias de seguridad, el diseño de una política efectiva requiere hacerse **las siguientes preguntas clave**:



### Preguntas esenciales para diseñar tu política de backups

1. **¿Qué función tiene la base de datos?**
   - ¿Es una base de datos de almacén que solo recibe transacciones de escritura?
   - ¿Sirve a una aplicación como control de acceso a un edificio?
   - ¿Es una base de datos histórica que solo se consulta y rara vez se actualiza?
   - ¿Es una base de datos muy activa, con transacciones constantes 24/7?
   - ¿Pertenece a un pequeño comercio local y está ociosa en noches, fines de semana y festivos?

2. **¿Cómo llegan las transacciones a la base de datos?**
   - ¿Siempre a través de una aplicación bien diseñada y segura?
   - ¿Hay acceso directo por parte de desarrolladores?
   - ¿Existe alta rotación de personal que accede a la base?

3. **¿Dónde está alojada la base de datos?**
   - ¿En un servidor físico o virtualizado?
   - ¿De qué año es el hardware?
   - ¿Qué sistema operativo utiliza?
   - ¿Qué tipo de discos tiene (SSD, HDD)?
   - ¿Están en RAID? ¿Qué tipo de RAID?

4. **¿El servidor se usa exclusivamente para la base de datos o para otras tareas también?**

5. **¿Existen cláusulas de disponibilidad en el contrato del proveedor del servicio?**
   - ¿Qué requerimientos específicos debes cumplir según el contrato?

6. **¿Cómo acceden los usuarios?**
   - ¿Cada uno con credenciales únicas?
   - ¿Todos usan las mismas credenciales?



### Recomendaciones para el diseño

Una vez que tengas toda esta información, estarás listo para diseñar la política de seguridad más adecuada. Para ello:

- **Habla con los administradores de sistemas, desarrolladores, usuarios, clientes y responsables.**
- **No te quedes con dudas.**
- Descubrirás áreas que podrían mejorarse para evitar riesgos, pero recuerda: **no todo se puede cambiar de inmediato**.
- Lo que sí puedes hacer es **proteger la base de datos con buenos backups** y proponer mejoras que se implementarán con el tiempo (o no), dependiendo de factores externos como el presupuesto.



### Consejo clave: Planifica recuperaciones, no solo backups

No planifiques solo tus backups. **Planifica tus recuperaciones**. Esto te permitirá saber qué tipo de backups necesitas.

Para ello, considera:

- ¿Qué tipos de fallos podrían ocurrir?
- ¿Qué tipo de recuperación necesitarías en cada caso?
- ¿Necesitas una recuperación total o parcial?
- ¿Necesitas recuperación en un punto en el tiempo?

Medita y planifica bien. En muchos casos, será útil tener **múltiples tipos de backups** para cubrir distintos escenarios, pero sin excederse: **solo lo necesario**.



### Último consejo del curso

Antes de recuperar un servidor, **haz siempre una copia de seguridad del estado actual**, porque cualquier problema podría empeorar.



### Conclusión

Espero que estos consejos te hayan dado una idea clara y útil. Ahora, **ponte manos a la obra**:

- Infórmate bien  
- Piensa  
- Planifica  
- Programa  
- Documenta
