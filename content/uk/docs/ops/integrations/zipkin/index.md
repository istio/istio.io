---
title: Zipkin
description: Як інтегрувати з Zipkin.
weight: 32
keywords: [integration,zipkin,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate telemetry-tracing-tips >}}

[Zipkin](https://zipkin.io/) — це система розподіленого трасування, яка допомагає збирати дані про час виконання для вирішення проблем із затримкою в архітектурах сервісів. Вона підтримує як збір даних, так і їх пошук.

## Встановлення {#installation}

### Опція 1: Швидкий старт {#option-1-quick-start}

Istio надає базову демонстраційну установку для швидкого запуску Zipkin:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/extras/zipkin.yaml
{{< /text >}}

Це розгорне Zipkin у вашому кластері. Це призначено лише для демонстраційних цілей і не налаштоване для продуктивності чи безпеки.

### Опція 2: Налаштовуване встановлення {#option-2-customizable-install}

Ознайомтесь з [документацією Zipkin](https://zipkin.io/), щоб почати. Спеціальних змін для роботи Zipkin з Istio не потрібно.

Після встановлення Zipkin, необхідно налаштувати проксі-сервери Istio для надсилання трейсів до цього розгортання. Це можна налаштувати за допомогою параметра `--set meshConfig.defaultConfig.tracing.zipkin.address=<zipkin-collector-address>:9411` під час встановлення. Дивіться [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) для розширеної конфігурації, такої як налаштування TLS.

## Використання {#usage}

Для отримання додаткової інформації про використання Zipkin, будь ласка, ознайомтеся з [завданням Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/).
