---
title: Apache SkyWalking
description: Як інтегрувати з Apache SkyWalking.
weight: 32
keywords: [integration,skywalking,tracing]
owner: istio/wg-environments-maintainers
test: no
---

[Apache SkyWalking](http://skywalking.apache.org) є системою моніторингу продуктивності застосунків (APM), спеціально розробленою для мікросервісів, хмарних і контейнерних архітектур. SkyWalking є комплексним рішенням для спостереження, яке не лише надає можливість розподіленого трасування як Jaeger і Zipkin, можливості для метрик як Prometheus і Grafana, логування як Kiali, але також розширює спостереження на багато інших сценаріїв, таких як асоціювання логів з трейсами, збір системних подій та асоціювання подій з метриками, профілювання продуктивності сервісів на основі eBPF тощо.

## Встановлення {#installation}

### Опція 1: Швидкий старт {#option-1-quick-start}

Istio надає базову демонстраційну установку для швидкого запуску SkyWalking:

{{< text bash >}}
$ kubectl apply -f @samples/addons/extras/skywalking.yaml@
{{< /text >}}

Це розгорне SkyWalking у вашому кластері. Це призначено лише для демонстраційних цілей і не налаштоване для продуктивності чи безпеки.

Стандартно проксі-сервери Istio не надсилають трейси до SkyWalking. Вам також потрібно активувати розширення трейсів SkyWalking, додавши наступні поля до вашої конфігурації:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
      - skywalking:
          service: tracing.istio-system.svc.cluster.local
          port: 11800
        name: skywalking
    defaultProviders:
        tracing:
        - "skywalking"
{{< /text >}}

### Опція 2: Налаштовуване встановлення {#option-2-customizable-install}

Ознайомтесь з [документацією SkyWalking](http://skywalking.apache.org), щоб почати. Спеціальних змін для роботи SkyWalking з Istio не потрібно.

Після встановлення SkyWalking, не забудьте змінити опцію `--set meshConfig.extensionProviders[0].skywalking.service` на вказівник на розгортання `skywalking-oap`. Дивіться [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) для розширеної конфігурації, такої як налаштування TLS.

## Використання {#usage}

Для отримання інформації про використання SkyWalking, будь ласка, ознайомтеся з [завданням SkyWalking](/docs/tasks/observability/distributed-tracing/skywalking/).
