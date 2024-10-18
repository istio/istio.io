---
title: Аварійне перемикання локацій
description: Це завдання демонструє, як налаштувати вашу мережу для аварійного перемикання локацій.
weight: 10
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---
Дотримуйтесь цього посібника, щоб налаштувати вашу мережу для аварійного перемикання локацій.

Перед тим як продовжити, обовʼязково завершите кроки з розділу [перш ніж розпочати](/docs/tasks/traffic-management/locality-load-balancing/before-you-begin).

У цьому завданні ви будете використовувати pod `Sleep` у `region1.zone1` як джерело запитів до сервісу `HelloWorld`. Потім ви ініціюєте відмови, які спричинять аварійне перемикання між локаціями в наступній послідовності:

{{< image width="75%"
    link="sequence.svg"
    caption="Послідовність аварійного перемикання локацій"
    >}}

Для керування аварійним перемиканням використовуються [пріоритети Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/priority.html). Ці пріоритети будуть призначені наступним чином для трафіку, що походить від podʼа `Sleep` (у `region1` `zone1`):

Пріоритет | Локація | Деталі
-------- | -------- | -------
0 | `region1.zone1` | Регіон, зона та підзона збігаються.
1 | Немає | Оскільки це завдання не використовує підзони, для іншої підзони немає збігів.
2 | `region1.zone2` | Інша зона в тому ж регіоні.
3 | `region2.zone3` | Немає збігів, проте аварійне перемикання визначене для `region1`->`region2`.
4 | `region3.zone4` | Немає збігів і аварійне перемикання не визначене для `region1`->`region3`.

## Налаштування аварійного перемикання локацій {#configure-locality-failover}

Застосуйте `DestinationRule`, яке налаштовує наступне:

- [Виявлення аномалій](/docs/reference/config/networking/destination-rule/#OutlierDetection) для сервісу `HelloWorld`. Це необхідно для коректного функціонування аварійного перемикання. Зокрема, воно налаштовує sidecar проксі, щоб знати, коли точки доступу для сервісу є ненадійними, що в кінцевому підсумку спричиняє аварійне перемикання на наступну локацію.

- [Політика аварійного перемикання](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting-Failover) між регіонами. Забезпечує те, що аварійне перемикання за межі регіону буде діяти передбачувано.

- [Політика пулу зʼєднань](/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-http), яка змушує кожен HTTP-запит використовувати нове зʼєднання. Це завдання використовує функцію [drain](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining) Envoy для примусового перемикання на наступну локацію. Після спорожнення Envoy буде відхиляти нові запити на зʼєднання. Оскільки кожен запит використовує нове зʼєднання, це призводить до аварійного перемикання відразу після спорожнення. **Ця конфігурація використовується лише для демонстраційних цілей.**

{{< text bash >}}
$ kubectl --context="${CTX_PRIMARY}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        maxRequestsPerConnection: 1
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failover:
          - from: region1
            to: region2
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## Перевірте, що трафік залишається в `region1.zone1` {#verify-traffic-stays-in-region1.zone1}

Зробіть запит до сервісу `HelloWorld` з podʼа `Sleep`:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region1.zone1, instance: helloworld-region1.zone1-86f77cd7b-cpxhv
{{< /text >}}

Перевірте, що `version` у відповіді дорівнює `region1.zone1`.

Повторіть це кілька разів і переконайтеся, що відповідь завжди однакова.

## Перемикання на `region1.zone2` {#failover-to-region1.zone2}

Наступним кроком є ініціювання аварійного перемикання на `region1.zone2`. Для цього [спорожніть sidecar проксі Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining#draining) для `HelloWorld` у `region1.zone1`:

{{< text bash >}}
$ kubectl --context="${CTX_R1_Z1}" exec \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l app=helloworld \
  -l version=region1.zone1 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

Зробіть запит до сервісу `HelloWorld` з podʼа `Sleep`:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region1.zone2, instance: helloworld-region1.zone2-86f77cd7b-cpxhv
{{< /text >}}

Перший запит зазнає невдачі, що ініціює аварійне перемикання. Повторіть команду кілька разів і перевірте, що `version` у відповіді завжди дорівнює `region1.zone2`.

## Перемикання на `region2.zone3` {#failover-to-region2.zone3}

Тепер запустіть аварійне перемикання на `region2.zone3`. Як і раніше, налаштуйте `HelloWorld` в `region1.zone2` на відмову при виклику:

{{< text bash >}}
$ kubectl --context="${CTX_R1_Z2}" exec \
  "$(kubectl get pod --context="${CTX_R1_Z2}" -n sample -l app=helloworld \
  -l version=region1.zone2 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

Зробіть запит до сервісу `HelloWorld` з podʼа `Sleep`:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region2.zone3, instance: helloworld-region2.zone3-86f77cd7b-cpxhv
{{< /text >}}

Перший виклик буде невдалим, що призведе до аварійного перемикання. Повторіть команду ще кілька разів і переконайтеся, що `version` у відповіді завжди дорівнює `region2.zone3`.

## Перемикання на `region3.zone4` {#failover-to-region3.zone4}

Тепер запустіть аварійне перемикання на `region3.zone4`. Як і раніше, налаштуйте `HelloWorld` в `region2.zone3` на відмову при виклику:

{{< text bash >}}
$ kubectl --context="${CTX_R2_Z3}" exec \
  "$(kubectl get pod --context="${CTX_R2_Z3}" -n sample -l app=helloworld \
  -l version=region2.zone3 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

Зробіть запит до сервісу `HelloWorld` з podʼа `Sleep`:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region3.zone4, instance: helloworld-region3.zone4-86f77cd7b-cpxhv
{{< /text >}}

Перший виклик буде невдалим, що призведе до аварійного перемикання. Повторіть команду ще кілька разів і переконайтеся, що `version` у відповіді завжди дорівнює `region3.zone4`.

**Вітаємо!** Ви успішно налаштували аварійне перемикання локацій!

## Наступні кроки {#next-steps}

[Очистіть](/docs/tasks/traffic-management/locality-load-balancing/cleanup) ресурси та файли з цього завдання.
