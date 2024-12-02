---
title: Встановлення Primary-Remote в різних мережах
description: Встановіть Istio mesh на основний та віддалений кластери в різних мережах.
weight: 40
keywords: [kubernetes, multicluster]
test: yes
owner: istio/wg-environments-maintainers
---

Дотримуйтесь цього посібника для встановлення панелі управління Istio на `cluster1` ({{< gloss "основний кластер" >}}primary кластер{{< /gloss >}}) та налаштування `cluster2` ({{< gloss "віддалений кластер" >}}remote кластер{{< /gloss >}}) для використання панелі управління в `cluster1`. Кластер `cluster1` розміщений в мережі `network1`, а `cluster2` — в мережі `network2`. Це означає, що між podʼами в різних кластерах немає прямого зʼєднання.

Перш ніж продовжити, переконайтеся, що ви виконали кроки з розділу [перш ніж почати](/docs/setup/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

У цій конфігурації кластер `cluster1` буде спостерігати за API серверами в обох кластерах для пошуку точок доступу. Таким чином, панель управління зможе забезпечити виявлення сервісів для робочих навантажень в обох кластерах.

Робочі навантаження між кластерами взаємодіють опосередковано, через спеціалізовані шлюзи для трафіку [east-west](https://en.wikipedia.org/wiki/East-west_traffic). Шлюз у кожному кластері повинен бути досяжним з іншого кластера.

Сервіси в `cluster2` будуть мати доступ до панелі управління в `cluster1` через той самий шлюз east-west.

{{< image width="75%"
    link="arch.svg"
    caption="Primary і remote кластери в різних мережах"
>}}

## Налаштування стандартної мережі для `cluster1` {#set-the-default-network-for-cluster1}

Якщо простір імен istio-system вже створений, необхідно встановити для нього мережу кластера:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Налаштування `cluster1` як primary кластера {#configure-cluster1-as-a-primary}

Створіть конфігурацію `istioctl` для `cluster1`:

{{< tabset category-name="multicluster-primary-remote-install-type-primary-cluster" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Встановіть Istio як primary у `cluster1` за допомогою istioctl та API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
      externalIstiod: true
EOF
{{< /text >}}

Застосуйте конфігурацію до `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

Зверніть увагу, що параметр `values.global.externalIstiod` встановлено як `true`. Це дозволяє панелі управління, встановленій в `cluster1`, також слугувати зовнішньою панеллю управління для інших віддалених кластерів. Коли цю функцію увімкнено, `istiod` намагатиметься отримати блокування лідерства і, відповідно, керувати [належним чином позначеними](#set-the-control-plane-cluster-for-cluster2) віддаленими кластерами, які приєднані до нього (у цьому випадку, `cluster2`).

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як primary у `cluster1` за допомогою наступних команд Helm:

Встановіть чарт `base` у `cluster1`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Потім встановіть чарт `istiod` в `cluster1` з наступними налаштуваннями мультикластера:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.externalIstiod=true --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

Зверніть увагу, що `values.global.externalIstiod` має значення `true`. Це дозволить панелі управління, встановленій на `cluster1`, також слугувати зовнішньою панеллю управління для інших віддалених кластерів. Коли цю можливість увімкнено, `istiod` намагатиметься отримати блокування лідерства, а отже, керувати [відповідно анотованими](#set-the-control-plane-cluster-for-cluster2) віддаленими кластерами, які до нього приєднано (у цьому випадку, `cluster2`).

{{< /tab >}}

{{< /tabset >}}

## Встановлення шлюзу east-west в `cluster1` {#install-the-east-west-gateway-in-cluster1}

Встановіть шлюз у `cluster1`, який буде призначений для трафіку east-west. Стандартно цей шлюз буде доступний в Інтернеті. Операційні розгортання можуть вимагати додаткових обмежень доступу (наприклад, через правила брандмауера), щоб запобігти зовнішнім атакам. Зверніться до свого хмарного постачальника, щоб дізнатися про доступні варіанти.

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
Якщо панель управління була встановлена з revision, додайте прапорець `--revision rev` до команди `gen-eastwest-gateway.sh`.
{{< /warning >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть шлюз east-west у `cluster1` за допомогою наступної команди Helm:

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER1}" --set name=istio-eastwestgateway --set networkGateway=network1
{{< /text >}}

{{< warning >}}
Якщо панель управління було встановлено з ревізією, вам слід додати прапорець `--set revision=<моя-ревізія>` до команди встановлення Helm.
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

Очікуйте на призначення зовнішньої IP-адреси для шлюзу east-west:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Відкриття доступу до панелі управління в `cluster1` {#expose-the-control-plane-in-cluster1}

Перш ніж ми зможемо виконати встановлення в `cluster2`, необхідно спочатку відкрити доступ до панелі управління в `cluster1`, щоб сервіси в `cluster2` могли отримувати доступ до виявлення сервісів:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

{{< warning >}}
Якщо панель управління була встановлена з ревізією `rev`, використовуйте наступну команду:

{{< text bash >}}
$ sed 's/{{.Revision}}/rev/g' @samples/multicluster/expose-istiod-rev.yaml.tmpl@ | kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f -
{{< /text >}}

{{< /warning >}}

## Налаштування панелі управління для `cluster2` {#set-the-control-plane-cluster-for-cluster2}

Необхідно визначити зовнішню панель управління, яка повинна керувати `cluster2`, анотувавши простір імен istio-system:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
{{< /text >}}

Встановлення анотації простору імен `topology.istio.io/controlPlaneClusters` в `cluster1` інструктує `istiod`, що працює в тому ж просторі імен (istio-system у цьому випадку) в `cluster1`, управляти `cluster2`, коли він буде [приєднаний як віддалений кластер](#attach-cluster2-as-a-remote-cluster-of-cluster1).

## Налаштування стандартної мережі для `cluster2` {#set-the-default-network-for-cluster2}

Встановіть мережу для `cluster2`, додавши мітку до простору імен istio-system:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## Налаштування `cluster2` як remote кластера {#configure-cluster2-as-a-remote}

Збережіть адресу шлюзу east-west `cluster1`.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Тепер створіть віддалену конфігурацію на `cluster2`.

{{< tabset category-name="multicluster-primary-remote-install-type-remote-cluster" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    istiodRemote:
      injectionPath: /inject/cluster/cluster2/net/network2
    global:
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

Застосуйте конфігурацію до `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як remote у `cluster2` за допомогою наступних команд Helm:

Install the `base` chart in `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --set profile=remote --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Потім встановіть чарт `istiod` у `cluster2` з наступними налаштуваннями мультикластера:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set profile=remote --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set istiodRemote.injectionPath=/inject/cluster/cluster2/net/network2  --set global.configCluster=true --set global.remotePilotAddress="${DISCOVERY_ADDRESS}" --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

{{< tip >}}

Профіль `remote` для чартів `base` та `istiod` Helm доступний лише починаючи з версії Istio 1.24.

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
Тут ми налаштовуємо розташування панелі управління, використовуючи параметри `injectionPath` і `remotePilotAddress`. Хоча це зручно для демонстрації, в операційному середовищі рекомендується конфігурувати параметр `injectionURL`, використовуючи правильно підписані сертифікати DNS, подібно до конфігурації, показаної в [інструкціях для зовнішньої панелі управління](/docs/setup/install/external-controlplane/#register-the-new-cluster).
{{< /tip >}}

## Приєднання `cluster2` як віддаленого кластера до `cluster1` {#attach-cluster2-as-a-remote-cluster-of-cluster1}

Щоб приєднати віддалений кластер до його панелі управління, ми надаємо панелі управління в `cluster1` доступ до API сервера в `cluster2`. Це зробить наступне:

- Дозволяє панелі управління автентифікувати запити на зʼєднання від робочих навантажень, що працюють в `cluster2`. Без доступу до API сервера панель управління відхилить запити.

- Дозволяє виявлення точок доступу сервісів, що працюють в `cluster2`.

Оскільки це включено в анотацію простору імен `topology.istio.io/controlPlaneClusters`, панель управління на `cluster1` також:

- Застосовує патчі сертифікати в вебхуках в `cluster2`.

- Запускає контролер просторів імен, який записує configmap в простори імен в `cluster2`.

Щоб надати доступ до API сервера для `cluster2`, ми створюємо віддалений секрет і застосовуємо його до `cluster1`:

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

## Встановлення шлюзу east-west в `cluster2` {#install-the-east-west-gateway-in-cluster2}

Як і в `cluster1` вище, встановіть шлюз у `cluster2`, який буде призначений для трафіку east-west та експонує сервіси користувача.

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть шлюз east-west у `cluster2` за допомогою наступної команди Helm:

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER2}" --set name=istio-eastwestgateway --set networkGateway=network2
{{< /text >}}

{{< warning >}}
Якщо панель управління було встановлено з ревізією, вам слід додати `--set revision=<моя-ревізія>` до команди встановлення Helm.
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

Очікуйте, поки для шлюзу east-west буде призначена зовнішня IP-адреса:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## Експонування сервісів у `cluster1` та `cluster2` {#expose-services-in-cluster1-and-cluster2}

Оскільки кластери знаходяться в окремих мережах, нам також потрібно відкрити всі сервіси користувачів (*.local) шлюзі east-west в обох кластерах. Хоча ці шлюзи є публічними в Інтернет, сервіси за ними можуть бути доступні тільки сервісам з довіреними сертифікатами mTLS та ідентифікаторами робочих навантажень, так само як якби вони були в одній мережі.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

{{< tip >}}
Оскільки `cluster2` встановлений з віддаленим профілем, експонування сервісів в основному кластері відкриє їх на шлюзах east-west обох кластерів.
{{< /tip >}}

**Вітаємо!** Ви успішно встановили Istio mesh в основному та віддаленому кластерах в різних мережах!

## Подальші кроки {#next-steps}

Тепер ви можете [перевірити встановлення](/docs/setup/install/multicluster/verify).

## Очищення {#cleanup}

Видаліть Istio з `cluster1` і `cluster2` за допомогою того ж механізму, за допомогою якого ви встановлювали Istio (istioctl або Helm).

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Видаліть Istio з `cluster1`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Видаліть Istio з `cluster2`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

Видаліть встановлення Istio Helm з `cluster1`:

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Видаліть простір імен `istio-system` з `cluster1`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Видаліть встановлення Istio Helm з `cluster2`:

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Видаліть простір імен `istio-system` з `cluster2`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

(Опціонально) Видаліть CRD, встановлені Istio:

Видалення CRD назавжди видаляє всі ресурси Istio, які ви створили у ваших кластерах. Щоб видалити Istio CRD, встановлені у ваших кластерах:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
