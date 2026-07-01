---
title: Ejecutar scripts Lua
description: Describe cómo extender la funcionalidad del proxy usando scripts Lua inline.
weight: 15
keywords: [extensibility,Lua,TrafficExtension]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio proporciona la capacidad de extender la funcionalidad del proxy usando scripts [Lua](https://www.lua.org/) inline
a través de la API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/).
Los filtros Lua son una alternativa ligera a [WebAssembly](/docs/tasks/extensibility/wasm-modules/)
para transformaciones simples de requests y responses — el script se embebe directamente en el recurso y
se ejecuta dentro del proxy Envoy, sin requerir distribución de módulos.

## Antes de comenzar

Despliega la aplicación de ejemplo [Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Configurar un script Lua

Un script Lua debe definir una o ambas de las siguientes funciones:

- `envoy_on_request(request_handle)`: se llama para cada request entrante
- `envoy_on_response(response_handle)`: se llama para cada response saliente

Los handles proporcionan acceso a headers, body, metadata y logging. Consulta la
[documentación del filtro Lua de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter)
para la API completa.

En este ejemplo, agregarás un filtro Lua al ingress gateway que lee un header de request `x-number`
y responde con un header `x-parity` indicando si el valor es `odd` (impar) o `even` (par). El
valor se lee durante el procesamiento del request y se almacena en metadatos dinámicos para que esté disponible al
escribir el header de response:

{{< text syntax=bash snip_id=apply_parity >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
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

## Verificar el script Lua

[Determina la IP y el puerto del ingress](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

Envía un request con un header `x-number` y verifica que `x-parity` esté configurado en la response:

{{< text syntax=bash snip_id=verify_parity_even >}}
$ curl -s -o /dev/null -D - -H "x-number: 42" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: even
{{< /text >}}

{{< text syntax=bash snip_id=verify_parity_odd >}}
$ curl -s -o /dev/null -D - -H "x-number: 7" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: odd
{{< /text >}}

## Orden y alcance

Cuando múltiples recursos `TrafficExtension` apuntan al mismo workload, el orden de ejecución se controla
mediante `phase` y `priority`.

- **`phase`** establece la posición amplia en la cadena de filtros: `AUTHN`, `AUTHZ` o `STATS`.
  Las extensiones sin phase se insertan cerca del final de la cadena, antes del router.
- **`priority`** desempata dentro del mismo phase. Los valores más altos se ejecutan primero.

El campo `match` restringe un `TrafficExtension` a tráfico específico por modo y puerto:

{{< text yaml >}}
spec:
  match:
  - mode: SERVER
    ports:
    - number: 8080
{{< /text >}}

Los modos válidos son `CLIENT` (saliente), `SERVER` (entrante) y `CLIENT_AND_SERVER` (ambos, el valor por defecto).

## Limpieza

{{< text syntax=bash snip_id=clean_up >}}
$ kubectl delete trafficextension -n istio-system parity
{{< /text >}}
