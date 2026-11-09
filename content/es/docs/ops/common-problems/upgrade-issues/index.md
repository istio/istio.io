---
title: Problemas de actualización
description: Resuelve problemas comunes con las actualizaciones de Istio.
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## Migración de EnvoyFilter {#envoyfilter-migration}

`EnvoyFilter` es una API alfa estrechamente acoplada a los detalles de
implementación de la generación de configuración xDS de Istio. El uso en producción de la
API alfa `EnvoyFilter` debe gestionarse con cuidado durante la actualización del control plane
o del data plane de Istio. En muchos casos, `EnvoyFilter` se puede reemplazar por una
API de Istio de primera clase que conlleva riesgos de actualización considerablemente menores.

### Usa la API de Telemetría para personalizar las métricas {#use-telemetry-api-for-metrics-customization}

El uso de `IstioOperator` para personalizar la generación de métricas de Prometheus se ha
reemplazado por la [API de Telemetría](/es/docs/tasks/observability/metrics/customize-metrics/),
porque `IstioOperator` depende de un `EnvoyFilter` de plantilla para cambiar la
configuración del filtro de métricas. Ten en cuenta que ambos métodos son incompatibles y
que la API de Telemetría no funciona con `EnvoyFilter` ni con `IstioOperator` como configuración de
personalización de métricas.

Por ejemplo, la siguiente configuración de `IstioOperator` agrega una dimensión `destination_port`:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              metrics:
                - name: requests_total
                  dimensions:
                    destination_port: string(destination.port)
{{< /text >}}

La siguiente configuración de `Telemetry` reemplaza la anterior:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      mode: SERVER
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
{{< /text >}}

### Usa la API TrafficExtension para la extensibilidad del data plane con Wasm {#use-the-trafficextension-api-for-wasm-data-plane-extensibility}

El uso de `EnvoyFilter` para inyectar filtros Wasm se ha reemplazado por la
[API TrafficExtension](/es/docs/tasks/extensibility/wasm-modules).
La API `TrafficExtension` permite cargar dinámicamente los plugins desde registros de artefactos,
URLs o archivos locales. El runtime de plugins "Null" ya no es una opción recomendada
para desplegar código Wasm.

### Usa la topología del gateway para establecer el número de saltos de confianza {#use-gateway-topology-to-set-the-number-of-the-trusted-hops}

El uso de `EnvoyFilter` para configurar el número de saltos de confianza en el
HTTP connection manager se ha reemplazado por el campo
[`gatewayTopology`](/es/docs/reference/config/istio.mesh.v1alpha1/#Topology)
de
[`ProxyConfig`](/es/docs/ops/configuration/traffic-management/network-topologies).
Por ejemplo, la siguiente configuración de `EnvoyFilter` debería sustituirse por una anotación
en el pod o por el valor predeterminado de la mesh. En lugar de:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingressgateway-redirect-config
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
    patch:
      operation: MERGE
      value:
        typed_config:
          '@type': type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          xff_num_trusted_hops: 1
  workloadSelector:
    labels:
      istio: ingress-gateway
{{< /text >}}

Usa la anotación equivalente de configuración del proxy en el pod del ingress gateway:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 1 }}'
{{< /text >}}

### Usa la topología del gateway para habilitar el protocolo PROXY en los ingress gateways {#use-gateway-topology-to-enable-proxy-protocol-on-the-ingress-gateways}

El uso de `EnvoyFilter` para habilitar el [protocolo
PROXY](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) en los
ingress gateways se ha reemplazado por el campo
[`gatewayTopology`](/es/docs/reference/config/istio.mesh.v1alpha1/#Topology)
de
[`ProxyConfig`](/es/docs/ops/configuration/traffic-management/network-topologies).
Por ejemplo, la siguiente configuración de `EnvoyFilter` debería sustituirse por una anotación
en el pod o por el valor predeterminado de la mesh. En lugar de:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
spec:
  configPatches:
  - applyTo: LISTENER_FILTER
    patch:
      operation: INSERT_FIRST
      value:
        name: proxy_protocol
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
  workloadSelector:
    labels:
      istio: ingress-gateway
{{< /text >}}

Usa la anotación equivalente de configuración del proxy en el pod del ingress gateway:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

### Usa una anotación de proxy para personalizar el tamaño de los buckets del histograma {#use-a-proxy-annotation-to-customize-the-histogram-bucket-sizes}

El uso de `EnvoyFilter` y del servicio experimental de descubrimiento de bootstrap para
configurar el tamaño de los buckets de las métricas de histograma se ha reemplazado por la
anotación de proxy `sidecar.istio.io/statsHistogramBuckets`. Por ejemplo, la
siguiente configuración de `EnvoyFilter` debería sustituirse por una anotación en el pod.
En lugar de:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: envoy-stats-1
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: BOOTSTRAP
    patch:
      operation: MERGE
      value:
        stats_config:
          histogram_bucket_settings:
            - match:
                prefix: istiocustom
              buckets: [1,5,50,500,5000,10000]
{{< /text >}}

Usa la anotación equivalente en el pod:

{{< text yaml >}}
metadata:
  annotations:
    "sidecar.istio.io/statsHistogramBuckets": '{"istiocustom":[1,5,50,500,5000,10000]}'
{{< /text >}}
