---
title: Visualizando Métricas con Grafana
description: Esta tarea muestra cómo configurar y usar el Dashboard de Istio para monitorear el tráfico de la malla.
weight: 40
keywords: [telemetry,visualization]
aliases:
    - /docs/tasks/telemetry/using-istio-dashboard/
    - /docs/tasks/telemetry/metrics/using-istio-dashboard/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo configurar y usar el Dashboard de Istio para monitorear el
tráfico de la malla. Como parte de esta tarea, utilizará el addon de Grafana Istio y
la interfaz web para ver los datos de tráfico de la service mesh.

La application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) se utiliza como
application de ejemplo a lo largo de esta tarea.

## Antes de empezar

* [Instale Istio](/es/docs/setup) en su cluster.
* Instale el [Addon de Grafana](/es/docs/ops/integrations/grafana/#option-1-quick-start).
* Instale el [Addon de Prometheus](/es/docs/ops/integrations/prometheus/#option-1-quick-start).
* Despliegue la application [Bookinfo](/es/docs/examples/bookinfo/).

## Visualizando el dashboard de Istio

1.  Verifique que el service `prometheus` se esté ejecutando en su cluster.

    En entornos Kubernetes, ejecute el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.100.250.202   <none>        9090/TCP   103s
    {{< /text >}}

1.  Verifique que el service de Grafana se esté ejecutando en su cluster.

    En entornos Kubernetes, ejecute el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    grafana   ClusterIP   10.103.244.103   <none>        3000/TCP   2m25s
    {{< /text >}}

1.  Abra el Dashboard de Istio a través de la UI de Grafana.

    En entornos Kubernetes, ejecute el siguiente comando:

    {{< text bash >}}
    $ istioctl dashboard grafana
    {{< /text >}}

    Visite [http://localhost:3000/d/G8wLrJIZk/istio-mesh-dashboard](http://localhost:3000/d/G8wLrJIZk/istio-mesh-dashboard) en su navegador web.

    El Dashboard de Istio se verá similar a:

    {{< image link="./grafana-istio-dashboard.png" caption="Dashboard de Istio" >}}

1.  Envíe tráfico a la malla.

    Para la muestra de Bookinfo, visite `http://$GATEWAY_URL/productpage` en su navegador web
    o emita el siguiente comando:

    {{< boilerplate trace-generation >}}

    {{< tip >}}
    `$GATEWAY_URL` es el valor establecido en el ejemplo de [Bookinfo](/es/docs/examples/bookinfo/).
    {{< /tip >}}

    Actualice la página varias veces (o envíe el comando varias veces) para generar una
    pequeña cantidad de tráfico.

    Vuelva a mirar el Dashboard de Istio. Debería reflejar el tráfico que se
    generó. Se verá similar a:

    {{< image link="./dashboard-with-traffic.png" caption="Dashboard de Istio con Tráfico" >}}

    Esto proporciona una vista global de la Malla junto con los services y workloads en la malla.
    Puede obtener más detalles sobre los services y workloads navegando a sus dashboards específicos como se explica a continuación.

1.  Visualizar Dashboards de Service.

    Desde el menú de navegación de la esquina superior izquierda del dashboard de Grafana, puede navegar al Dashboard de Service de Istio o visitar
    [http://localhost:3000/d/LJ_uJAvmk/istio-service-dashboard](http://localhost:3000/d/LJ_uJAvmk/istio-service-dashboard) en su navegador web.

    {{< tip >}}
    Es posible que deba seleccionar un service en el menú desplegable Service.
    {{< /tip >}}

    El Dashboard de Service de Istio se verá similar a:

    {{< image link="./istio-service-dashboard.png" caption="Dashboard de Service de Istio" >}}

    Esto proporciona detalles sobre las métricas para el service y luego los workloads del cliente (workloads que están llamando a este service)
    y los workloads del service (workloads que están proporcionando este service) para ese service.

1.  Visualizar Dashboards de Workload.

    Desde el menú de navegación de la esquina superior izquierda del dashboard de Grafana, puede navegar al Dashboard de Workload de Istio o visitar
    [http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard](http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard) en su navegador web.

    El Dashboard de Workload de Istio se verá similar a:

    {{< image link="./istio-workload-dashboard.png" caption="Dashboard de Workload de Istio" >}}

    Esto proporciona detalles sobre las métricas para cada workload y luego los workloads de entrada (workloads que están enviando solicitudes a
    este workload) y los services de salida (services a los que este workload envía solicitudes) para ese workload.

### Acerca de los dashboards de Grafana

El Dashboard de Istio consta de tres secciones principales:

1. Una Vista de Resumen de la Malla. Esta sección proporciona una vista de Resumen Global de la Malla y muestra los workloads HTTP/gRPC y TCP
   en la Malla.

1. Vista de Services Individuales. Esta sección proporciona métricas sobre solicitudes y
   respuestas para cada service individual dentro de la malla (HTTP/gRPC y TCP).
   También proporciona métricas sobre los workloads del cliente y del service para este service.

1. Vista de Workloads Individuales: Esta sección proporciona métricas sobre solicitudes y
   respuestas para cada workload individual dentro de la malla (HTTP/gRPC y TCP).
   También proporciona métricas sobre los workloads de entrada y los services de salida para este workload.

Para obtener más información sobre cómo crear, configurar y editar dashboards, consulte la
[documentación de Grafana](https://docs.grafana.org/).

## Limpieza

*   Elimine cualquier proceso `kubectl port-forward` que pueda estar ejecutándose:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* Si no planea explorar ninguna tarea de seguimiento, consulte las
[instrucciones de limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
para apagar la application.
