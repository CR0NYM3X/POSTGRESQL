 
### ¿Qué es TimescaleDB?

TimescaleDB es una extensión de PostgreSQL diseñada para manejar datos de series temporales. Esto significa que puedes aprovechar todas las capacidades de PostgreSQL junto con funcionalidades avanzadas específicas para datos temporales.

### Series Temporales

Cuando hablamos de series temporales, nos referimos a datos que se registran en intervalos de tiempo específicos. Estos datos suelen incluir una marca temporal y pueden ser utilizados para analizar tendencias a lo largo del tiempo. Ejemplos comunes de series temporales incluyen:

- **Datos de sensores**: Temperatura, humedad, presión, etc., registrados en intervalos regulares.
- **Logs de aplicaciones**: Eventos y errores registrados con marcas temporales.
- **Datos financieros**: Precios de acciones, volúmenes de transacciones, etc., registrados minuto a minuto.
- **Métricas de rendimiento**: Uso de CPU, memoria, tráfico de red, etc., monitoreados continuamente.
- **Monitoreo de sistemas**: Analizar métricas de rendimiento en intervalos de segundos o minutos.
- **IoT**: Registrar y analizar datos de sensores en intervalos de segundos, minutos o días.
 

### ¿Por qué es tan poderoso?

TimescaleDB tiene varias características clave que lo hacen destacar:

1. **Hypertables**: Estas son tablas que se particionan automáticamente en función del tiempo o de una clave arbitraria. Esto optimiza el almacenamiento y la recuperación de datos de series temporales, permitiendo manejar grandes volúmenes de datos de manera eficiente.

2. **Consultas SQL completas**: Puedes usar consultas SQL estándar para analizar datos de series temporales, combinando la facilidad de uso de los DBMS relacionales con la escalabilidad de los sistemas NoSQL.

3. **Agregaciones continuas**: Permite crear vistas materializadas que se actualizan continuamente, facilitando el cálculo de agregaciones en tiempo real.

4. **Compresión de datos**: Ofrece compresión avanzada para reducir el almacenamiento de datos históricos sin perder eficiencia en las consultas.

5. **Políticas de retención**: Puedes configurar políticas para eliminar automáticamente datos antiguos, ayudando a gestionar el almacenamiento de manera eficiente.

### El secreto de TimescaleDB

El verdadero secreto de TimescaleDB radica en su capacidad para combinar la robustez y familiaridad de PostgreSQL con optimizaciones específicas para datos de series temporales. Esto incluye:

- **Partición automática**: Los datos se distribuyen automáticamente entre las tablas particionadas, mejorando el rendimiento de las consultas.
- **Índices optimizados**: Utiliza índices almacenados en RAM para acelerar la inserción y consulta de datos.
- **Escalabilidad**: Puede manejar grandes volúmenes de datos de manera eficiente, ideal para aplicaciones como monitoreo de sistemas, plataformas de negociación y recopilación de métricas de sensores.


# Bibliografias 
```
https://github.com/timescale/timescaledb
https://www.timescale.com/

# Free
TimeScaleDB — An introduction to time-series databases -> https://medium.com/dataengineering-and-algorithms/timescaledb-an-introduction-to-time-series-databases-3438d275e88e
Step-by-step process of how to install TimescaleDB with PostgreSQL on AWS Ubuntu EC2 -> https://medium.com/@mudasirhaji/step-by-step-process-of-how-to-install-timescaledb-with-postgresql-on-aws-ubuntu-ec2-ddc939dd819c
TimescaleDB: The Essential Guide Start With Time-Series Data -> https://medium.com/@pratiyush1/timescaledb-the-essential-guide-start-with-time-series-data-ce6423ff70c3
Handling Billions of Rows in PostgreSQL -> https://medium.com/timescale/handling-billions-of-rows-in-postgresql-80d3bd24dabb
TimescaleDB vs. Postgres for time-series: 20x higher inserts, 2000x faster deletes, 1.2x-14,000x faster queries -> https://medium.com/timescale/timescaledb-vs-6a696248104e
Continuous Aggregates & Policies with TimescaleDB in PostgreSQL ->  https://medium.com/@anowerhossain97/continuous-aggregates-policies-with-timescaledb-in-postgresql-0ad375a73abd
How I Save System Stat Data in PostgreSQL Using TimescaleDB  -> https://levelup.gitconnected.com/how-i-save-system-stat-data-in-postgresql-using-timescaledb-64e09d54eb1c

# Payment
https://ozwizard.medium.com/managing-time-series-data-using-timescaledb-on-postgres-3752654252d0
Time-Series Data with TimescaleDB and PostgreSQL -> https://medium.com/@tihomir.manushev/time-series-data-with-timescaledb-and-postgresql-3ac9127db90c
```
