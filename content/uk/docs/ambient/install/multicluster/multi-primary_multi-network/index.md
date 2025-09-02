---
title: Встановлення ambient multi-primary в різних мережах
description: Встановлення Istio ambient mesh у кількох основних кластерах в різних мережах.
weight: 30
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/verify
prev: /docs/ambient/install/multicluster/before-you-begin
---

{{< boilerplate alpha >}}

{{< tip >}}
Цей посібник вимагає встановлення CRD Gateway API.
{{< boilerplate gateway-api-install-crds >}}
{{< /tip >}}

Слідуйте цьому посібнику, щоб встановити панель управління Istio на `cluster1` і `cluster2`, зробивши кожен з них {{< gloss "Основний кластер" >}}основним кластером{{< /gloss >}} (це наразі єдина підтримувана конфігурація в режимі ambient). Кластер `cluster1` знаходиться в мережі `network1`, тоді як `cluster2` — в мережі `network2`. Це означає, що між podʼами кластерів немає прямого зʼєднання.

Перед продовженням обовʼязково виконайте кроки в розділі [Як розпочати](/docs/ambient/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

У цій конфігурації як `cluster1`, так і `cluster2` спостерігають за API-серверами в кожному кластері для отримання точок доступу.

Робочі навантаження сервісів між кластерами спілкуються опосередковано, через спеціальні шлюзи для [схід-захід](https://en.wikipedia.org/wiki/East-west_traffic) трафіку. Шлюз у кожному кластері повинен бути доступним з іншого кластера.

{{< image width="75%"
    link="arch.svg"
    caption="Кілька основних кластерів у окремих мережах"
    >}}

## Встановлення стандартної мережі для `cluster1` {#set-the-default-network-for-cluster1}

Якщо простір імен istio-system вже створено, нам потрібно встановити мережу кластера там:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Налаштування `cluster1` як основного {#configure-cluster1-as-a-primary}

Створіть конфігурацію `istioctl` для `cluster1`:

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Встановіть Istio як основний у `cluster1` за допомогою istioctl та API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

Застосувати конфігурацію до `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як основний у `cluster1` за допомогою таких команд Helm:

Встановіть чарт `base` у `cluster1`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Потім встановіть чарт `istiod` у `cluster1` із такими налаштуваннями для мультикластеру:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

Далі встановіть агента вузла CNI в режимі ambient:

{{< text syntax=bash snip_id=install_cni_cluster1 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER1}" --set profile=ambient
{{< /text >}}

Нарешті, встановіть пенель даних ztunnel:

{{< text syntax=bash snip_id=install_ztunnel_cluster1 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}" --set multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Встановлення ambient шлюзу схід-захід в `cluster1` {#install-an-ambient-east-west-gateway-in-cluster1}

Встановіть шлюз у `cluster1`, який призначений для ambient [east-west](https://en.wikipedia.org/wiki/East-west_traffic) трафіку. Зверніть увагу, що в залежності від вашого середовища Kubernetes, цей шлюз може бути розгорнутий та бути стандартно доступним в Інтернет. Системи у виробничому середовищі можуть вимагати додаткових обмежень доступу (наприклад, через правила брандмауера), щоб запобігти зовнішнім атакам. Звіртесь з документацією вашого постачальника хмари, щоб дізнатися, які варіанти доступні.

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 \
    --ambient | \
    kubectl --context="${CTX_CLUSTER1}" apply -f -
{{< /text >}}

{{< warning >}}
Якщо control-plane було встановлено з ревізією, додайте прапорець `--revision rev` до команди `gen-eastwest-gateway.sh`.
{{< /warning >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Встановіть шлюз схід-захід у `cluster1`, використовуючи таке визначення шлюзу:

{{< text bash >}}
$ cat <<EOF > cluster1-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network1"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
Якщо ви використовуєте ревізію istiod і не маєте стандартної ревізії або теґу, можливо, вам доведеться додати мітку `istio.io/rev` до цього маніфесту `Gateway`.
{{< /warning >}}

Застосуйте конфігурацію до `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f cluster1-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Дочекайтеся, поки шлюзу схід-захід буде призначено зовнішню IP-адресу:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Встановлення стандартної мережі для `cluster2` {#set-the-default-network-for-cluster2}

Якщо простір імен istio-system вже створено, нам потрібно встановити мережу кластера там:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## Налаштування `cluster2` як основного  {#configure-cluster2-as-a-primary}

Створіть конфігурацію `istioctl` для `cluster2`:

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Встановіть Istio як основний у `cluster2`, використовуючи istioctl та API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
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

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть Istio як основний у `cluster2`, використовуючи такі команди Helm:

Встановіть чарт `base` у `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Потім встановіть чарт `istiod` у `cluster2` із такими налаштуваннями для мультикластеру:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

Далі встановіть агент вузла CNI в режимі ambient:

{{< text syntax=bash snip_id=install_cni_cluster2 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER2}" --set profile=ambient
{{< /text >}}

Нарешті, встановіть панель даних ztunnel:

{{< text syntax=bash snip_id=install_ztunnel_cluster2 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"  --set multiCluster.clusterName=cluster2 --set global.network=network2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Встановлення ambient шлюзу схід-захід в `cluster2` {#install-an-ambient-east-west-gateway-in-cluster2}

Як і в `cluster1`, встановіть шлюз у `cluster2`, який буде призначений для трафіку схід-захід.

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 \
    --ambient | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Встановіть шлюз схід-захід у `cluster2`, використовуючи таке визначення Gateway:

{{< text bash >}}
$ cat <<EOF > cluster2-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network2"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
Якщо ви використовуєте ревізію istiod і не маєте стандартної ревізії або теґу, можливо, вам доведеться додати мітку `istio.io/rev` до цього маніфесту `Gateway`.
{{< /warning >}}

Застосуйте конфігурацію до `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" -f cluster2-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Дочекайтеся, поки шлюзу схід-захід буде призначено зовнішню IP-адресу:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## Увімкнення виявлення точок доступу {#enable-endpoint-discovery}

Встановіть віддалений секрет у `cluster2`, який надає доступ до API-сервера `cluster1`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Встановіть віддалений секрет у `cluster1`, який надає доступ до сервера API `cluster2`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Вітаємо!** Ви успішно встановили мережу Istio на декількох основних кластерах у різних мережах!

## Наступні кроки {#next-steps}

Тепер ви можете [перевірити встановлення](/docs/ambient/install/multicluster/verify).

## Очищення {#Cleanup}

Видаліть Istio з обох кластерів `cluster1` та `cluster2`, використовуючи той самий механізм, яким ви встановлювали Istio (istioctl або Helm).

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Видаліть Istio в `cluster1`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Видаліть Istio в `cluster2`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

Видаліть встановлення Istio Helm з `cluster1`:

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Видаліть простір імен `istio-system` з `cluster1`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Видаліть встановлення Istio Helm з `cluster2`:

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Видаліть простір імен `istio-system` з `cluster2`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

(Опціонально) Видалення CRD, встановлених Istio:

Видалення CRD призводить до остаточного видалення всіх ресурсів Istio, які ви створили у своїх кластерах. Щоб видалити CRD Istio, встановлені у ваших кластерах:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

І нарешті, очистіть CRD API Gateway:

{{< text syntax=bash snip_id=delete_gateway_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
