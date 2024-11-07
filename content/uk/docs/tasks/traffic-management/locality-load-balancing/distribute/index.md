---
title: Розподіл за коефіцієнтами локацій
description: Цей посібник демонструє, як налаштувати розподіл локацій за коефіціентами.
weight: 20
keywords: [locality,load balancing,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---
Дотримуйтесь настанов цього посібника, щоб налаштувати розподіл трафіку між локаціями.

Перед тим як продовжити, обовʼязково виконайте кроки, описані в розділі
[перш ніж розпочати](/docs/tasks/traffic-management/locality-load-balancing/before-you-begin).

У цьому завданні ви використаєте pod `curl` у `region1` `zone1` як джерело
запитів до сервісу `HelloWorld`. Ви налаштуєте Istio з наступним
розподілом між локаціями:

Регіон | Зона | % трафіку
------ | ---- | ------------
`region1` | `zone1` | 70
`region1` | `zone2` | 20
`region2` | `zone3` | 0
`region3` | `zone4` | 10

## Налаштування розподілу за коефіцієнтами {#configure-weighted-distribution}

Застосуйте `DestinationRule`, яке налаштовує наступне:

- [Виявлення аномалій](/docs/reference/config/networking/destination-rule/#OutlierDetection) для сервісу `HelloWorld`. Це необхідно для правильного функціонування розподілу. Зокрема, це налаштовує sidecar проксі, щоб вони знали, коли точки доступу сервісу є несправними.

- [Розподіл за коефіцієнтами](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/locality_weight.html?highlight=weight) для сервісу `HelloWorld`, як описано в таблиці вище.

{{< text bash >}}
$ kubectl --context="${CTX_PRIMARY}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      localityLbSetting:
        enabled: true
        distribute:
        - from: region1/zone1/*
          to:
            "region1/zone1/*": 70
            "region1/zone2/*": 20
            "region3/zone4/*": 10
    outlierDetection:
      consecutive5xxErrors: 100
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## Перевірка розподілу {#verify-the-distribution}

Викличте сервіс `HelloWorld` з pod `curl`:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c curl \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=curl -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
{{< /text >}}

Повторюйте це кілька разів і перевірте, що кількість відповідей для кожного pod відповідає очікуваному відсотку в таблиці на початку цього посібника.

**Вітаємо!** Ви успішно налаштували розподіл за локаціями!

## Наступні кроки {#next-steps}

[Очистіть](/docs/tasks/traffic-management/locality-load-balancing/cleanup) ресурси та файли з цього завдання.
