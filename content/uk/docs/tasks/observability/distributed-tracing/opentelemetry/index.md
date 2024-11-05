---
title: OpenTelemetry
description: Дізнайтеся, як налаштувати проксі для надсилання трейсів OpenTelemetry до Колектора.
weight: 30
keywords: [телеметрія,трейсинг,opentelemetry,спан,порт-форвардинг,telemetry,tracing,opentelemetry,span,port-forwarding]
aliases:
 - /uk/docs/tasks/telemetry/distributed-tracing/opentelemetry/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Після завершення цього завдання ви зможете зрозуміти, як ваш застосунок може брати участь у трейсингу з [OpenTelemetry](https://www.opentelemetry.io/), незалежно від мови, фреймворка або платформи, який ви використовуєте для створення застосунку.

Це завдання використовує [Bookinfo](/docs/examples/bookinfo/) як демонстраційний застосунок та
[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) як приймач трейсів.

Щоб дізнатися, як Istio обробляє трейсинг, відвідайте [огляд цього завдання](../overview/).

## Розгортання OpenTelemetry Collector {#deploy-the-opentelemetry-collector}

{{< boilerplate start-otel-collector-service >}}

## Встановлення {#installation}

Всі параметри трейсингу можна налаштувати глобально через `MeshConfig`. Щоб спростити конфігурацію, рекомендується створити один YAML файл, який можна передати команді `istioctl install -f`.

## Вибір експортеру {#choosing-the-exporter}

Istio можна налаштувати для експорту трейсів [OpenTelemetry Protocol (OTLP)](https://opentelemetry.io/docs/specs/otel/protocol/) через gRPC або HTTP. Можна налаштувати лише один експортер одночасно (або gRPC, або HTTP).

### Експорт через gRPC {#exporting-via-grpc}

У цьому прикладі трейс буде експортуватися через OTLP/gRPC до OpenTelemetry Collector. Приклад також активує [детектор ресурсів середовища](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). Детектор середовища додає атрибути зі змінної середовища `OTEL_RESOURCE_ATTRIBUTES` до експортованого ресурсу OpenTelemetry.

{{< text syntax=bash snip_id=none >}}
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

### Експорт через HTTP {#exporting-via-http}

У цьому прикладі трейс буде експортуватися через OTLP/HTTP до OpenTelemetry Collector. Приклад також активує [детектор ресурсів середовища](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). Детектор середовища додає атрибути зі змінної середовища `OTEL_RESOURCE_ATTRIBUTES` до експортованого ресурсу OpenTelemetry.

{{< text syntax=bash snip_id=install_otlp_http >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4318
        service: opentelemetry-collector.observability.svc.cluster.local
        http:
          path: "/v1/traces"
          timeout: 5s
          headers:
            - name: "custom-header"
              value: "custom value"
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

## Увімкнення трейсингу для mesh через Telemetry API {#enable-tracing-for-mesh-via-telemetry-api}

Увімкніть трейсинг, застосувавши наступну конфігурацію:

{{< text syntax=bash snip_id=enable_telemetry >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 100
    customTags:
      "my-attribute":
        literal:
          value: "default-value"
EOF
{{< /text >}}

## Розгортання Bookinfo {#deploy-the-bookinfo-application}

Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Генерація трейсів за допомогою Bookinfo {#generating-traces-using-the-bookinfo-sample}

1. Коли Bookinfo буде запущено, отримайте доступ до `http://$GATEWAY_URL/productpage` один або кілька разів для генерації інформації про трейс.

    {{< boilerplate trace-generation >}}

1. Використовуйте OpenTelemetry Collector, сконфігурований для експорту трейсів у консоль, щоб перевірити, що трейс надходять, переглянувши логи Колектора. Логи повинні містити щось подібне до:

    {{< text syntax=yaml snip_id=none >}}
    Resource SchemaURL:
    Resource labels:
          -> service.name: STRING(productpage.default)
    ScopeSpans #0
    ScopeSpans SchemaURL:
    InstrumentationScope
    Span #0
        Trace ID       : 79fb7b59c1c3a518750a5d6dad7cd2d1
        Parent ID      : 0cf792b061f0ad51
        ID             : 2dff26f3b4d6d20f
        Name           : egress reviews:9080
        Kind           : SPAN_KIND_CLIENT
        Start time     : 2024-01-30 15:57:58.588041 +0000 UTC
        End time       : 2024-01-30 15:57:59.451116 +0000 UTC
        Status code    : STATUS_CODE_UNSET
        Status message :
    Attributes:
          -> node_id: STRING(sidecar~10.244.0.8~productpage-v1-564d4686f-t6s4m.default~default.svc.cluster.local)
          -> zone: STRING()
          -> guid:x-request-id: STRING(da543297-0dd6-998b-bd29-fdb184134c8c)
          -> http.url: STRING(http://reviews:9080/reviews/0)
          -> http.method: STRING(GET)
          -> downstream_cluster: STRING(-)
          -> user_agent: STRING(curl/7.74.0)
          -> http.protocol: STRING(HTTP/1.1)
          -> peer.address: STRING(10.244.0.8)
          -> request_size: STRING(0)
          -> response_size: STRING(441)
          -> component: STRING(proxy)
          -> upstream_cluster: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> upstream_cluster.name: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> http.status_code: STRING(200)
          -> response_flags: STRING(-)
          -> istio.namespace: STRING(default)
          -> istio.canonical_service: STRING(productpage)
          -> istio.mesh_id: STRING(cluster.local)
          -> istio.canonical_revision: STRING(v1)
          -> istio.cluster_id: STRING(Kubernetes)
          -> my-attribute: STRING(default-value)
    {{< /text >}}

## Очищення {#cleanup}

1. Видаліть ресурс Telemetry:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1. Видаліть будь-які процеси `istioctl`, які можуть все ще працювати, використовуючи control-C або:

    {{< text syntax=bash snip_id=none >}}
    $ killall istioctl
    {{< /text >}}

1. Видаліть OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

1. Якщо ви не плануєте досліджувати жодних подальших завдань, зверніться до інструкцій з [очищення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу з застосунком.
