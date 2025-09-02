---
title: Перевірка встановлення ambient
description: Перевірте, чи правильно встановлено Istio ambient mesh на кількох кластерах.
weight: 50
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/multi-primary_multi-network
---
Дотримуйтесь цього посібника, щоб переконатися, що ваша мультикластерна установка Istio працює належним чином.

Перед продовженням обовʼязково виконайте кроки в розділі [Як розпочати](/docs/ambient/install/multicluster/before-you-begin), а також виберіть і дотримуйтесь одного з [посібників з установки мультикластерів](/docs/ambient/install/multicluster).

У цьому посібнику ми перевіримо, чи функціонує мультикластерна установка, розгорнувши застосунок `HelloWorld` `v1` у `cluster1` і `v2` у `cluster2`. Після отримання запиту `HelloWorld` включить свою версію у відповідь, коли ми викликаємо шлях `/hello`.

Ми також розгорнемо контейнер `curl` у обох кластерах. Ми будемо використовувати ці поди як джерело запитів до сервісу `HelloWorld`, імітуючи трафік у межах мережі. Нарешті, після генерації трафіку ми спостерігатимемо, який кластер отримав запити.

## Перевірка мультикластера {#verify-multicluster}

Щоб підтвердити, що Istiod тепер може спілкуватися з панеллю управління Kubernetes віддаленого кластера.

{{< text bash >}}
$ istioctl remote-clusters --context="${CTX_CLUSTER1}"
NAME         SECRET                                        STATUS      ISTIOD
cluster1                                                   synced      istiod-7b74b769db-kb4kj
cluster2     istio-system/istio-remote-secret-cluster2     synced      istiod-7b74b769db-kb4kj
{{< /text >}}

Усі кластери повинні вказувати свій статус як `synced`. Якщо кластер показується зі статусом `timeout`, це означає, що Istiod у основному кластері не може звʼязатися з віддаленим кластером. Дивіться журнали Istiod для отримання детальних повідомлень про помилки.

Примітка: якщо ви бачите проблеми з `timeout` і між Istiod у основному кластері та панеллю управління Kubernetes у віддаленому кластері є проміжний хост (такий як [Rancher auth proxy](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/manage-clusters/access-clusters/authorized-cluster-endpoint#two-authentication-methods-for-rke-clusters)), можливо, вам потрібно буде оновити поле `certificate-authority-data` конфігурації kubeconfig, яку генерує `istioctl create-remote-secret`, щоб відповідати сертифікату, що використовується проміжним хостом.

## Розгортання `HelloWorld` Service {#deploy-the-helloworld-service}

Щоб зробити сервіс `HelloWorld` доступним для виклику з будь-якого кластера, пошук DNS повинен бути успішним у кожному кластері (детальніше див. [моделі розгортання](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)). Ми вирішимо цю проблему, розгорнувши сервіс `HelloWorld` у кожному кластері мережі.

{{< tip >}}
Перед продовженням переконайтеся, що простори імен istio-system в обох кластерах мають `istio.io/topology-network`, встановлений на відповідне значення (наприклад, `network1` для `cluster1` і `network2` для `cluster2`).
{{< /tip >}}

Щоб почати, створіть простір імен `sample` у кожному кластері:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

Створіть простір імен `sample` у сервісній мережі:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio.io/dataplane-mode=ambient
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio.io/dataplane-mode=ambient
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

Розгорніть застосунок `helloworld-v1` у `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

Підтвердіть статус пода `helloworld-v1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  1/1       Running   0          40s
{{< /text >}}

Дочекайтеся, поки статус `helloworld-v1` стане `Running`.

Тепер позначте сервіс helloworld у `cluster1` як глобальний, щоб до нього можна було отримати доступ з інших кластерів у мережі:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Розгортання `HelloWorld` `V2` {#deploy-helloworld-v2}

Розгорніть застосунок `helloworld-v2` у `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

Підтвердіть статус пода `helloworld-v2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  1/1       Running   0          40s
{{< /text >}}

Дочекайтеся, поки статус `helloworld-v2` стане `Running`.

Тепер позначте сервіс helloworld у `cluster2` як глобальний, щоб до нього можна було отримати доступ з інших кластерів у мережі:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER2}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Розгортання `curl` {#deploy-curl}

Розгорніть застосунок `curl` у обох кластерах:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/curl/curl.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/curl/curl.yaml@ -n sample
{{< /text >}}

Підтвердіть статус пода `curl` у `cluster1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-n6bzf            1/1     Running   0          5s
{{< /text >}}

Дочекайтеся, поки статус пода `curl` стане `Running`.

Підтвердіть статус пода `curl` у `cluster2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-dzl9j            1/1     Running   0          5s
{{< /text >}}

Дочекайтеся, поки статус пода `curl` стане `Running`.

## Перевірка міжкластерного трафіку {#verifying-cross-cluster-traffic}

Щоб перевірити, чи працює балансування навантаження між кластерами, кілька разів викликайте сервіс `HelloWorld`, використовуючи под `curl`. Щоб забезпечити навантаження балансування, викликайте сервіс `HelloWorld` з усіх кластерів у вашому розгортанні.

Надішліть один запит з пода `curl` на `cluster1` до сервісу `HelloWorld`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Повторіть запит кілька разів та перевірте, що версія `HelloWorld` повинна змінюватися між `v1` і `v2`, що свідчить про те, що використовуються точки доступу в обох кластерах:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Тепер повторіть цей процес з подом `curl` у `cluster2`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Повторіть цей запит кілька разів та перевірте, що версія `HelloWorld` повинна змінюватися між `v1` і `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**Вітаємо!** Ви успішно встановили та перевірили Istio на кількох кластерах!

<!-- TODO: Link to guide for locality load balancing once we add waypoint instructions -->
