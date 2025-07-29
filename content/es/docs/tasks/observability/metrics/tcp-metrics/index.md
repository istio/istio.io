---
title: Recopilación de Métricas para Services TCP
description: Esta tarea muestra cómo configurar Istio para recopilar métricas para services TCP.
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /docs/tasks/telemetry/tcp-metrics
    - /docs/tasks/telemetry/metrics/tcp-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo configurar Istio para recopilar automáticamente telemetría para services TCP
en una malla. Al final de esta tarea, puede consultar las métricas TCP predeterminadas para su malla.

La application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) se utiliza
como ejemplo a lo largo de esta tarea.

## Antes de empezar

* [Instale Istio](/es/docs/setup) en su cluster y despliegue una
application. También debe instalar [Prometheus](/es/docs/ops/integrations/prometheus/).

* Esta tarea asume que la muestra de Bookinfo se desplegará en el namespace `default`.
Si utiliza un namespace diferente, actualice la
configuración y los comandos de ejemplo.

## Recopilación de nuevos datos de telemetría

1.  Configure Bookinfo para usar MongoDB.

    1.  Instale `v2` del service `ratings`.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        serviceaccount/bookinfo-ratings-v2 created
        deployment.apps/ratings-v2 created
        {{< /text >}}

    1.  Instale el service `mongodb`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        service/mongodb created
        deployment.apps/mongodb-v1 created
        {{< /text >}}

    1.  La muestra de Bookinfo despliega múltiples versiones de cada microservice, así que comience creando reglas de destino
        que definan los subconjuntos de service correspondientes a cada versión, y la política de balanceo de carga para cada subconjunto.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        Si habilitó mTLS, ejecute el siguiente comando en su lugar:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
        {{< /text >}}

        Para mostrar las reglas de destino, ejecute el siguiente comando:

        {{< text bash >}}
        $ kubectl get destinationrules -o yaml
        {{< /text >}}

        Espere unos segundos a que las reglas de destino se propaguen antes de agregar virtual services que hagan referencia a estos subconjuntos, porque las referencias a subconjuntos en los virtual services dependen de las reglas de destino.

    1.  Cree virtual services `ratings` y `reviews`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        virtualservice.networking.istio.io/reviews created
        virtualservice.networking.istio.io/ratings created
        {{< /text >}}

1.  Envíe tráfico a la application de ejemplo.

    Para la muestra de Bookinfo, visite `http://$GATEWAY_URL/productpage` en su navegador web
    o use el siguiente comando:

    {{< text bash >}}
    $ curl http://"$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` es el valor establecido en el ejemplo de [Bookinfo](/es/docs/examples/bookinfo/).
    {{< /tip >}}

1.  Verifique que los valores de las métricas TCP se estén generando y recopilando.

    En un entorno Kubernetes, configure el reenvío de puertos para Prometheus
    usando el siguiente comando:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Vea los valores de las métricas TCP en la ventana del navegador de Prometheus. Seleccione **Graph**.
    Introduzca la métrica `istio_tcp_connections_opened_total` o `istio_tcp_connections_closed_total` y seleccione **Execute**.
    La tabla mostrada en la
    pestaña **Console** incluye entradas similares a:

    {{< text plain >}}
    istio_tcp_connections_opened_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

    {{< text plain >}}
    istio_tcp_connections_closed_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

## Comprender la recopilación de telemetría TCP

En esta tarea, utilizó la configuración de Istio para
generar y reportar automáticamente métricas para todo el tráfico a un service TCP
dentro de la malla.
Las métricas TCP para todas las conexiones activas se registran cada `15s` por defecto y este temporizador es configurable
a través de `tcpReportingDuration`.
Las métricas para una conexión también se registran al final de la conexión.

### Atributos TCP

Varios atributos específicos de TCP permiten la política y el control de TCP dentro de Istio.
Estos atributos son generados por los proxies de Envoy y obtenidos de Istio usando los metadatos de nodo de Envoy.
Envoy reenvía los metadatos de nodo a los Envoy de pares usando tunelización basada en ALPN y un protocolo basado en prefijos.
Definimos un nuevo protocolo `istio-peer-exchange`, que es anunciado y priorizado por el cliente y los sidecars del servidor
en la malla. La negociación ALPN resuelve el protocolo a `istio-peer-exchange` para conexiones entre proxies habilitados para Istio,
pero no entre un proxy habilitado para Istio y cualquier otro proxy.
Este protocolo extiende TCP de la siguiente manera:

1.  El cliente TCP, como primera secuencia de bytes, envía una cadena de bytes mágicos y una carga útil con prefijo de longitud.
1.  El servidor TCP, como primera secuencia de bytes, envía una secuencia de bytes mágicos y una carga útil con prefijo de longitud. Estas cargas útiles
 son metadatos serializados codificados en protobuf.
1.  El cliente y el servidor pueden escribir simultáneamente y fuera de orden. El filtro de extensión en Envoy realiza el procesamiento posterior
 en el flujo descendente y ascendente hasta que la secuencia de bytes mágicos no coincide o se lee toda la carga útil.

{{< image link="./alpn-based-tunneling-protocol.svg"
    alt="Flujo de Generación de Atributos para Services TCP en una Malla de Istio."
    caption="Flujo de Atributos TCP"
    >}}

## Limpieza

*   Elimine el proceso `port-forward`:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

* Si no planea explorar ninguna tarea de seguimiento, consulte las
  instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
  para apagar la application.
