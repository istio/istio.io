---
title: Передумови, специфічні для певних платформ
description: Передумови для встановлення Istio в режимі навколишнього середовища, специфічні для конкретної платформи.
weight: 2
aliases:
  - /uk/docs/ops/ambient/install/platform-prerequisites
  - /uk/latest/docs/ops/ambient/install/platform-prerequisites
owner: istio/wg-environments-maintainers
test: no
---

Цей документ охоплює будь-які специфічні для платформи або середовища вимоги для установки Istio в режимі ambient.

## Платформа {#platform}

Деякі середовища Kubernetes вимагають налаштування різних параметрів конфігурації Istio для їх підтримки.

### Google Kubernetes Engine (GKE) {#google-kubernetes-engine-gke}

У GKE компоненти Istio з `priorityClassName` [system-node-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) можуть бути встановлені лише в просторах імен, в яких визначено [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/). Стандартно у GKE лише `kube-system` має визначений ResourceQuota для класу `node-critical`. Історичний агент CNI та `ztunnel` обидва потребують класу `node-critical`, тому в GKE обидва компоненти повинні бути:

- Встановлені в `kube-system` (_не_ в `istio-system`)
- Встановлені в інший простір імен (наприклад, `istio-system`), в якому вручну створено ResourceQuota, наприклад:

{{< text syntax=yaml >}}
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gcp-critical-pods
  namespace: istio-system
spec:
  hard:
    pods: 1000
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values:
      - system-node-critical
{{< /text >}}

### k3d {#k3d}

Коли ви використовуєте [k3d](https://k3d.io/) зі стандартним Flannel CNI, вам потрібно додати коректне значення `platform` до вашої команди встановлення, оскільки k3d використовує нестандартні розташування для конфігурацій CNI та двійкових файлів, що потребують певних перевизначень в Helm.

1. Створіть кластер з вимкненим Traefik, щоб уникнути конфлікту з ingress gateways Istio:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

2. Встановіть `global.platform=k3d` під час встановлення чартів Istio. Наприклад:

    {{< tabset category-name="install-method" >}}

    {{< tab name="Helm" category-value="helm" >}}

        {{< text syntax=bash >}}
        $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait
        {{< /text >}}

    {{< /tab >}}

    {{< tab name="istioctl" category-value="istioctl" >}}

        {{< text syntax=bash >}}
        $ istioctl install --set profile=ambient --set values.global.platform=k3d
        {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

### K3s {#k3s}

Коли ви використовуєте [K3s](https://k3s.io/) та одну з його вбудованих CNIs, ви повинні додати правильне значення `platform` до ваших команд установки, оскільки K3s використовує нестандартні розташування для конфігурацій CNI та бінарних файлів, що вимагає деяких перевизначень в Helm. Для стандартних шляхів K3s Istio надає вбудовані перевизначення на основі значення `global.platform`.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3s --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=k3s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Однак ці розташування можуть бути перевизначені в K3s, [згідно з документацією K3s](https://docs.k3s.io/cli/server#k3s-server-cli-help). Якщо ви використовуєте K3s з власним, не вбудованим CNI, ви повинні вручну вказати правильні шляхи для цих CNIs, наприклад, `/etc/cni/net.d` — [див. документацію K3s для деталей](https://docs.k3s.io/networking/basic-network-options#custom-cni). Наприклад:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### MicroK8s

Якщо ви встановлюєте Istio на [MicroK8s](https://microk8s.io/), вам потрібно додати коректне значення `platform` до вашої команди встановлення, оскільки MicroK8s [використовує нестандартні розташування для конфігурації CNI та двійкових файлів](https://microk8s.io/docs/change-cidr). Наприклад:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=microk8s --wait

    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=microk8s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### minikube

Якщо ви використовуєте [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) з [Docker-драйвером](https://minikube.sigs.k8s.io/docs/drivers/docker/), вам потрібно додати коректне значення `platform` до вашої команди встановлення, оскільки minikube з Docker використовує нестандартні привʼязки монтування шляхів для контейнерів. Наприклад:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=minikube --wait"
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=minikube"
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Red Hat OpenShift {#red-hat-openshift}

OpenShift вимагає, щоб компоненти `ztunnel` та `istio-cni` були встановлені в просторі імен `kube-system`, і щоб для всіх чартів було встановлено `global.platform=openshift`.

Якщо ви використовуєте `helm`, ви можете безпосередньо встановити цільовий простір імен і значення `global.platform`.

Якщо ви використовуєте `istioctl`, ви повинні використати спеціальний профіль з назвою `openshift-ambient`, щоб досягти того самого результату.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n kube-system --set profile=ambient --set global.platform=openshift --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=openshift-ambient --skip-confirmation
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Втулки CNI {#cni-plugins}

Наведені нижче конфігурації застосовуються до всіх платформ, якщо використовуються певні {{< gloss "CNI" >}}втулки CNI{{< /gloss >}}:

### Cilium

1. Cilium наразі стандартно проактивно видаляє інші втулки CNI та їх конфігурацію, і його потрібно налаштувати з `cni.exclusive = false`, щоб правильно підтримувати ланцюжки. Див. [документацію Cilium](https://docs.cilium.io/en/stable/helm-reference/) для більш детальної інформації.
2. BPF маскування в Cilium наразі стандартно вимкнено і має проблеми з використанням локальних IP-адрес Istio для перевірки справності Kubernetes. Увімкнення BPF маскування через `bpf.masquerade=true` наразі не підтримується і призводить до того, що в Istio ambient зʼявляються нефункціональні перевірки стану справності podʼів. Стандартна реалізація маскування iptables Cilium повинна продовжувати функціонувати правильно.
3. Через те, як Cilium керує ідентифікацією вузлів та внутрішніми списками дозволів на рівні вузлів, проби справності можуть бути передані до podʼів, застосування default-DENY `NetworkPolicy` в установці Cilium CNI, що лежить в основі Istio в режимі оточення, призведе до блокування проб справності `kubelet` (які стандартно не підпадають під дію NetworkPolicy в Cilium)..

    Це можна вирішити, застосувавши наступну `CiliumClusterWideNetworkPolicy`:

    {{< text syntax=yaml >}}
    apiVersion: "cilium.io/v2"
    kind: CiliumClusterwideNetworkPolicy
    metadata:
      name: "allow-ambient-hostprobes"
    spec:
      description: "Дозволяє SNAT перевірки справності kubelet в ambient podʼах"
      endpointSelector: {}
      ingress:
      - fromCIDR:
        - "169.254.7.127/32"
    {{< /text >}}

    Див. [тікет #49277](https://github.com/istio/istio/issues/49277) та [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy) для більш детальної інформації.
