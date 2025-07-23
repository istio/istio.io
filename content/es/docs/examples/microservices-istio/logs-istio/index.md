---
title: Monitoreo con Istio
overview: Recopilación y consulta de métricas de malla.
weight: 72
owner: istio/wg-docs-maintainers
test: no
---

El monitoreo es crucial para apoyar la transición al estilo de arquitectura de microservicios.

Con Istio, obtienes monitoreo del tráfico entre microservicios por defecto.
Puedes usar el Dashboard de Istio para monitorear tus microservicios en tiempo real.

Istio está integrado de forma nativa con
[Prometheus time series database and monitoring system](https://prometheus.io). Prometheus recopila varias
métricas relacionadas con el tráfico y proporciona
[un lenguaje de consulta enriquecido](https://prometheus.io/docs/prometheus/latest/querying/basics/) para ellas.

Ve a continuación varios ejemplos de consultas de Prometheus relacionadas con Istio.

1.  Accede a la interfaz de usuario de Prometheus en [http://my-istio-logs-database.io](http://my-istio-logs-database.io).
(La URL `my-istio-logs-database.io` debería estar en tu archivo /etc/hosts, la configuraste
[anteriormente](/es/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    {{< image width="80%" link="prometheus.png" caption="Interfaz de Usuario de Consultas de Prometheus" >}}

1.  Ejecuta las siguientes consultas de ejemplo en el cuadro de entrada _Expression_. Presiona el botón _Execute_ para ver los resultados de las consultas en
la pestaña _Console_. Las consultas usan `tutorial` como el nombre del namespace de la aplicación, sustitúyelo con el nombre de
tu namespace. Para mejores resultados, ejecuta el simulador de tráfico en tiempo real descrito en los pasos anteriores al consultar datos.

    1. Obtener todas las solicitudes en tu namespace:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination"}
        {{< /text >}}

    1.  Obtener la suma de todas las solicitudes en tu namespace:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination"})
        {{< /text >}}

    1.  Obtener las solicitudes al microservicio `reviews`:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}
        {{< /text >}}

    1.  [Tasa](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate) de solicitudes durante los últimos 5 minutos a todas las instancias del microservicio `reviews`:

        {{< text plain >}}
        rate(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}[5m])
        {{< /text >}}

Las consultas anteriores usan la métrica `istio_requests_total`, que es una métrica estándar de Istio. Puedes observar
otras métricas, en particular, las de Envoy ([Envoy](https://www.envoyproxy.io) es el sidecar proxy de Istio). Puedes
ver las métricas recopiladas en el menú desplegable _insert metric at cursor_.

## Siguientes pasos

¡Felicidades por completar el tutorial!

Estas tareas son un excelente lugar para que los principiantes evalúen más
características de Istio usando esta instalación `demo`:

- [Enrutamiento de solicitudes](/es/docs/tasks/traffic-management/request-routing/)
- [Inyección de fallas](/es/docs/tasks/traffic-management/fault-injection/)
- [Cambio de tráfico](/es/docs/tasks/traffic-management/traffic-shifting/)
- [Consulta de métricas](/es/docs/tasks/observability/metrics/querying-metrics/)
- [Visualización de métricas](/es/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Acceso a servicios externos](/es/docs/tasks/traffic-management/egress/egress-control/)
- [Visualización de tu malla](/es/docs/tasks/observability/kiali/)

Antes de personalizar Istio para uso en producción, consulta estos recursos:

- [Modelos de despliegue](/es/docs/ops/deployment/deployment-models/)
- [Mejores prácticas de despliegue](/es/docs/ops/best-practices/deployment/)
- [Requisitos de Pod](/es/docs/ops/deployment/application-requirements/)
- [Instrucciones generales de instalación](/es/docs/setup/)

## Únete a la comunidad de Istio

Te damos la bienvenida para que hagas preguntas y nos brindes retroalimentación uniéndote a la
[comunidad de Istio](/get-involved/).
