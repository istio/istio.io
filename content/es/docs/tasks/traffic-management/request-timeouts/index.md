---
title: Timeouts de Solicitud
description: Esta tarea te muestra cómo configurar timeouts de solicitud en Envoy usando Istio.
weight: 40
aliases:
    - /docs/tasks/request-timeouts.html
keywords: [traffic-management,timeouts]
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea te muestra cómo configurar timeouts de solicitud en Envoy usando Istio.

{{< boilerplate gateway-api-support >}}

## Antes de comenzar

* Configura Istio siguiendo las instrucciones en la
  [Guía de instalación](/es/docs/setup/).

* Despliega la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) incluyendo las
  [versiones del servicio](/es/docs/examples/bookinfo/#define-the-service-versions).

## Timeouts de solicitud

Un timeout para solicitudes HTTP puede ser especificado usando un campo timeout en una regla de ruta.
Por defecto, el timeout de solicitud está deshabilitado, pero en esta tarea sobrescribes el timeout del servicio `reviews`
a medio segundo.
Para ver su efecto, sin embargo, también introduces un retraso artificial de 2 segundos en las llamadas
al servicio `ratings`.

1.  Ruta las solicitudes al servicio `reviews` v2, es decir, una versión que llama al servicio `ratings`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Añade un retraso de 2 segundos a las llamadas al servicio `ratings`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Gateway API no soporta la inyección de fallos todavía, por lo que necesitamos usar un `VirtualService` de Istio
para añadir el retraso por ahora:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Abre la URL de Bookinfo `http://$GATEWAY_URL/productpage` en tu navegador, donde `$GATEWAY_URL` es la dirección IP externa del ingress, tal como se explica en
la [Guía de Bookinfo](/es/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) doc.

    Deberías ver la aplicación Bookinfo funcionando normalmente (con estrellas de valoración mostradas),
    pero hay un retraso de 2 segundos cada vez que refrescas la página.

4)  Ahora añade un timeout de solicitud de medio segundo para las llamadas al servicio `reviews`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
    timeouts:
      request: 500ms
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Refresca la página web de Bookinfo.

    Ahora deberías ver que tarda aproximadamente 1 segundo en devolverse, en lugar de 2, y las reseñas no están disponibles.

    {{< tip >}}
    La razón por la que la respuesta tarda 1 segundo, incluso aunque el timeout esté configurado a medio segundo, es
    porque hay un reintento hardcodeado en el servicio `productpage`, por lo que llama al servicio `reviews` que está tardando
    dos veces antes de devolverse.
    {{< /tip >}}

## Entendiendo lo que ocurrió

En esta tarea, usaste Istio para establecer el timeout de solicitud para las llamadas al servicio `reviews`
a medio segundo. Por defecto, el timeout de solicitud está deshabilitado.
Dado que el servicio `reviews` llama al servicio `ratings` cuando maneja las solicitudes,
usaste Istio para inyectar un retraso de 2 segundos en las llamadas a `ratings` para hacer que
el servicio `reviews` tarde más de medio segundo en completarse y, por lo tanto, pudiste ver el timeout en acción.

Observaste que en lugar de mostrar reseñas, la página de producto de Bookinfo (que llama al servicio `reviews` para poblar la página) mostró
el mensaje: Lo sentimos, las reseñas del producto no están disponibles por ahora.
Esto fue el resultado de recibir el error de timeout del servicio `reviews`.

Si examinas la tarea de [inyección de fallos](/es/docs/tasks/traffic-management/fault-injection/), encontrarás que el servicio `productpage`
también tiene su propio timeout de aplicación (3 segundos) para las llamadas al servicio `reviews`.
Observa que en esta tarea usaste una regla de ruta de Istio para establecer el timeout a medio segundo.
Si en su lugar hubieras establecido el timeout a algo mayor que 3 segundos (como 4 segundos), el timeout
no habría tenido efecto ya que el más restrictivo de los dos prevalece.
Más detalles se pueden encontrar [aquí](/es/docs/concepts/traffic-management/#network-resilience-and-testing).

Una cosa más sobre los timeouts en Istio es que, además de sobrescribirlos en las reglas de ruta,
como hiciste en esta tarea, también se pueden sobrescribir a nivel de solicitud por solicitud si la aplicación añade
un encabezado `x-envoy-upstream-rq-timeout-ms` en las solicitudes de salida. En el encabezado,
el timeout se especifica en milisegundos en lugar de segundos.

## Limpieza

*   Elimina las reglas de enrutamiento de la aplicación:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete virtualservice ratings
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Si no tienes intención de explorar ninguna tarea posterior, consulta las
  [instrucciones de limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
  para apagar la aplicación.
