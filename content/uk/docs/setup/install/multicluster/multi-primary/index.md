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

Створіть конфігурацію Istio для `cluster1`:

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

## Налаштування `cluster2` як primary {#configure-cluster2-as-a-primary}

Створіть конфігурацію Istio для `cluster2`:

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

1. Видаліть Istio у `cluster1`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
    {{< /text >}}

1. Видаліть Istio у `cluster2`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
    {{< /text >}}
