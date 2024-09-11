---
title: Jaeger
description: Як інтегруватися з Jaeger.
weight: 28
keywords: [integration,jaeger,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate telemetry-tracing-tips >}}

[Jaeger](https://www.jaegertracing.io/) — це система розподіленого трасування з відкритим вихідним кодом, що дозволяє користувачам моніторити та налагоджувати транзакції в складних розподілених системах.

## Встановлення {#installation}

### Варіант 1: Швидкий старт {#option-1-quick-start}

Istio надає базове зразкове встановлення для швидкого запуску Jaeger:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

Це розгорне Jaeger у вашому кластері. Це призначено лише для демонстрації nf не оптимізовано для продуктивності або безпеки.

### Варіант 2: Налаштоване встановлення {#option-2-customizable-install}

Ознайомтеся з [документацією Jaeger](https://www.jaegertracing.io/), щоб почати. Ніякі спеціальні зміни не потрібні для роботи Jaeger з Istio.

Після встановлення Jaeger, вам потрібно налаштувати проксі Istio для надсилання трейсів до розгортання. Це можна налаштувати за допомогою `--set meshConfig.defaultConfig.tracing.zipkin.address=<jaeger-collector-address>:9411` під час встановлення. Дивіться [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) для розширеної конфігурації, такої як налаштування TLS.

## Використання {#usage}

Для отримання додаткової інформації про використання Jaeger, будь ласка, ознайомтеся з [завданням Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/).
