---
title: Habilitar Límites de Tasa usando Envoy
description: Esta tarea muestra cómo configurar Istio para limitar dinámicamente el tráfico a un service.
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo usar la limitación de tasa nativa de Envoy para limitar dinámicamente el tráfico a un service de Istio.
En esta tarea, aplicará un límite de tasa global para el service `productpage` a través del ingress gateway que permite
1 solicitud por minuto en todas las instancias del service. Además, aplicará un límite de tasa local para cada
instancia individual de `productpage` que permitirá 4 solicitudes por minuto. De esta manera, se asegurará de que el service `productpage`
maneje un máximo de 1 solicitud por minuto a través del ingress gateway, pero cada instancia de `productpage` puede manejar
hasta 4 solicitudes por minuto, permitiendo cualquier tráfico dentro de la mesh.

## Antes de empezar

1. Configure Istio en un cluster de Kubernetes siguiendo las instrucciones de la
   [Guía de Instalación](/es/docs/setup/getting-started/).

1. Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/).

## Límites de tasa

Envoy admite dos tipos de limitación de tasa: global y local. La limitación de tasa global
utiliza un service de limitación de tasa gRPC global para proporcionar limitación de tasa para toda la mesh.
La limitación de tasa local se utiliza para limitar la tasa de solicitudes por instancia de service.
La limitación de tasa local se puede utilizar junto con la limitación de tasa global para reducir la carga en
el service de limitación de tasa global.

En esta tarea, configurará Envoy para limitar la tasa de tráfico a una ruta específica de un service
utilizando límites de tasa tanto globales como locales.

## Límite de tasa global

Envoy se puede utilizar para [configurar límites de tasa globales](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting) para su malla.
La limitación de tasa global en Envoy utiliza una API gRPC para solicitar cuota de un service de limitación de tasa.
A continuación se utiliza una [implementación de referencia](https://github.com/envoyproxy/ratelimit) de la API, escrita en Go con un backend de Redis.

1. Utilice el siguiente configmap para [configurar la implementación de referencia](https://github.com/envoyproxy/ratelimit#configuration)
    para limitar la tasa de solicitudes a la ruta `/productpage` a 1 solicitud/min, un valor `api` para el siguiente ejemplo avanzado, y todas las demás solicitudes a 100 solicitudes/min.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ratelimit-config
    data:
      config.yaml: |
        domain: ratelimit
        descriptors:
          - key: PATH
            value: "/productpage"
            rate_limit:
              unit: minute
              requests_per_unit: 1
          - key: PATH
            value: "api"
            rate_limit:
              unit: minute
              requests_per_unit: 2
          - key: PATH
            rate_limit:
              unit: minute
              requests_per_unit: 100
    EOF
    {{< /text >}}

1. Cree un service de límite de tasa global que implemente el
  [protocolo de service de límite de tasa](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/ratelimit/v3/rls.proto) de Envoy.
  Como referencia, se puede encontrar una configuración de demostración [aquí]({{< github_blob >}}/samples/ratelimit/rate-limit-service.yaml),
  que se basa en una [implementación de referencia](https://github.com/envoyproxy/ratelimit) proporcionada por Envoy.

    {{< text bash >}}
    $ kubectl apply -f @samples/ratelimit/rate-limit-service.yaml@
    {{< /text >}}

1. Aplique un `EnvoyFilter` al `ingressgateway` para habilitar la limitación de tasa global utilizando el filtro de límite de tasa global de Envoy.

    El parche inserta el filtro
    [global de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit)
    `envoy.filters.http.ratelimit` en la cadena `HTTP_FILTER`. El campo `rate_limit_service` especifica el service de límite de tasa externo,
    `outbound|8081||ratelimit.default.svc.cluster.local` en este caso.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit
      namespace: istio-system
    spec:
      workloadSelector:
        # select by label in the same namespace
        labels:
          istio: ingressgateway
      configPatches:
        # The Envoy config you want to modify
        - applyTo: HTTP_FILTER
          match:
            context: GATEWAY
            listener:
              filterChain:
                filter:
                  name: "envoy.filters.network.http_connection_manager"
                  subFilter:
                    name: "envoy.filters.http.router"
          patch:
            operation: INSERT_BEFORE
            # Adds the Envoy Rate Limit Filter in HTTP filter chain.
            value:
              name: envoy.filters.http.ratelimit
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
                # domain can be anything! Match it to the ratelimter service config
                domain: ratelimit
                failure_mode_deny: true
                timeout: 10s
                rate_limit_service:
                  grpc_service:
                    envoy_grpc:
                      cluster_name: outbound|8081||ratelimit.default.svc.cluster.local
                      authority: ratelimit.default.svc.cluster.local
                  transport_api_version: V3
    EOF
    {{< /text >}}

1. Aplique otro `EnvoyFilter` al `ingressgateway` que defina la configuración de ruta en la que se aplicará el límite de tasa.
    Esto agrega [acciones de límite de tasa](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit)
    para cualquier ruta de un virtual host llamado `bookinfo.com:80`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: VIRTUAL_HOST
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: ""
                route:
                  action: ANY
          patch:
            operation: MERGE
            # Applies the rate limit rules.
            value:
              rate_limits:
                - actions: # any actions in here
                  - request_headers:
                      header_name: ":path"
                      descriptor_key: "PATH"
    EOF
    {{< /text >}}

### Caso avanzado de límite de tasa global

Este ejemplo utiliza regex para coincidir con `/api/*` `uri` y define una acción de límite de tasa insertada a nivel de ruta
utilizando el nombre http de VirtualService. El valor PATH `api` insertado en el ejemplo anterior entra en juego.

1. Cambie VirtualService para que el prefijo `/api/v1/products` se mueva a una ruta llamada `api`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      gateways:
      - bookinfo-gateway
      hosts:
      - '*'
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            prefix: /static
        - uri:
            exact: /login
        - uri:
            exact: /logout
        route:
        - destination:
            host: productpage
            port:
              number: 9080
      - match:
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            port:
              number: 9080
        name: api
    EOF
    {{< /text >}}

1. Aplique un EnvoyFilter para agregar la acción de límites de tasa a nivel de ruta en cualquier producto del 1 al 99:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc-api
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: HTTP_ROUTE
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: "*:8080"
                route:
                  name: "api"
          patch:
            operation: MERGE
            value:
              route:
                rate_limits:
                - actions:
                  - header_value_match:
                      descriptor_key: "PATH"
                      descriptor_value: "api"
                      headers:
                        - name: ":path"
                          safe_regex_match:
                            google_re2: {}
                            regex: "/api/v1/products/[1-9]{1,2}"
    EOF
    {{< /text >}}

## Límite de tasa local

Envoy admite la [limitación de tasa local](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit) de conexiones L4 y solicitudes HTTP.
Esto le permite aplicar límites de tasa a nivel de instancia, en el propio proxy, sin llamar a ningún otro service.

El siguiente `EnvoyFilter` habilita la limitación de tasa local para cualquier tráfico a través del service `productpage`.
El parche `HTTP_FILTER` inserta el filtro
[local de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit)
`envoy.filters.http.local_ratelimit` en la cadena de filtros del administrador de conexiones HTTP. El
[cubo de tokens](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket) del filtro de límite de tasa local
está configurado para permitir 4 solicitudes/min. El filtro también está configurado para agregar una cabecera de respuesta `x-local-rate-limit`
a las solicitudes que se bloquean.

{{< tip >}}
Las estadísticas mencionadas en la [página de limitación de tasa de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#statistics) están deshabilitadas por defecto. Puede habilitarlas con las siguientes anotaciones durante el despliegue:

{{< text yaml >}}
template:
  metadata:
    annotations:
      proxy.istio.io/config: |-
        proxyStatsMatcher:
          inclusionRegexps:
          - ".*http_local_rate_limit.*"

{{< /text >}}

{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
              token_bucket:
                max_tokens: 4
                tokens_per_fill: 4
                fill_interval: 60s
              filter_enabled:
                runtime_key: local_rate_limit_enabled
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              filter_enforced:
                runtime_key: local_rate_limit_enforced
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              response_headers_to_add:
                - append: false
                  header:
                    key: x-local-rate-limit
                    value: 'true'
    EOF
{{< /text >}}

La configuración anterior aplica la limitación de tasa local a todos los vhosts/rutas. Alternativamente, puede restringirla a una ruta específica.

El siguiente `EnvoyFilter` habilita la limitación de tasa local para cualquier tráfico al puerto 9080 del service `productpage`.
A diferencia de la configuración anterior, no hay `token_bucket` incluido en el parche `HTTP_FILTER`.
El `token_bucket` se define en el segundo parche (`HTTP_ROUTE`) que incluye un `typed_per_filter_config` para el
filtro local de Envoy `envoy.filters.http.local_ratelimit`, para rutas al virtual host `inbound|http|9080`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
    - applyTo: HTTP_ROUTE
      match:
        context: SIDECAR_INBOUND
        routeConfiguration:
          vhost:
            name: "inbound|http|9080"
            route:
              action: ANY
      patch:
        operation: MERGE
        value:
          typed_per_filter_config:
            envoy.filters.http.local_ratelimit:
              "@type": type.googleapis.com/udpa.type.v1.TypedStruct
              type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
              value:
                stat_prefix: http_local_rate_limiter
                token_bucket:
                  max_tokens: 4
                  tokens_per_fill: 4
                  fill_interval: 60s
                filter_enabled:
                  runtime_key: local_rate_limit_enabled
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                filter_enforced:
                  runtime_key: local_rate_limit_enforced
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                response_headers_to_add:
                  - append: false
                    header:
                      key: x-local-rate-limit
                      value: 'true'
    EOF
{{< /text >}}

## Verificar los resultados

### Verificar el límite de tasa global

Envíe tráfico a la muestra de Bookinfo. Visite `http://$GATEWAY_URL/productpage` en su navegador web o emita el siguiente comando:

{{< text bash >}}
$ for i in {1..2}; do curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{\http_code}\n"; sleep 3; done
200
429
{{< /text >}}

{{< text bash >}}
$ for i in {1..3}; do curl -s "http://$GATEWAY_URL/api/v1/products/${i}" -o /dev/null -w "%{\http_code}\n"; sleep 3; done
200
200
429
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` es el valor establecido en el ejemplo de [Bookinfo](/es/docs/examples/bookinfo/).
{{< /tip >}}

Para `/productpage`, verá que la primera solicitud pasa, pero cada solicitud siguiente dentro
de un minuto obtendrá una respuesta 429. Y para `/api/v1/products/*` deberá realizar dos solicitudes,
con cualquier número entre 1 y 99, hasta que obtenga la respuesta 429 dentro de un minuto.

### Verificar el límite de tasa local

Aunque el límite de tasa global en el ingress gateway limita las solicitudes al service `productpage` a 1 solicitud/min,
el límite de tasa local para las instancias de `productpage` permite 4 solicitudes/min.
Para confirmar esto, envíe solicitudes internas de `productpage`, desde el pod `ratings`, usando el siguiente comando `curl`:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- bash -c 'for i in {1..5}; do curl -s productpage:9080/productpage -o /dev/null -w "%{\http_code}\n"; sleep 1; done'

200
200
200
200
429
{{< /text >}}

No debería ver más de 4 solicitudes/min por instancia de `productpage`.

## Limpieza

{{< text bash >}}
$ kubectl delete envoyfilter filter-ratelimit -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc-api -nistio-system
$ kubectl delete envoyfilter filter-local-ratelimit-svc -nistio-system
$ kubectl delete cm ratelimit-config
$ kubectl delete -f @samples/ratelimit/rate-limit-service.yaml@
{{< /text >}}
