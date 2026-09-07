---
title: Налаштування поведінки відмовостійкості в мультикластерній установці ambient
description: Налаштування виявлення викидів і поведінки відмовостійкості в ambient мультикластерній ambient мережі за допомогою waypoint.
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/verify
---
Дотримуйтеся цього посібника, щоб налаштувати поведінку відмовостійкості у вашій ambient мультикластерній установці Istio за допомогою проксі waypoint.

Перед тим як продовжити, обовʼязково виконайте ambient мультикластерну установку Istio за одним із [посібників з мультикластерної установки](/docs/ambient/install/multicluster) та переконайтеся, що установка працює належним чином.

У цьому посібнику ми вдосконалимо застосунок `HelloWorld`, який використовувався для перевірки мультикластерної установки. Ми налаштуємо локальну відмовостійкість для сервісу `HelloWorld`, щоб надавати перевагу точкам доступу в кластері, локальному для клієнта, за допомогою `DestinationRule`, і розгорнемо проксі waypoint для застосування цієї конфігурації.

## Розгортання проксі waypoint {#deploy-waypoint-proxy}

Щоб налаштувати виявлення викидів і налаштувати поведінку відмовостійкості для сервісу, нам потрібен проксі waypoint. Для початку розгорніть проксі waypoint у кожному кластері мережі:

{{< text bash >}}
$ istioctl --context "${CTX_CLUSTER1}" waypoint apply --name waypoint --for service -n sample --wait
$ istioctl --context "${CTX_CLUSTER2}" waypoint apply --name waypoint --for service -n sample --wait
{{< /text >}}

Підтвердьте статус розгортання проксі waypoint на `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           137m
{{< /text >}}

Підтвердьте статус розгортання проксі waypoint на `cluster2`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           138m
{{< /text >}}

Зачекайте, поки всі проксі waypoint будуть готові.

Налаштуйте сервіс `HelloWorld` у кожному кластері на використання проксі waypoint:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
$ kubectl --context "${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
{{< /text >}}

Нарешті, і цей крок є специфічним для мультикластерного розгортання проксі waypoint, позначте сервіс проксі waypoint у кожному кластері як глобальний, так само, як ви раніше зробили з сервісом `HelloWorld`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc waypoint -n sample istio.io/global=true
$ kubectl --context "${CTX_CLUSTER2}" label svc waypoint -n sample istio.io/global=true
{{< /text >}}

Сервіс `HelloWorld` в обох кластерах тепер налаштований на використання проксі waypoint, але проксі waypoint поки що не роблять нічого корисного.

## Налаштування локальної відмовостійкості {#configure-locality-failover}

Щоб налаштувати локальну відмовостійкість, створіть і застосуйте `DestinationRule` у `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

Застосуйте той самий `DestinationRule` також у `cluster2`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

Цей `DestinationRule` налаштовує наступне:

- [Виявлення викидів](/docs/reference/config/networking/destination-rule/#OutlierDetection) для сервісу `HelloWorld`. Воно вказує проксі waypoint, як визначати, коли точки доступу сервісу є несправними. Це необхідно для належного функціонування відмовостійкості.

- [Пріоритет відмовостійкості](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting), який вказує проксі waypoint, як пріоритезувати точки доступу під час маршрутизації запитів. У цьому прикладі проксі waypoint надаватиме перевагу точкам доступу у тому самому кластері над точками доступу в інших кластерах.

З цими політиками проксі waypoint надаватимуть перевагу точкам доступу в тому самому кластері, що й проксі waypoint, коли вони доступні та вважаються справними згідно з конфігурацією виявлення викидів.

## Перевірка, що трафік залишається в локальному кластері {#verify-traffic-stays-in-local-cluster}

Надішліть запит з подів `curl` на `cluster1` до сервісу `HelloWorld`:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Тепер, якщо ви повторите цей запит кілька разів, ви побачите, що версія `HelloWorld` завжди має бути `v1`, оскільки трафік залишається в `cluster1`:

{{< text plain >}}
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
...
{{< /text >}}

Аналогічно, надішліть запит з подів `curl` на `cluster2` кілька разів:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Ви маєте побачити, що всі запити обробляються в `cluster2`, дивлячись на версію у відповіді:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

## Перевірка відмовостійкості до іншого кластера {#verify-failover-to-another-cluster}

Щоб перевірити, що відмовостійкість до віддаленого кластера працює, змоделюйте відмову сервісу `HelloWorld` у `cluster1`, зменшивши масштаб розгортання:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" scale --replicas=0 deployment/helloworld-v1 -n sample
{{< /text >}}

Надішліть запит з подів `curl` на `cluster1` до сервісу `HelloWorld` знову:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Цього разу ви маєте побачити, що запит обробляється сервісом `HelloWorld` у `cluster2`, оскільки в `cluster1` немає доступних точок доступу:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

**Вітаємо!** Ви успішно налаштували локальну відмовостійкість в ambient мультикластерному розгортанні Istio!
