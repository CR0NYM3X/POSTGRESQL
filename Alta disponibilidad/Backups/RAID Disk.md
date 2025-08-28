Un **RAID** (Redundant Array of Independent Disks) es una tecnología que combina múltiples discos duros en una sola unidad lógica para mejorar el rendimiento, la redundancia o ambas cosas. Se usa comúnmente en servidores, centros de datos y sistemas críticos donde la disponibilidad y la velocidad del almacenamiento son esenciales.

### ¿Qué son los discos duros en este contexto?
Los **discos duros** (HDD o SSD) son dispositivos de almacenamiento que guardan datos de forma permanente. En un sistema RAID, varios discos se agrupan para trabajar juntos como si fueran uno solo.

 

### ¿Para qué sirve el RAID?

Dependiendo del tipo de RAID, puede ofrecer:

- **Redundancia**: Si un disco falla, los datos no se pierden.
- **Mejor rendimiento**: Al distribuir los datos entre varios discos, se pueden leer/escribir más rápido.
- **Mayor capacidad**: Algunos niveles combinan discos para sumar espacio.

 

### Tipos comunes de RAID

| Nivel RAID | Características | Ventajas | Desventajas |
|------------|-----------------|----------|-------------|
| RAID 0     | Divide los datos entre discos (striping) | Alta velocidad | Sin redundancia, si falla uno se pierde todo |
| RAID 1     | Copia exacta en dos discos (mirroring) | Alta seguridad | Solo se usa la mitad del espacio |
| RAID 5     | Distribuye datos y paridad entre 3+ discos | Buen equilibrio entre seguridad y rendimiento | Requiere al menos 3 discos |
| RAID 6     | Similar al RAID 5 pero con doble paridad | Mayor tolerancia a fallos | Menor rendimiento en escritura |
| RAID 10    | Combina RAID 1 y RAID 0 | Alta velocidad y redundancia | Requiere al menos 4 discos |

 

### ¿Dónde se usa?

- **Servidores de bases de datos**
- **Sistemas de almacenamiento empresarial**
- **Estaciones de trabajo para edición de video**
- **Sistemas NAS (Network Attached Storage)**
