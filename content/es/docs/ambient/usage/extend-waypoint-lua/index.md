---
title: Extender waypoints con scripts Lua
description: Describe cómo extender los waypoint proxies en modo ambient usando scripts Lua inline.
weight: 56
keywords: [extensibility,Lua,TrafficExtension,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio permite extender los waypoint proxies usando scripts [Lua](https://www.lua.org/) inline
a través de la API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/).
En modo ambient, los recursos `TrafficExtension` deben adjuntarse a un waypoint proxy usando `targetRefs`.

## Antes de comenzar

1. Configura Istio siguiendo la [guía de inicio rápido en modo ambient](/docs/ambient/getting-started).
1. Despliega la [aplicación de ejemplo Bookinfo](/docs/ambient/getting-started/deploy-sample-app).
1. [Agrega el namespace default a la mesh ambient](/docs/ambient/getting-started/secure-and-visualize).
1. Despliega la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) como fuente de prueba:

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## En un gateway

Obtén el nombre del gateway:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

Crea un `TrafficExtension` apuntando al `bookinfo-gateway` con un filtro Lua de paridad. El filtro
lee el header de solicitud `x-number` y agrega el header de respuesta `x-parity` indicando si el
valor es `odd` (impar) o `even` (par). El valor se almacena en metadatos dinámicos durante el procesamiento de la solicitud para que
esté disponible al escribir el header de respuesta:

{{< text syntax=bash snip_id=apply_lua_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verificar el tráfico a través del gateway

{{< text syntax=bash snip_id=test_gateway_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 4" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage" | grep x-parity
x-parity: even
{{< /text >}}

## En un waypoint, para todos los servicios de un namespace

### Desplegar un waypoint proxy

Sigue las [instrucciones de despliegue de waypoint](/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy)
para desplegar un waypoint proxy en el namespace de bookinfo:

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

Verifica que el tráfico llega al servicio:

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

Obtén el nombre del gateway del waypoint:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

Crea un `TrafficExtension` apuntando al waypoint:

{{< text syntax=bash snip_id=apply_lua_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verificar el tráfico a través del waypoint proxy

{{< text syntax=bash snip_id=test_waypoint_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 7" http://productpage:9080/productpage | grep x-parity
x-parity: odd
{{< /text >}}

## En un waypoint, para un servicio específico

Elimina el filtro a nivel de namespace y reemplázalo con uno que apunte únicamente al servicio `reviews`:

{{< text syntax=bash snip_id=remove_waypoint_parity >}}
$ kubectl delete trafficextension parity-at-waypoint
{{< /text >}}

Crea un `TrafficExtension` apuntando directamente al servicio `reviews` para que el filtro se aplique
únicamente al tráfico destinado a ese servicio:

{{< text syntax=bash snip_id=apply_lua_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-for-reviews
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  match:
  - mode: SERVER
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verificar el tráfico apuntando al servicio

{{< text syntax=bash snip_id=test_waypoint_service_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 3" http://reviews:9080/reviews/1 | grep x-parity
x-parity: odd
{{< /text >}}

## Limpieza

1. Elimina los recursos `TrafficExtension`:

    {{< text syntax=bash snip_id=remove_traffic_extensions >}}
    $ kubectl delete trafficextension parity-at-gateway parity-for-reviews
    {{< /text >}}

1. Sigue la [guía de desinstalación del modo ambient](/docs/ambient/getting-started/#uninstall) para eliminar
   Istio y las aplicaciones de prueba de ejemplo.
