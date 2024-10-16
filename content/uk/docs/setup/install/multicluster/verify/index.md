---
title: Перевірка встановлення
description: Переконайтеся, що Istio правильно встановлено на декількох кластерах.
weight: 50
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
Слідуйте цьому посібнику, щоб перевірити, що ваша установка Istio для кількох кластерів працює належним чином.

Перед тим як продовжити, обовʼязково завершите кроки в розділі [перш ніж почати](/docs/setup/install/multicluster/before-you-begin), а також виберіть і дотримуйтесь одного з посібників з установки для кількох кластерів.

У цьому посібнику ми розгорнемо застосунок `HelloWorld` `V1` у `cluster1` та `V2` у `cluster2`. При отриманні запиту `HelloWorld` включатиме свою версію у відповідь.

Ми також розгорнемо контейнер `Sleep` в обох кластерах. Ми будемо використовувати ці контейнери як джерело запитів до сервісу `HelloWorld`, імітуючи трафік всередині мережі. Нарешті, після генерації трафіку ми спостерігатимемо, який кластер отримав запити.

## Розгортання сервісу `HelloWorld` {#deploy-the-helloworld-service}

Щоб зробити сервіс `HelloWorld` доступним з будь-якого кластера, пошуковий запит DNS повинен успішно проходити в кожному кластері (див. [моделі розгортання](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters) для деталей). Ми вирішимо це, розгорнувши сервіс `HelloWorld` в кожному кластері в мережі.

Для початку створіть простір імен `sample` в кожному кластері:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

Увімкніть автоматичне додавання sidecar контейнерів для простору імен `sample`:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled
{{< /text >}}

Створіть сервіс `HelloWorld` в обох кластерах:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
{{< /text >}}

## Розгортання `HelloWorld` `V1` {#deploy-helloworld-v1}

Розгорніть застосунок `helloworld-v1` в `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

Перевірте статус podʼа `helloworld-v1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
{{< /text >}}

Дочекайтесь, поки статус `helloworld-v1` буде `Running`.

## Розгортання `HelloWorld` `V2` {#deploy-helloworld-v2}

Розгорніть застосунок `helloworld-v2` в `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

Перевірте статус podʼа `helloworld-v2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
{{< /text >}}

Дочекайтесь, поки статус `helloworld-v2` буде `Running`.

## Розгортання `Sleep` {#deploy-sleep}

Розгорніть застосунок `Sleep` в обох кластерах:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/sleep/sleep.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

Перевірте статус podʼа `Sleep` в `cluster1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-n6bzf           2/2     Running   0          5s
{{< /text >}}

Дочекайтесь, поки статус podʼа `Sleep` буде `Running`.

Перевірте статус podʼа `Sleep` в `cluster2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-dzl9j           2/2     Running   0          5s
{{< /text >}}

Дочекайтесь, поки статус podʼа `Sleep` буде `Running`.

## Перевірка міжкластерного трафіку {#verify-cross-cluster-traffic}

Щоб перевірити, чи працює міжкластерне балансування навантаження як очікується, викликайте сервіс `HelloWorld` кілька разів за допомогою podʼа `Sleep`. Щоб забезпечити правильність балансування навантаження, викликайте сервіс `HelloWorld` з усіх кластерів у вашій установці.

Відправте один запит з podʼа `Sleep` в `cluster1` до сервісу `HelloWorld`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Повторіть цей запит кілька разів і перевірте, що версія `HelloWorld` повинна перемикатися між `v1` і `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Тепер повторіть цей процес з podʼа `Sleep` в `cluster2`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Повторіть цей запит кілька разів і перевірте, що версія `HelloWorld` повинна перемикатися між `v1` і `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**Вітаємо!** Ви успішно встановили та перевірили Istio на кількох кластерах!

## Наступні кроки {#next-steps}

Ознайомтесь з [завданнями з балансування навантаження за локальністю](/docs/tasks/traffic-management/locality-load-balancing), щоб дізнатися, як керувати трафіком у мережі з кількома кластерами.
