---
title: Встановлення Multi-Primary в різних мережах
description: Встановлення Istio mesh для кількох primary кластерів в різних мережах.
weight: 30
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers

---

Дотримуйтесь цього керівництва, щоб встановити панель управління Istio в обох `cluster1` та `cluster2`, зробивши кожен {{< gloss "основний кластер" >}}primary кластером{{< /gloss >}}. Кластер `cluster1` знаходиться в мережі `network1`, а `cluster2` — в мережі `network2`. Це означає, що між podʼами в різних кластерах немає прямого зʼєднання.

Перед тим, як продовжити, обовʼязково виконайте кроки, зазначені у розділі [перш ніж почати](/docs/setup/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

У цій конфігурації обидва `cluster1` та `cluster2` спостерігають за API серверами в кожному кластері для отримання точок доступу.

Робочі навантаження сервісів між кластерами спілкуються опосередковано, через спеціальні шлюзи для [east-west](https://en.wikipedia.org/wiki/East-west_traffic) трафіку. Шлюз у кожному кластері має бути доступний з іншого кластера.

{{< image width="75%"
    link="arch.svg"
    caption="Multiple primary clusters on separate networks"
    >}}

## Налаштування стандартної мережі для `cluster1` {#set-the-default-network-for-cluster1}

Якщо простір імен istio-system вже створений, необхідно встановити мережу кластера:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Налаштування `cluster1` як primary кластера {#configure-cluster1-as-a-primary}

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

## Встановлення east-west шлюзу в `cluster1` {#install-the-east-west-gateway-in-cluster1}

Встановіть шлюз в `cluster1`, який призначений для [east-west](https://en.wikipedia.org/wiki/East-west_traffic) трафіку. Стандартно цей шлюз буде доступний в Інтернеті. Операційні розгортання можуть вимагати додаткових обмежень доступу (наприклад, через правила брандмауера), щоб запобігти зовнішнім атакам. Зверніться до свого хмарного постачальника, щоб дізнатися про доступні варіанти.

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
Якщо панель управління була встановлена з використанням ревізії, додайте прапорець `--revision rev` до команди `gen-eastwest-gateway.sh`.
{{< /warning >}}

Дочекайтеся призначення зовнішньої IP-адреси для east-west шлюзу:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Експонування сервісів в `cluster1` {#expose-services-in-cluster1}

Оскільки кластери знаходяться в окремих мережах, нам потрібно експонувати всі сервіси (*.local) через east-west шлюз в обох кластерах. Хоча цей шлюз і є загальнодоступним в Інтернеті, сервіси за ним можуть бути доступні лише сервісам з довіреним mTLS-сертифікатом та ідентифікатором робочого навантаження, так само як якби вони знаходилися в тій самій мережі.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## Встановлення стандартної мережі для `cluster2` {#set-the-default-network-for-cluster2}

Якщо простір імен istio-system вже створений, необхідно втсановити мережу кластера:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## Налаштування `cluster2` як primary кластера {#configure-cluster2-as-a-primary}

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
      network: network2
EOF
{{< /text >}}

Застосуйте конфігурацію до `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## Встановлення east-west шлюзу в `cluster2` {#install-the-east-west-gateway-in-cluster2}

Як і у випадку з `cluster1`, встановіть шлюз у `cluster2`, який призначений для east-west трафіку.

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

Дочекайтеся призначення зовнішньої IP-адреси для east-west шлюзу:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## Експонування сервісів у `cluster2` {#expose-services-in-cluster2}

Як і у випадку з `cluster1`, експонуйте сервіси через east-west шлюз.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## Увімкнення виявлення точок доступу {#enable-endpoint-discovery}

Встановіть віддалений секрет у `cluster2`, який надає доступ до API сервера `cluster1`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Встановіть віддалений секрет у `cluster1`, який надає доступ до API сервера `cluster2`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Вітаємо!** Ви успішно встановили Istio mesh для кількох основних кластерів на різних мережах!

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
