---
title: Проблеми з спостереженням
description: Вирішення проблем зі збором телеметрії.
force_inline_toc: true
weight: 30
aliases:
    - /uk/docs/ops/troubleshooting/grafana
    - /uk/docs/ops/troubleshooting/missing-traces
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## В Zipkin не зʼявляються трейси при запуску Istio локально на Mac {#no-traces-appearing-in-zipkin-when-running-istio-locally-on-mac}

Istio встановлено, і все здається працює, але в Zipkin не зʼявляються трейси, хоча повинні бути.

Це може бути викликано відомою [проблемою Docker](https://github.com/docker/for-mac/issues/1260), коли час всередині контейнерів може суттєво відрізнятися від часу на хост-машині. Якщо це так, коли ви вибираєте дуже довгий інтервал дат у Zipkin, ви побачите, що трейси зʼявляються на кілька днів раніше.

Ви також можете підтвердити цю проблему, порівнявши дату всередині Docker-контейнера з датою за його межами:

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

Щоб розвʼязати цю проблему, вам потрібно вимкнути та перезапустити Docker перед повторним встановленням Istio.

## Відсутній вивід Grafana {#missing-grafana-output}

Якщо ви не можете отримати вивід Grafana при підключенні з локального вебклієнта до віддалено розгорнутого Istio, слід перевірити, чи збігаються дати та час клієнта та сервера.

Час вебклієнта (наприклад, Chrome) впливає на вивід Grafana. Просте розвʼязання цієї проблеми — перевірити, чи працює сервіс синхронізації часу коректно в кластері Kubernetes та чи використовує машина вебклієнта також коректну службу синхронізації часу. Деякі поширені системи синхронізації часу — це NTP та Chrony. Це особливо проблематично в інженерних лабораторіях з брандмауерами. У таких випадках NTP може бути некоректно налаштований для роботи з лабораторними сервісами NTP.

## Перевірте, чи працюють podʼи Istio CNI (якщо використовуються) {#verify-istio-cni-pods-are-running-if-used}

Втулок Istio CNI виконує перенаправлення трафіку podʼів Istio mesh у фазі налаштування мережі життєвого циклу podʼа Kubernetes, таким чином усуваючи [необхідність для можливостей `NET_ADMIN` та `NET_RAW`](/docs/ops/deployment/application-requirements/) для користувачів, які розгортають podʼи в Istio mesh. Втулок Istio CNI замінює функціональність, що надається контейнером `istio-init`.

1. Перевірте, що podʼи `istio-cni-node` працюють:

    {{< text bash >}}
    $ kubectl -n kube-system get pod -l k8s-app=istio-cni-node
    {{< /text >}}

2. Якщо в вашому кластері застосовується `PodSecurityPolicy`, переконайтеся, що службовий обліковий запис `istio-cni` може використовувати `PodSecurityPolicy`, яка [дозволяє можливості `NET_ADMIN` та `NET_RAW`](/docs/ops/deployment/application-requirements/).
