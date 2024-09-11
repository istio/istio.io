---
title: Спостережуваність
description: Описує функції телеметрії та моніторингу, які надає Istio.
weight: 40
keywords: [telemetry,metrics,logs,tracing]
aliases:
    - /uk/docs/concepts/policy-and-control/mixer.html
    - /uk/docs/concepts/policy-and-control/mixer-config.html
    - /uk/docs/concepts/policy-and-control/attributes.html
    - /uk/docs/concepts/policies-and-telemetry/overview/
    - /uk/docs/concepts/policies-and-telemetry/config/
    - /uk/docs/concepts/policies-and-telemetry/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio генерує детальну телеметрію для всіх комунікацій між сервісами в межах mesh-мережі. Ця телеметрія забезпечує *спостережуваність* за поведінкою сервісів, дозволяючи операторам розвʼязувати проблеми, підтримувати та оптимізувати свої застосунки — без додаткових зусиль з боку розробників сервісів. Завдяки Istio оператори отримують повне розуміння того, як взаємодіють контрольовані сервіси, як з іншими сервісами, так і з компонентами Istio.

Istio генерує наступні типи телеметрії для забезпечення загальної спостережуваності mesh-мережі:

- [**Метрики**](#metrics). Istio генерує набір метрик сервісів на основі чотирьох "золотих сигналів" моніторингу (затримка, трафік, помилки та насиченість). Istio також надає детальні метрики для [панелі управління mesh](/docs/ops/deployment/architecture/). Крім того, на основі цих метрик надається набір стандартних інфопанелей моніторингу mesh.

- [**Розподілені трейси**](#distributed-traces). Istio генерує розподілені трейси для кожного сервісу, що дає операторам детальне розуміння потоків викликів і залежностей сервісів у межах mesh-мережі.

- [**Журнали доступу**](#access-logs). Коли трафік надходить у сервіс у межах mesh-мережі, Istio може генерувати повний запис кожного запиту, включаючи метадані джерела та призначення. Ця інформація дозволяє операторам проводити аудит поведінки сервісу до рівня окремого [екземпляра навантаження](/docs/reference/glossary/#workload-instance).

## Метрики {#metrics}

Метрики надають спосіб моніторингу та розуміння поведінки в сукупності.

Для моніторингу поведінки сервісів Istio генерує метрики для всього трафіку сервісів, що надходить, виходить та проходить всередині mesh-мережі Istio. Ці метрики надають інформацію про такі аспекти, як загальний обсяг трафіку, рівень помилок у трафіку та час відповіді на запити.

Окрім моніторингу поведінки сервісів у межах mesh-мережі, важливо також контролювати стан самої мережі. Компоненти Istio експортують метрики щодо їхньої власної внутрішньої поведінки, щоб забезпечити розуміння стану та функціонування панелі управління mesh-мережі.

### Метрики на рівні проксі {#proxy-level-metrics}

Збір метрик в Istio починається з sidecar проксі (Envoy). Кожен проксі генерує широкий набір метрик про весь трафік, що проходить через нього (як вхідний, так і вихідний). Проксі також надають детальну статистику про адміністративні функції проксі, включаючи інформацію про конфігурацію та стан.

Метрики, згенеровані Envoy, дозволяють моніторити mesh на рівні ресурсів Envoy (таких як слухачі та кластери). Як результат, для моніторингу метрик Envoy потрібно розуміти звʼязок між сервісами mesh та ресурсами Envoy.

Istio дозволяє операторам вибирати, які метрики Envoy генеруються та збираються на кожному екземплярі робочого навантаження. Стандартно Istio активує лише невелику частину статистики, згенерованої Envoy, щоб уникнути перевантаження сховищ метрик та зменшити навантаження на ЦП, повʼязане зі збором метрик. Однак оператори можуть легко розширити набір зібраних метрик проксі за потреби. Це дозволяє цілеспрямовано налагоджувати поведінку мережі, зменшуючи загальні витрати на моніторинг у mesh.

На [сайті документації Envoy](https://www.envoyproxy.io/docs/envoy/latest/) є детальний огляд [збору статистики Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/statistics.html?highlight=statistics). Керівництво з експлуатації [Envoy Statistics](/docs/ops/configuration/telemetry/envoy-stats/) надає більше інформації про контроль генерації метрик на рівні проксі.

Приклад метрик на рівні проксі:

{{< text json >}}
envoy_cluster_internal_upstream_rq{response_code_class="2xx",cluster_name="xds-grpc"} 7163

envoy_cluster_upstream_rq_completed{cluster_name="xds-grpc"} 7164

envoy_cluster_ssl_connection_error{cluster_name="xds-grpc"} 0

envoy_cluster_lb_subsets_removed{cluster_name="xds-grpc"} 0

envoy_cluster_internal_upstream_rq{response_code="503",cluster_name="xds-grpc"} 1
{{< /text >}}

### Метрики на рівні сервісів {#service-level-metrics}

Окрім метрик на рівні проксі, Istio надає набір метрик, орієнтованих на сервіси, для моніторингу комунікацій між сервісами. Ці метрики охоплюють чотири основні потреби моніторингу сервісів: затримку, трафік, помилки та насичення. Istio поставляється з набором [дашбордів](/docs/tasks/observability/metrics/using-istio-dashboard/) для моніторингу поведінки сервісів на основі цих метрик.

[Стандартні метрики Istio](/docs/reference/config/metrics/) типово експортуються до [Prometheus](/docs/ops/integrations/prometheus/).

Використання метрик на рівні сервісів є повністю опціональним. Оператори можуть вирішити вимкнути генерацію та збір цих метрик, щоб задовольнити свої індивідуальні потреби.

Приклад метрики на рівні сервісів:

{{< text json >}}
istio_requests_total{
  connection_security_policy="mutual_tls",
  destination_app="details",
  destination_canonical_service="details",
  destination_canonical_revision="v1",
  destination_principal="cluster.local/ns/default/sa/default",
  destination_service="details.default.svc.cluster.local",
  destination_service_name="details",
  destination_service_namespace="default",
  destination_version="v1",
  destination_workload="details-v1",
  destination_workload_namespace="default",
  reporter="destination",
  request_protocol="http",
  response_code="200",
  response_flags="-",
  source_app="productpage",
  source_canonical_service="productpage",
  source_canonical_revision="v1",
  source_principal="cluster.local/ns/default/sa/default",
  source_version="v1",
  source_workload="productpage-v1",
  source_workload_namespace="default"
} 214
{{< /text >}}

### Метрики панелі управління {#control-plane-metrics}

Панель управління Istio також надає набір метрик самомоніторингу. Ці метрики дозволяють відстежувати поведінку самого Istio, відокремлено від сервісів у mesh.

Для отримання додаткової інформації про підтримувані метрики зверніться до [довідкової документації](/docs/reference/commands/pilot-discovery/#metrics).

## Розподілені трейси {#distributed-traces}

Розподілені трейси надають можливість моніторити та розуміти поведінку, відстежуючи індивідуальні запити, які проходять через mesh. Трейси дозволяють операторам mesh зрозуміти залежності між сервісами та джерела затримок у їхній сервісній мережі.

Istio підтримує розподілені трейси через проксі Envoy. Проксі автоматично генерують відрізки трейсів від імені застосунків, які вони обробляють, що вимагає лише того, щоб застосунки пересилали відповідний контекст запиту.

Istio підтримує кілька бекендів для трейсів, включаючи [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/), [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/), [Lightstep](/docs/tasks/observability/distributed-tracing/lightstep/) та [Datadog](https://www.datadoghq.com/blog/monitor-istio-with-datadog/). Оператори можуть керувати частотою вибірки для генерації трейсів (тобто, швидкістю, з якою генеруються дані трейсів для кожного запиту). Це дозволяє операторам контролювати обсяг і швидкість генерації даних трейсів для їхнього mesh.

Більше інформації про розподілені трейси з Istio можна знайти у наших [Частих питаннях про розподілені трейси](/about/faq/#distributed-tracing).

Приклад розподілених трейсів, згенерованих Istio для одного запиту:

{{< image link="/uk/docs/tasks/observability/distributed-tracing/zipkin/istio-tracing-details-zipkin.png" caption="Розподілені трейси для одного запиту" >}}

## Логи доступу {#access-logs}

Логи доступу надають можливість моніторити та розуміти поведінку з погляду окремого екземпляра робочого навантаження.

Istio може генерувати логи доступу для сервісного трафіку у налаштовуваних форматах, надаючи операторам повний контроль над тим, як, що, коли та де відбувається логування. Для отримання додаткової інформації зверніться до розділу [Отримання логів доступу Envoy](/docs/tasks/observability/logs/access-log/).

Приклад логу доступу Istio:

{{< text plain >}}
[2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
{{< /text >}}
