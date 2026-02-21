# Peerdb

### Explicación Profesional: El método CTID

Normalmente, cuando herramientas como `pg_dump` o la replicación nativa de Postgres mueven una tabla, lo hacen de forma **secuencial**: empiezan por la primera fila y terminan en la última (un solo hilo/proceso). Si la tabla pesa 1TB, esto tarda una eternidad.

PeerDB rompe esta limitación haciendo lo siguiente:

1. **Segmentación Física (CTIDs):** En Postgres, cada fila tiene un identificador oculto llamado `ctid` que indica su ubicación física exacta en el disco (en qué bloque de datos está). PeerDB divide la tabla en "trozos" basados en rangos de estos `ctid`.
2. **Lectura Multihilo:** En lugar de una sola conexión leyendo la tabla, PeerDB abre, por ejemplo, 8 o 16 conexiones simultáneas. Cada una se encarga de un "trozo" de la ubicación física del disco.
3. **Consistencia de Snapshot:** Para que los datos no sean un caos (mientras unos leen el principio, otros el final y la base de datos sigue recibiendo cambios), PeerDB usa `pg_export_snapshot()`. Esto le dice a todas las conexiones: "Ignoren lo que pase después de este segundo, todos lean la foto exacta de la tabla en este instante".
4. **Protocolo Binario:** En lugar de convertir los datos a texto (que es lento), PeerDB usa el formato binario nativo de Postgres, enviando los datos casi como están en el disco hacia el destino.

---

### La Analogía: "La Mudanza del Edificio de Archivos"

Imagina que tienes que mudar **un millón de cajas** de un edificio viejo (Postgres) a uno nuevo (ClickHouse).

* **Método tradicional (pg_dump/Nativo):** Tienes a **un solo trabajador** con un carrito. Él entra al edificio, sube al primer piso, agarra una caja, la lleva al edificio nuevo, regresa por la segunda, y así sucesivamente. Si se cansa o se tropieza (error de red), a veces tiene que empezar de nuevo o se pierde el orden. Es desesperadamente lento.
* **El método PeerDB:**
1. **El Mapa:** PeerDB no mira el contenido de las cajas, mira el **plano del edificio**. Dice: "Tú, trabajador 1, encárgate de las habitaciones 1 a la 10. Tú, trabajador 2, de la 11 a la 20", y así hasta tener 16 trabajadores. (Esto es el **CTID**: la ubicación física).
2. **La Foto:** Antes de empezar, PeerDB toma una **foto instantánea** de todo el edificio. Si alguien mete una caja nueva mientras ellos trabajan, los mudanceros la ignoran porque no estaba en la foto original. (Esto es el **Snapshot**).
3. **Trabajo en Equipo:** Los 16 trabajadores sacan las cajas al mismo tiempo por 16 puertas diferentes.
4. **Cinta Transportadora:** No se detienen a etiquetar cada caja en un idioma nuevo; simplemente pasan las cajas tal cual están (formato binario) a través de un tubo directo al otro edificio.



**Resultado:** Lo que al trabajador solitario le tomaba 17 horas, al equipo coordinado de PeerDB le toma menos de 2 horas.

**En resumen:** PeerDB es mejor porque sabe "picar" una sola tabla gigante en pedazos físicos y procesarlos todos a la vez sin perder la coherencia de los datos.

# Links
```
https://clickhouse.com/blog/practical-postgres-migrations-at-scale-peerdb
```
