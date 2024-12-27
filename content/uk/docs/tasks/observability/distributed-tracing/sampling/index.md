---
title: Налаштування вибірки трейсів
description: Досліджуйте різні підходи до налаштування вибірки трейсів на проксі.
weight: 4
keywords: [sampling, telemetry, tracing, opentelemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio надає кілька способів налаштування вибірки трейсів. На цій сторінці ви дізнаєтеся і зрозумієте всі різні способи налаштування вибірки.

## Перед початком {#before-you-begin}

1. Переконайтеся, що ваші застосунки передають заголовки трейсингу, як описано [тут](/docs/tasks/observability/distributed-tracing/overview/).

## Доступні конфігурації вибірки трейсів {#available-trace-sampling-configurations}

1. Вибірка за відсотком: випадкова швидкість вибірки для відсотка запитів, які будуть вибрані для генерації трейсів.

1. Власний OpenTelemetry Sampler: реалізація власного семплера, яка повинна бути поєднана з `OpenTelemetryTracingProvider`.

### Вибірка за відсотком {#percentage-sampler}

{{< boilerplate telemetry-tracing-tips >}}

Випадкова швидкість вибірки за відсотком використовує зазначене значення відсотка для вибору запитів для вибірки.

Швидкість вибірки повинна бути в діапазоні від 0.0 до 100.0 з точністю 0.01. Наприклад, щоб трейсити 5 запитів з кожних 10000, використовуйте значення 0.05.

Є три способи налаштування випадкової швидкості вибірки:

#### Telemetry API {#telemetry-api}

Вибірку можна налаштувати для різних масштабів: для всієї mesh-мережі, для простору імен або для конкретного навантаження, що забезпечує велику гнучкість. Щоб дізнатися більше, будь ласка, ознайомтеся з документацією [Telemetry API](/docs/tasks/observability/telemetry/).

Встановіть Istio без налаштування `sampling` всередині `defaultConfig`:

{{< text syntax=bash snip_id=install_without_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Увімкніть провайдера трейсингу через Telemetry API та задайте `randomSamplingPercentage`.

{{< text syntax=bash snip_id=enable_telemetry_with_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
   name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 10
EOF
{{< /text >}}

#### Використання `MeshConfig` {#using-meshconfig}

Випадкова вибірка за відсотком може бути налаштована глобально через `MeshConfig`.

{{< text syntax=bash snip_id=install_default_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Потім увімкніть провайдера трейсингу через Telemetry API. Зверніть увагу, що ми не задаємо `randomSamplingPercentage` тут.

{{< text syntax=bash snip_id=enable_telemetry_no_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
EOF
{{< /text >}}

#### Використання анотації `proxy.istio.io/config` {#using-the-proxyistioioconfig-annotation}

Ви можете додати анотацію `proxy.istio.io/config` до метаданих вашого Pod, щоб перевизначити будь-які налаштування вибірки на рівні мережі.

Наприклад, щоб перевизначити вибірку на рівні мережі вище, ви додасте наступне до вашого manifest файлу pod:

{{< text syntax=yaml snip_id=none >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          tracing:
            sampling: 20
    spec:
      ...
{{< /text >}}

### Власний OpenTelemetry Sampler {#custom-opentelemetry-sampler}

Специфікація OpenTelemetry визначає [Sampler API](https://opentelemetry.io/docs/specs/otel/trace/sdk/#sampler). Sampler API дозволяє створювати власний семплер, який може здійснювати більш інтелектуальні та ефективні рішення для вибірки, такі як [Probability Sampling](https://opentelemetry.io/docs/specs/otel/trace/tracestate-probability-sampling-experimental/).

Такі семплери потім можна поєднати з [`OpenTelemetryTracingProvider`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider).

{{< quote >}}
Реалізація семплера розташована в проксі і її можна знайти в [Envoy OpenTelemetry Samplers](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers).
{{< /quote >}}

Поточні конфігурації семплера в Istio:

- [Dynatrace Sampler](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)

Власні семплери налаштовуються через `MeshConfig`. Ось приклад конфігурації семплера Dynatrace:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 443
        service: abc.live.dynatrace.com/api/v2/otlp
        http:
          path: "/api/v2/otlp/v1/traces"
          timeout: 10s
          headers:
            - name: "Authorization"
              value: "Api-Token dt0c01."
        dynatrace_sampler:
          tenant: "abc"
          cluster_id: 123
{{< /text >}}

### Порядок пріоритету {#order-of-precedence}

З кількома способами налаштування вибірки важливо розуміти порядок пріоритету кожного методу.

При використанні випадкової вибірки за відсотком порядок пріоритету є:

<table><tr><td>Telemetry API > Анотація Pod > <code>MeshConfig</code> </td></tr></table>

Це означає, що якщо значення визначено в усіх з зазначених, вибирається значення з Telemetry API.

Коли налаштований власний OpenTelemetry семплер, порядок пріоритету є:

<table><tr><td>Custom OTel Sampler > (Telemetry API | Анотація Pod | <code>MeshConfig</code>)</td></tr></table>

Це означає, що якщо налаштований власний OpenTelemetry семплер, він перевизначить усі інші методи. Крім того, значення випадкової вибірки встановлено на `100` і не може бути змінене. Це важливо, оскільки власний семплер має отримувати 100% відрізків для правильного прийняття рішень.

## Розгортання OpenTelemetry Collector {#deploy-the-opentelemetry-collector}

{{< boilerplate start-otel-collector-service >}}

## Розгортання Bookinfo {#deploy-the-bookinfo-application}

Розгорніть [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) як демонстраційний застосунок.

## Генерація трейсів за допомогою Bookinfo {#generating-traces-using-the-bookinfo-sample}

1. Коли Bookinfo запущено і працює, відвідайте `http://$GATEWAY_URL/productpage` один або кілька разів, щоб згенерувати інформацію про трейси.

    {{< boilerplate trace-generation >}}

## Очищення {#cleanup}

1. Видаліть ресурс Telemetry:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1. Видаліть будь-які процеси `istioctl`, які можуть ще працювати, використовуючи control-C або:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

1. Видаліть OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}
