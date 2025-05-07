---
title: Встановлення Multi-Primary
description: Встановлення мережі Istio на кілька основних кластерів.
weight: 10
keywords: [kubernetes,мультикластер]
test: yes
owner: istio/wg-environments-maintainers
---

Слідуйте цьому посібнику, щоб встановити панель управління Istio на `cluster1` та `cluster2`, роблячи кожен з них {{< gloss "основний кластер" >}}primary кластером{{< /gloss >}}. Обидва кластери знаходяться в мережі `network1`, що означає пряму взаємодію між podʼами в обох кластерах.

Перед тим, як продовжити, обовʼязково виконайте кроки, наведені в розділі [перш ніж почати](/docs/setup/install/multicluster/before-you-begin).

У цій конфігурації кожна панель управління спостерігає за API-серверами в обох кластерах для моніторингу точок доступу.

Сервісні навантаження спілкуються безпосередньо (pod-pod) через межі кластерів.

{{< image width="75%"
    link="arch.svg"
    caption="Кілька основних кластерів у одній мережі"
    >}}

## Налаштування `cluster1` як primary {#configure-cluster1-as-a-primary}

Створіть конфігурацію `istioctl` для `cluster1`:
{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Встановіть Istio як primary в `cluster1` використовуючи istioctl та `IstioOperator` API.

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
EOF
{{< /text >}}

Застосуйте конфігурацію до `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як primary у `cluster1` за допомогою наступних команд Helm:

Встановіть чарт `base` в `cluster1`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Потім встановіть чарт `istiod` в `cluster1` з наступними параметрами для мультикластера:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Налаштування `cluster2` як primary {#configure-cluster2-as-a-primary}

Створіть конфігурацію `istioctl` для `cluster2`:

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Встановіть Istio як primary у `cluster2` за допомогою istioctl та API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
EOF
{{< /text >}}

Застосуйте конфігурацію до `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як primary у `cluster2` за допомогою наступних команд Helm:

Встановіть чарт `base` у `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Потім встановіть чарт `istiod` у `cluster2` з наступними налаштуваннями мультикластера:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Увімкнення виявлення точок доступу {#enable-endpoint-discovery}

Встановіть віддалений секрет у `cluster2`, що надає доступ до API-сервера `cluster1`.

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Встановіть віддалений секрет у `cluster1`, що надає доступ до API-сервера `cluster2`.

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Вітаємо!** Ви успішно встановили сервісну мережу Istio на кілька primary кластерів!

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

Видалення CRD назавжди видаляє всі ресурси Istio, які ви створили у ваших кластерах. Видаліть CRD Istio, встановлені у ваших кластерах, за допомогою запуску:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
