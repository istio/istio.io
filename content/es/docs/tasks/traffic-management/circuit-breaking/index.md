---
title: Circuit Breaking
description: Esta tarea muestra cómo configurar el interruptor de circuito para conexiones, solicitudes y detección de valores atípicos.
weight: 50
keywords: [traffic-management,circuit-breaking]
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea muestra cómo configurar el interruptor de circuito para conexiones, solicitudes
y detección de valores atípicos.

el interruptor de circuito es un patrón importante para crear applications de microservicios resilientes.
el interruptor de circuito le permite escribir applications que limitan el impacto de fallos, picos de latencia y otros efectos indeseables de las peculiaridades de la red.

En esta tarea, configurará las reglas de interruptor de circuito y luego probará la
configuración "disparando" intencionalmente el disyuntor.

## Antes de empezar

* Configure Istio siguiendo las instrucciones de la
  [guía de instalación](/es/docs/setup/).

{{< boilerplate start-httpbin-service >}}

La application `httpbin` sirve como service de backend para esta tarea.

## Configuración del disyuntor

1.  Cree una [regla de destino](/es/docs/reference/config/networking/destination-rule/) para aplicar la configuración de interruptor de circuito
al llamar al service `httpbin`:

    {{< warning >}}
    Si instaló/configuró Istio con la autenticación mTLS habilitada, debe agregar una política de tráfico TLS `mode: ISTIO_MUTUAL` a la `DestinationRule` antes de aplicarla.
    De lo contrario, las solicitudes generarán errores 503 como se describe [aquí](/es/docs/ops/common-problems/network-issues/#503-errors-after-setting-destination-rule).
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: httpbin
    spec:
      host: httpbin
      trafficPolicy:
        connectionPool:
          tcp:
            maxConnections: 1
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
        outlierDetection:
          consecutive5xxErrors: 1
          interval: 1s
          baseEjectionTime: 3m
          maxEjectionPercent: 100
    EOF
    {{< /text >}}

1.  Verifique que la regla de destino se creó correctamente:

    {{< text bash yaml >}}
    $ kubectl get destinationrule httpbin -o yaml
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    ...
    spec:
      host: httpbin
      trafficPolicy:
        connectionPool:
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
          tcp:
            maxConnections: 1
        outlierDetection:
          baseEjectionTime: 3m
          consecutive5xxErrors: 1
          interval: 1s
          maxEjectionPercent: 100
    {{< /text >}}

## Añadir un cliente

Cree un cliente para enviar tráfico al service `httpbin`. El cliente es
un cliente de prueba de carga simple llamado [fortio](https://github.com/istio/fortio).
Fortio le permite controlar el número de conexiones, la concurrencia y
los retrasos para las llamadas HTTP salientes. Utilizará este cliente para "disparar" las políticas de interruptor de circuito
que estableció en la `DestinationRule`. 

1. Inyecte el cliente con el proxy sidecar de Istio para que las interacciones de red estén
regidas por Istio.

    Si ha habilitado la [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), despliegue el service `fortio`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/sample-client/fortio-deploy.yaml@
    {{< /text >}}

    De lo contrario, debe inyectar manualmente el sidecar antes de desplegar la application `fortio`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
    {{< /text >}}

1. Inicie sesión en el pod del cliente y use la herramienta fortio para llamar a `httpbin`.
Pase `curl` para indicar que solo desea hacer una llamada:

    {{< text bash >}}
    $ export FORTIO_POD=$(kubectl get pods -l app=fortio -o 'jsonpath={.items[0].metadata.name}')
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio curl -quiet http://httpbin:8000/get
    HTTP/1.1 200 OK
    server: envoy
    date: Tue, 25 Feb 2020 20:25:52 GMT
    content-type: application/json
    content-length: 586
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 36

    {
      "args": {},
      "headers": {
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "fortio.org/fortio-1.3.1",
        "X-B3-Parentspanid": "8fc453fb1dec2c22",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "071d7f06bc94943c",
        "X-B3-Traceid": "86a929a0e76cda378fc453fb1dec2c22",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/httpbin;Hash=68bbaedefe01ef4cb99e17358ff63e92d04a4ce831a35ab9a31d3c8e06adb038;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      },
      "origin": "127.0.0.1",
      "url": "http://httpbin:8000/get"
    }
    {{< /text >}}

¡Puede ver que la solicitud tuvo éxito! Ahora, es hora de romper algo.

## Disparar el disyuntor

En la configuración de `DestinationRule`, especificó `maxConnections: 1` y
`http1MaxPendingRequests: 1`. Estas reglas indican que si excede más de
una conexión y solicitud concurrentemente, debería ver algunos fallos cuando el
`istio-proxy` abra el circuito para futuras solicitudes y conexiones.

1. Llame al service con dos conexiones concurrentes (`-c 2`) y envíe 20 solicitudes
(`-n 20`):

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
    20:33:46 I logger.go:97> Log level is now 3 Warning (was 2 Info)
    Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 20 calls: http://httpbin:8000/get
    Starting at max qps with 2 thread(s) [gomax 6] for exactly 20 calls (10 per thread + 0)
    20:33:46 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 59.8524ms : 20 calls. qps=334.16
    Aggregated Function Time : count 20 avg 0.0056869 +/- 0.003869 min 0.000499 max 0.0144329 sum 0.113738
    # range, mid point, percentile, count
    >= 0.000499 <= 0.001 , 0.0007495 , 10.00, 2
    > 0.001 <= 0.002 , 0.0015 , 15.00, 1
    > 0.003 <= 0.004 , 0.0035 , 45.00, 6
    > 0.004 <= 0.005 , 0.0045 , 55.00, 2
    > 0.005 <= 0.006 , 0.0055 , 60.00, 1
    > 0.006 <= 0.007 , 0.0065 , 70.00, 2
    > 0.007 <= 0.008 , 0.0075 , 80.00, 2
    > 0.008 <= 0.009 , 0.0085 , 85.00, 1
    > 0.011 <= 0.012 , 0.0115 , 90.00, 1
    > 0.012 <= 0.014 , 0.013 , 95.00, 1
    > 0.014 <= 0.0144329 , 0.0142165 , 100.00, 1
    # target 50% 0.0045
    # target 75% 0.0075
    # target 90% 0.012
    # target 99% 0.0143463
    # target 99.9% 0.0144242
    Sockets used: 4 (for perfect keepalive, would be 2)
    Code 200 : 17 (85.0 %)
    Code 503 : 3 (15.0 %)
    Response Header Sizes : count 20 avg 195.65 +/- 82.19 min 0 max 231 sum 3913
    Response Body/Total Sizes : count 20 avg 729.9 +/- 205.4 min 241 max 817 sum 14598
    All done 20 calls (plus 0 warmup) 5.687 ms avg, 334.2 qps
    {{< /text >}}

¡Es interesante ver que casi todas las solicitudes pasaron! El `istio-proxy`
permite cierto margen de maniobra.

    {{< text plain >}}
    Code 200 : 17 (85.0 %)
    Code 503 : 3 (15.0 %)
    {{< /text >}}

1. Aumente el número de conexiones concurrentes a 3:

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
    20:32:30 I logger.go:97> Log level is now 3 Warning (was 2 Info)
    Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 30 calls: http://httpbin:8000/get
    Starting at max qps with 3 thread(s) [gomax 6] for exactly 30 calls (10 per thread + 0)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 51.9946ms : 30 calls. qps=576.98
    Aggregated Function Time : count 30 avg 0.0040001633 +/- 0.003447 min 0.0004298 max 0.015943 sum 0.1200049
    # range, mid point, percentile, count
    >= 0.0004298 <= 0.001 , 0.0007149 , 16.67, 5
    > 0.001 <= 0.002 , 0.0015 , 36.67, 6
    > 0.002 <= 0.003 , 0.0025 , 50.00, 4
    > 0.003 <= 0.004 , 0.0035 , 60.00, 3
    > 0.004 <= 0.005 , 0.0045 , 66.67, 2
    > 0.005 <= 0.006 , 0.0055 , 76.67, 3
    > 0.006 <= 0.007 , 0.0065 , 83.33, 2
    > 0.007 <= 0.008 , 0.0075 , 86.67, 1
    > 0.008 <= 0.009 , 0.0085 , 90.00, 1
    > 0.009 <= 0.01 , 0.0095 , 96.67, 2
    > 0.014 <= 0.015943 , 0.0149715 , 100.00, 1
    # target 50% 0.003
    # target 75% 0.00583333
    # target 90% 0.009
    # target 99% 0.0153601
    # target 99.9% 0.0158847
    Sockets used: 20 (for perfect keepalive, would be 3)
    Code 200 : 11 (36.7 %)
    Code 503 : 19 (63.3 %)
    Response Header Sizes : count 30 avg 84.366667 +/- 110.9 min 0 max 231 sum 2531
    Response Body/Total Sizes : count 30 avg 451.86667 +/- 277.1 min 241 max 817 sum 13556
    All done 30 calls (plus 0 warmup) 4.000 ms avg, 577.0 qps
    {{< /text >}}

Ahora comienza a ver el comportamiento esperado de interruptor de circuito. Solo el 36.7% de las
solicitudes tuvieron éxito y el resto fueron atrapadas por el interruptor de circuito:

    {{< text plain >}}
    Code 200 : 11 (36.7 %)
    Code 503 : 19 (63.3 %)
    {{< /text >}}

1. Consulte las estadísticas de `istio-proxy` para ver más:

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.circuit_breakers.default.remaining_pending: 1
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.circuit_breakers.default.rq_pending_open: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.circuit_breakers.high.rq_pending_open: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.upstream_rq_pending_active: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.upstream_rq_pending_failure_eject: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.upstream_rq_pending_overflow: 21
    cluster.outbound|8000||httpbin.default.svc.cluster.local;.upstream_rq_pending_total: 29
    {{< /text >}}

    Puede ver `21` para el valor `upstream_rq_pending_overflow`, lo que significa que `21`
    llamadas hasta ahora han sido marcadas para interruptor de circuito.

## Limpieza

1.  Elimine las reglas:

    {{< text bash >}}
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1.  Apague el service [httpbin]({{< github_tree >}}/samples/httpbin) y el cliente:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/sample-client/fortio-deploy.yaml@
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}
