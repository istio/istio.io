---
title: Встановлення Primary-Remote
description: Встановлення мережі Istio на основний та віддалений кластери.
weight: 20
keywords: [kubernetes,мультикластер]
test: yes
owner: istio/wg-environments-maintainers
---

Слідуйте цьому посібнику, щоб встановити панель управління Istio в `cluster1` ({{< gloss "основний кластер" >}}primary кластер{{< /gloss >}}) та налаштувати `cluster2` ({{< gloss "віддалений кластер" >}}remote кластер{{< /gloss >}}) для використання панелі управління в `cluster1`. Обидва кластери знаходяться в мережі `network1`, що означає пряму взаємодію між podʼами в обох кластерах.

Перед тим, як продовжити, обовʼязково виконайте кроки, наведені в розділі [перш ніж почати](/docs/setup/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}
{{< warning >}}
Ці інструкції не підходять для розгортання primary кластера AWS EKS. Причиною цієї несумісності є те, що AWS Load Balancers (LB) представляються як повні доменні імена (FQDN), тоді як віддалений кластер використовує тип служби Kubernetes `ExternalName`. Однак, тип `ExternalName` підтримує виключно IP-адреси та не допускає FQDN.
{{< /warning >}}

У цій конфігурації кластер `cluster1` буде спостерігати за API-серверами в обох кластерах для моніторингу точок доступу. Таким чином, панель управління зможе забезпечити виявлення сервісів для робочих навантажень в обох кластерах.

Сервісні навантаження спілкуються безпосередньо (pod-pod) через межі кластерів.

Сервіси у `cluster2` отримають доступ до панелі управління в `cluster1` через спеціальний шлюз для трафіку [east-west](https://en.wikipedia.org/wiki/East-west_traffic).

{{< image width="75%"
    link="arch.svg"
    caption="Primary та remote кластери в одній мережі"
    >}}

## Налаштування `cluster1` як primary {#configure-cluster1-as-a-primary}

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

Зверніть увагу, що `values.global.externalIstiod` встановлено на `true`. Це дозволяє панелі управління, встановленій у `cluster1`, також виконувати роль зовнішньої панелі управління для інших віддалених кластерів. Коли цю функцію увімкнено, `istiod` намагатиметься отримати блокування лідерства і, відповідно, керувати [відповідно анотованими](#set-the-control-plane-cluster-for-cluster2) віддаленими кластерами, які приєднані до нього (в цьому випадку, `cluster2`).

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

Зверніть увагу, що `values.global.externalIstiod` має значення `true`. Це дозволить панелі управління, встановленій у `cluster1`, також слугувати зовнішньою панеллю управління для інших віддалених кластерів. Коли цю можливість увімкнено, `istiod` намагатиметься отримати блокування лідерства, а отже, керувати [відповідно анотованими](#set-the-control-plane-cluster-for-cluster2) віддаленими кластерами, які до нього приєднано (у цьому випадку, `cluster2`).

{{< /tab >}}

{{< /tabset >}}

## Встановлення шлюзу east-west у `cluster1` {#install-the-east-west-gateway-in-cluster1}

Встановіть шлюз в `cluster1`, призначений для трафіку [east-west](https://en.wikipedia.org/wiki/East-west_traffic). Стандартно цей шлюз буде публічним в Інтернеті. Операційні розгортання можуть вимагати додаткових обмежень доступу (наприклад, через правила брандмауера), щоб запобігти зовнішнім атакам. Зверніться до свого постачальника хмарних послуг, щоб дізнатися, які варіанти доступні.

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
Якщо панель управління було встановлено з revision, додайте прапорець `--revision rev` до команди `gen-eastwest-gateway.sh`.
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

Дочекайтеся призначення зовнішньої IP-адреси для шлюзу east-west:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Експонування панелі управління в `cluster1` {#expose-the-control-plane-in-cluster1}

Перед тим як встановлювати `cluster2`, потрібно спочатку експонувати панель управління в `cluster1`, щоб сервіси в `cluster2` могли отримати доступ до виявлення сервісів:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

{{< warning >}}
Якщо панель управління було встановлено з версією `rev`, використовуйте наступну команду:

{{< text bash >}}
$ sed 's/{{.Revision}}/rev/g' @samples/multicluster/expose-istiod-rev.yaml.tmpl@ | kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f -
{{< /text >}}
{{< /warning >}}

## Встановлення панелі управління для `cluster2` {#set-the-control-plane-cluster-for-cluster2}

Необхідно визначити кластер зовнішньої панелі управління, який буде керувати `cluster2`, додавши анотацію до простору імен `istio-system`:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
{{< /text >}}

Встановлення анотації простору імен `topology.istio.io/controlPlaneClusters` в `cluster1` інструктує `istiod`, що працює в тому ж просторі імен (`istio-system` в цьому випадку) у `cluster1`, керувати `cluster2`, коли він буде [підключений як віддалений кластер](#attach-cluster2-as-a-remote-cluster-of-cluster1).

## Налаштування `cluster2` як remote {#configure-cluster2-as-a-remote}

Збережіть адресу шлюзу east-west у `cluster1`:

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Тепер створіть конфігурацію для віддаленого `cluster2`:

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
      injectionPath: /inject/cluster/cluster2/net/network1
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

Встановіть Istio як віддалений у `cluster2` за допомогою наступних команд Helm:

Встановіть чарт `base` у `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --set profile=remote --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Потім встановіть чарт `istiod` у `cluster2` з наступними налаштуваннями мультикластера:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set profile=remote --set global.multiCluster.clusterName=cluster2 --set istiodRemote.injectionPath=/inject/cluster/cluster2/net/network1 --set global.configCluster=true --set global.remotePilotAddress="${DISCOVERY_ADDRESS}" --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

{{< tip >}}

Профіль `remote` для чартів `base` та `istiod` Helm доступний лише починаючи з версії Istio 1.24.

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
Тут ми налаштовуємо розташування панелі управління за допомогою параметрів `injectionPath` та `remotePilotAddress`. Хоча це зручно для демонстрації, в операційному середовищі рекомендується замість цього налаштовувати параметр `injectionURL`, використовуючи належним чином підписані DNS-сертифікати, аналогічно конфігурації, показаній в [інструкціях з налаштування зовнішньої панелі управління](/docs/setup/install/external-controlplane/#register-the-new-cluster).
{{< /tip >}}

## Приєднання `cluster2` як remote кластера до `cluster1` {#attach-cluster2-as-a-remote-cluster-of-cluster1}

Щоб приєднати віддалений кластер до його панелі управління, ми надаємо панелі управління в `cluster1` доступ до API-сервера в `cluster2`. Це забезпечить наступне:

- Дозволяє панелі управління автентифікувати запити на підключення від робочих навантажень, що працюють у `cluster2`. Без доступу до API-сервера панель управління відхилить запити.

- Дозволяє виявлення точок доступу сервісів, що працюють у `cluster2`.

Оскільки це було включено в анотацію простору імен `topology.istio.io/controlPlaneClusters`, панель управління в `cluster1` також:

- Застосує сертифікати до вебхуків в `cluster2`.

- Запустить контролер простору імен, який записує configmap у просторах імен в `cluster2`.

Щоб надати доступ до API-сервера в `cluster2`, ми створюємо віддалений секрет і застосовуємо його до `cluster1`:

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Вітаємо!** Ви успішно встановили сервісну мережу Istio на основний та віддалений кластери!

## Наступні кроки {#next-steps}

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
