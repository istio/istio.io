---
title: Enrutamiento de Solicitudes
description: Esta tarea te muestra cómo configurar el enrutamiento dinámico de solicitudes a múltiples versiones de un microservicio.
weight: 10
aliases:
    - /docs/tasks/request-routing.html
keywords: [traffic-management,routing]
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea te muestra cómo enrutar solicitudes dinámicamente a múltiples versiones de un
microservicio.

{{< boilerplate gateway-api-support >}}

## Antes de comenzar

* Configura Istio siguiendo las instrucciones en la
  [Guía de instalación](/es/docs/setup/).

* Despliega la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/).

* Revisa el documento de conceptos de [Gestión de Tráfico](/es/docs/concepts/traffic-management).

## Acerca de esta tarea

La muestra de [Bookinfo](/es/docs/examples/bookinfo/) de Istio consiste en cuatro microservicios separados, cada uno con múltiples versiones.
Tres versiones diferentes de uno de los microservicios, `reviews`, han sido desplegadas y están ejecutándose concurrentemente.
Para ilustrar el problema que esto causa, accede a la `/productpage` de la aplicación Bookinfo en un navegador y actualiza varias veces.
La URL es `http://$GATEWAY_URL/productpage`, donde `$GATEWAY_URL` es la dirección IP externa del ingress, como se explica en
la documentación de [Bookinfo](/es/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

Notarás que a veces la salida de reseñas del libro contiene calificaciones con estrellas y otras veces no.
Esto es porque sin una versión de servicio predeterminada explícita a la que enrutar, Istio enruta solicitudes a todas las versiones disponibles
de manera round robin.

El objetivo inicial de esta tarea es aplicar reglas que enruten todo el tráfico a `v1` (versión 1) de los microservicios. Más tarde,
aplicarás una regla para enrutar tráfico basado en el valor de una cabecera de solicitud HTTP.

## Enrutar a la versión 1

Para enrutar a solo una versión, configuras reglas de enrutamiento que envían tráfico a versiones predeterminadas para los microservicios.

{{< warning >}}
Si no lo has hecho ya, sigue las instrucciones en [definir las versiones del servicio](/es/docs/examples/bookinfo/#define-the-service-versions).
{{< /warning >}}

1. Ejecuta el siguiente comando para crear las reglas de enrutamiento:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Istio usa virtual services para definir reglas de enrutamiento.
Ejecuta el siguiente comando para aplicar virtual services que enrutarán todo el tráfico a `v1` de cada microservicio:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

Debido a la consistencia eventual de la configuración, espera unos segundos
para que los virtual services surtan efecto.

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
    - name: reviews-v1
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Muestra las rutas definidas con el siguiente comando:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash yaml >}}
$ kubectl get virtualservices -o yaml
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - details
    http:
    - route:
      - destination:
          host: details
          subset: v1
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - productpage
    http:
    - route:
      - destination:
          host: productpage
          subset: v1
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - ratings
    http:
    - route:
      - destination:
          host: ratings
          subset: v1
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - reviews
    http:
    - route:
      - destination:
          host: reviews
          subset: v1
{{< /text >}}

También puedes mostrar las definiciones de `subset` correspondientes con el siguiente comando:

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get httproute reviews -o yaml
...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: Route was valid
      observedGeneration: 8
      reason: Accepted
      status: "True"
      type: Accepted
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: All references resolved
      observedGeneration: 8
      reason: ResolvedRefs
      status: "True"
      type: ResolvedRefs
    controllerName: istio.io/gateway-controller
    parentRef:
      group: gateway.networking.k8s.io
      kind: Service
      name: reviews
      port: 9080
{{< /text >}}

En el estado del recurso, asegúrate de que la condición `Accepted` sea `True` para el padre `reviews`.

{{< /tab >}}

{{< /tabset >}}

Has configurado Istio para enrutar a la versión `v1` de los microservicios del Bookinfo,
especialmente la versión del servicio `reviews` 1.

## Prueba la nueva configuración de enrutamiento

Puedes probar fácilmente la nueva configuración refrescando la `/productpage`
de la aplicación Bookinfo en tu navegador.
Observa que la parte de reseñas de la página se muestra sin estrellas,
independientemente de cuántas veces la actualices. Esto es porque configuraste Istio para enrutar
todo el tráfico para el servicio `reviews` a la versión `reviews:v1` y esta
versión del servicio no accede al servicio de calificaciones de estrellas.

Has cumplido con la primera parte de esta tarea: enrutar tráfico a una
versión de un servicio.

## Enrutar basado en la identidad del usuario

A continuación, cambiarás la configuración de enrutamiento para que todo el tráfico de un usuario
específico se enrute a una versión de servicio específica. En este caso, todo el tráfico de un usuario
llamado Jason se enrutará al servicio `reviews:v2`.

Este ejemplo está habilitado por el hecho de que el servicio `productpage`
añade un encabezado personalizado `end-user` a todas las solicitudes HTTP salientes al servicio `reviews`.

Istio también admite enrutamiento basado en JWT fuertemente autenticado en el gateway de entrada, consulta la
[Enrutamiento basado en reclamo de JWT](/es/docs/tasks/security/authentication/jwt-route) para más detalles.

Recuerda, `reviews:v2` es la versión que incluye la característica de calificaciones de estrellas.

1. Ejecuta el siguiente comando para habilitar el enrutamiento basado en el usuario:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
{{< /text >}}

Puedes confirmar que la regla se ha creado usando el siguiente comando:

{{< text bash yaml >}}
$ kubectl get virtualservice reviews -o yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
...
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
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
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) En la `/productpage` de la aplicación Bookinfo, inicia sesión como usuario `jason`.

    Refresca el navegador. ¿Qué ves? Las calificaciones de estrellas aparecen junto a cada
    reseña.

3) Inicia sesión como otro usuario (elige cualquier nombre que desees).

    Refresca el navegador. Ahora las estrellas se han ido. Esto es porque el tráfico se enruta
    a `reviews:v1` para todos los usuarios excepto Jason.

Has configurado correctamente Istio para enrutar tráfico basado en la identidad del usuario.

## Entendiendo lo que sucedió

En esta tarea, usaste Istio para enviar el 100% del tráfico a la versión
`v1` de cada uno de los microservicios del Bookinfo. Luego, estableciste una regla para enviar tráfico
selectivamente a la versión `v2` del servicio `reviews` basado en un encabezado personalizado `end-user` añadido
a la solicitud por el servicio `productpage`.

Ten en cuenta que los servicios de Kubernetes, como los del Bookinfo utilizados en esta tarea, deben
cumplir ciertas restricciones para aprovechar las características de enrutamiento L7 de Istio. Consulta la
[Requisitos para Pods y Servicios](/es/docs/ops/deployment/application-requirements/) para más detalles.

En la tarea de [desplazamiento de tráfico](/es/docs/tasks/traffic-management/traffic-shifting), seguirás
el mismo patrón básico que aprendiste aquí para configurar reglas de enrutamiento para
enviar gradualmente el tráfico de una versión de un servicio a otra.

## Limpieza

1. Elimina las reglas de enrutamiento de la aplicación:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Si no planeas explorar ninguna tarea posterior, consulta las
  [Instrucciones de limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
  para apagar la aplicación.
