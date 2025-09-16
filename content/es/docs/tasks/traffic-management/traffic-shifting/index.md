---
title: Desplazamiento de Tráfico
description: Te muestra cómo migrar tráfico de una versión antigua a una nueva versión de un servicio.
weight: 30
keywords: [traffic-management,traffic-shifting]
aliases:
    - /docs/tasks/traffic-management/version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea te muestra cómo desplazar tráfico de una versión de un microservicio a otra.

Un caso de uso común es migrar tráfico gradualmente de una versión antigua de un microservicio a una nueva.
En Istio, logras este objetivo configurando una secuencia de reglas de enrutamiento que redirigen un porcentaje de tráfico
de un destino a otro.

En esta tarea, enviarás 50% del tráfico a `reviews:v1` y 50% a `reviews:v3`. Luego,
completarás la migración enviando 100% del tráfico a `reviews:v3`.

{{< boilerplate gateway-api-support >}}

## Antes de comenzar

* Configura Istio siguiendo las instrucciones en la
  [Guía de instalación](/es/docs/setup/).

* Despliega la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/).

* Revisa el documento de conceptos de [Gestión de Tráfico](/es/docs/concepts/traffic-management).

## Aplicar enrutamiento basado en peso

{{< warning >}}
Si no lo has hecho ya, sigue las instrucciones en [definir las versiones del servicio](/es/docs/examples/bookinfo/#define-the-service-versions).
{{< /warning >}}

1.  Para comenzar, ejecuta este comando para enrutar todo el tráfico a la versión `v1`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Abre el sitio Bookinfo en tu navegador. La URL es `http://$GATEWAY_URL/productpage`, donde `$GATEWAY_URL` es la dirección IP externa del ingress, como se explica en
el documento [Bookinfo](/es/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

    Nota que la parte de reseñas de la página se muestra sin estrellas,
    independientemente de cuántas veces la refresques. Esto es porque configuraste Istio para enrutar
    todo el tráfico para el servicio de reseñas a la versión `reviews:v1` y esta
    versión del servicio no accede al servicio de valoraciones.

3)  Transfiere el 50% del tráfico de `reviews:v1` a `reviews:v3` con el siguiente comando:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Espera unos segundos para que las nuevas reglas se propaguen y luego
confirma que la regla se reemplazó:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash outputis=yaml snip_id=verify_config_50_v3 >}}
$ kubectl get virtualservice reviews -o yaml
apiVersion: networking.istio.io/v1
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
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash outputis=yaml snip_id=gtw_verify_config_50_v3 >}}
$ kubectl get httproute reviews -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
...
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 50
    - group: ""
      kind: Service
      name: reviews-v3
      port: 9080
      weight: 50
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-10T18:13:43Z"
      message: Route was valid
      observedGeneration: 14
      reason: Accepted
      status: "True"
      type: Accepted
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Refresca la `/productpage` en tu navegador y ahora verás *rojas* las estrellas de valoración aproximadamente el 50% del tiempo. Esto es porque la versión `v3` de `reviews` accede
al servicio de valoraciones, pero la versión `v1` no.

    {{< tip >}}
    Con la implementación actual del sidecar de Envoy, puede que necesites refrescar
    la `/productpage` muchas veces --quizás 15 o más-- para ver la distribución correcta.
    Puedes modificar las reglas para enrutar el 90% del tráfico a `v3` para ver las estrellas rojas
    más a menudo.
    {{< /tip >}}

6)  Suponiendo que decides que el microservicio `reviews:v3` es estable, puedes
enrutar el 100% del tráfico a `reviews:v3` aplicando este servicio virtual:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) Refresca la `/productpage` varias veces. Ahora siempre verás reseñas de libros
    con *rojas* las estrellas de valoración para cada reseña.

## Entendiendo lo que sucedió

En esta tarea migras tráfico de una versión antigua a una nueva versión del servicio `reviews` usando la característica de enrutamiento ponderado de Istio. Ten en cuenta que esto es muy diferente a hacer la migración de versiones usando las características de escalado de instancias de orquestación de contenedores, que usan el escalado de instancias para gestionar el tráfico.

Con Istio, puedes permitir que las dos versiones del servicio `reviews` escalen independientemente, sin afectar la distribución del tráfico entre ellas.

Para más información sobre el enrutamiento de versiones con autoscaling, consulta el artículo del blog [Desplazamientos de canario usando Istio](/blog/2017/0.1-canary/).

## Limpieza

1. Elimina las reglas de enrutamiento de la aplicación:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_cleanup >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Si no planeas explorar ninguna tarea posterior, consulta las
  instrucciones de [limpieza del Bookinfo](/es/docs/examples/bookinfo/#cleanup)
  para apagar la aplicación.
