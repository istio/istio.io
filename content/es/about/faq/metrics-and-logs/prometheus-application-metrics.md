---
title: ¿Puedo usar Prometheus para recopilar métricas de aplicaciones con Istio?
weight: 90
---

Sí. [Prometheus](https://prometheus.io/) es un sistema de monitoreo de código abierto y una base de datos de series de tiempo.
Puede usar Prometheus con Istio para registrar métricas que rastrean la salud de Istio y de
las aplicaciones dentro de la service mesh. Puede visualizar métricas usando herramientas como
[Grafana](/es/docs/ops/integrations/grafana/) y [Kiali](/es/docs/tasks/observability/kiali/).
Consulte [Configuración para Prometheus](/es/docs/ops/integrations/prometheus/#Configuration) para comprender cómo habilitar la recopilación de métricas.

Algunas notas:

- Si el pod de Prometheus se inició antes de que el pod de istiod pudiera generar los certificados requeridos y distribuirlos a Prometheus, el pod de Prometheus deberá
reiniciarse para poder recopilar de los destinos protegidos con TLS mutuo.
- Si su aplicación expone las métricas de Prometheus en un puerto dedicado, ese puerto debe agregarse a las especificaciones del servicio y la implementación.
