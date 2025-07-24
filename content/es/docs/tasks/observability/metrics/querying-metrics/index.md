---
title: Consultando Métricas desde Prometheus
description: Esta tarea muestra cómo consultar Métricas de Istio usando Prometheus.
weight: 30
keywords: [telemetry,metrics]
aliases:
    - /docs/tasks/telemetry/querying-metrics/
    - /docs/tasks/telemetry/metrics/querying-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo consultar Métricas de Istio usando Prometheus. Como parte de
esta tarea, utilizará la interfaz web para consultar valores de métricas.

La application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) se utiliza como
application de ejemplo a lo largo de esta tarea.

## Antes de empezar

* [Instale Istio](/es/docs/setup) en su cluster.
* Instale el [Addon de Prometheus](/es/docs/ops/integrations/prometheus/#option-1-quick-start).
* Despliegue la application [Bookinfo](/es/docs/examples/bookinfo/).

## Consultando métricas de Istio

1.  Verifique que el service `prometheus` se esté ejecutando en su cluster.

    En entornos Kubernetes, ejecute el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.109.160.254   <none>        9090/TCP   4m
    {{< /text >}}

1.  Envíe tráfico a la mesh.

    Para la muestra de Bookinfo, visite `http://$GATEWAY_URL/productpage` en su navegador web
    o emita el siguiente comando:

    {{< text bash >}}
    $ curl "http://$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` es el valor establecido en el ejemplo de [Bookinfo](/es/docs/examples/bookinfo/).
    {{< /tip >}}

1.  Abra la UI de Prometheus.

    En entornos Kubernetes, ejecute el siguiente comando:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Haga clic en **Graph** a la derecha de Prometheus en la cabecera.

1.  Ejecute una consulta de Prometheus.

    En el cuadro de entrada "Expression" en la parte superior de la página web, ingrese el texto:

    {{< text plain >}}
    istio_requests_total
    {{< /text >}}

    Luego, haga clic en el botón **Execute**.

Los resultados serán similares a:

{{< image link="./prometheus_query_result.png" caption="Resultado de la Consulta de Prometheus" >}}

También puede ver los resultados de la consulta gráficamente seleccionando la pestaña Graph debajo del botón **Execute**.

{{< image link="./prometheus_query_result_graphical.png" caption="Resultado de la Consulta de Prometheus - Gráfico" >}}

Otras consultas para probar:

*   Recuento total de todas las solicitudes al service `productpage`:

    {{< text plain >}}
    istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

*   Recuento total de todas las solicitudes a `v3` del service `reviews`:

    {{< text plain >}}
    istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    Esta consulta devuelve el recuento total actual de todas las solicitudes a la v3 del service `reviews`.

*   Tasa de solicitudes en los últimos 5 minutos a todas las instancias del service `productpage`:

    {{< text plain >}}
    rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### Acerca del addon de Prometheus

El addon de Prometheus es un servidor Prometheus que viene preconfigurado para extraer
endpoints de Istio para recopilar métricas. Proporciona un mecanismo para el almacenamiento persistente y la consulta
de métricas de Istio.

Para obtener más información sobre cómo consultar Prometheus, lea su [documentación de consulta](https://prometheus.io/docs/querying/basics/).

## Limpieza

*   Elimine cualquier proceso `istioctl` que aún pueda estar ejecutándose usando control-C o:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

*   Si no planea explorar ninguna tarea de seguimiento, consulte las
    instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
    para apagar la application.
