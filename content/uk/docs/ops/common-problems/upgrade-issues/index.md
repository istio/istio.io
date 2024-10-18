---
title: Проблеми з оновленням
description: Вирішення поширених проблем з оновленнями Istio.
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## Міграція EnvoyFilter {#envoyfilter-migration}

`EnvoyFilter` — це альфа API, яка тісно повʼязана з деталями реалізації генерації конфігурації xDS в Istio. Використання альфа API `EnvoyFilter` в промислових системах має бути ретельно продуманим під час оновлення панелі управління або панелі даних Istio. У багатьох випадках `EnvoyFilter` можна замінити на API Istio, що несе значно менші ризики оновлення.

### Використання Telemetry API для налаштування метрик {#use-telemetry-api-for-metrics-customization}

Використання `IstioOperator` для налаштування генерації метрик Prometheus було замінено на [Telemetry API](/docs/tasks/observability/metrics/customize-metrics/), оскільки `IstioOperator` спирається на шаблон `EnvoyFilter` для зміни конфігурації фільтра метрик. Зверніть увагу, що ці два методи несумісні, і Telemetry API не працює з `EnvoyFilter` або конфігурацією налаштування метрик `IstioOperator`.

Наприклад, наступна конфігурація `IstioOperator` додає теґ `destination_port`:

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

Наступна конфігурація `Telemetry` замінює наведену вище:

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

### Використання WasmPlugin API для розширення можливостей Wasm панелі даних {#use-wasmplugin-api-for-wasm-data-plane-extensibility}

Використання `EnvoyFilter` для додавання фільтрів Wasm було замінено на [WasmPlugin API](/docs/tasks/extensibility/wasm-module-distribution). WasmPlugin API дозволяє динамічне завантаження втулків з реєстрів артефактів, URL-адрес або локальних файлів. Виконавчий файл втулка "Null" більше не є рекомендованим варіантом для розгортання коду Wasm.

### Використання топології шлюза для встановлення кількості довірених хопів {#use-gateway-topology-to-set-the-number-of-the-trusted-hops}

Використання `EnvoyFilter` для конфігурації кількості довірених хопів в HTTP-менеджері зʼєднань було замінено на поле [`gatewayTopology`](/docs/reference/config/istio.mesh.v1alpha1/#Topology) в [`ProxyConfig`](/docs/ops/configuration/traffic-management/network-topologies). Наприклад, наступна конфігурація `EnvoyFilter` повинна використовувати анотацію на podʼі або стандартне значення для мережі. Замість:

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

Використовуйте еквівалентну анотацію конфігурації проксі podʼа для шлюза:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 1 }}'
{{< /text >}}

### Використання топології шлюза для увімкнення PROXY протоколу на шлюзах вхідного трафіку {#use-gateway-topology-to-enable-proxy-protocol-on-the-ingress-gateways}

Використання `EnvoyFilter` для увімкнення [PROXY протоколу](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) на шлюзах вхідного трафіку було замінено на поле [`gatewayTopology`](/docs/reference/config/istio.mesh.v1alpha1/#Topology) в [`ProxyConfig`](/docs/ops/configuration/traffic-management/network-topologies). Наприклад, наступна конфігурація `EnvoyFilter` повинна використовувати анотацію на podʼі або стандартне значення для мережі. Замість:

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

Використовуйте еквівалентну анотацію конфігурації проксі podʼа для шлюза:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

### Використання анотації проксі для налаштування розмірів кошиків гістограми {#use-a-proxy-annotation-to-customize-the-histogram-bucket-sizes}

Використання `EnvoyFilter` та експериментального сервісу виявлення bootstrap для конфігурації розмірів кошиків для метрик гістограми було замінено на анотацію проксі `sidecar.istio.io/statsHistogramBuckets`. Наприклад, наступна конфігурація `EnvoyFilter` повинна використовувати анотацію на podʼі. Замість:

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

Використовуйте еквівалентну анотацію podʼа:

{{< text yaml >}}
metadata:
  annotations:
    "sidecar.istio.io/statsHistogramBuckets": '{"istiocustom":[1,5,50,500,5000,10000]}'
{{< /text >}}
