# Análisis de Fallos e Incidentes: Arquitectura de Alta Disponibilidad PostgreSQL
Este documento recopila el análisis técnico de comportamiento ante fallos del clúster crítico de bases de datos, con el objetivo de servir como base de conocimiento (*Knowledge Base*) y manual de operaciones (*Runbook*) para el equipo de Ingeniería, conocer el comportamiento de las herramientas ante cada situación.

## 1. Definición del Entorno Tecnológico

* **Sector:** Fintech / Banca Crítica (Disponibilidad 24/7/365).
* **Objetivos de Resiliencia:** RPO = 0 (Cero pérdida de datos) | RTO < 30 segundos (Mínimo tiempo de recuperación).
* **Topología del Clúster:** 3 Nodos PostgreSQL.
  * `Nodo 1`: Maestro (Primary).
  * `Nodo 2`: Réplica Síncrona (Garantía de persistencia inmediata).
  * `Nodo 3`: Réplica Asíncrona (Lecturas distribuidas y DR).

### Stack Tecnológico Integrado
* **Motor:** PostgreSQL (Core de Datos).
* **Orquestación y HA:** Patroni + etcd (Distributed Consensus Store - DCS).
* **Ruteo de Red y Balanceo:** HAProxy + Keepalived (Gestión de IP Virtual - VIP).
* **Pool de Conexiones:** PgBouncer.
* **Seguridad y Auditoría:** pgAudit (Cumplimiento normativo e inalterabilidad de logs).
* **Respaldos:** pgBackRest (Estrategia de backups y archivado WAL corporativo).
