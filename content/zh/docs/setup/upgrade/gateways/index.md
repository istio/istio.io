---
title: 多版本的 Gateway  管理 [实验性]
description: 使用 Gateway  配置和升级 Istio (实验性)。
weight: 30
keywords: [kubernetes,upgrading,gateway]
owner: istio/wg-environments-maintainers
test: no
---

{{< boilerplate experimental >}}

使用一个 `IstioOperator` CR，即使在使用 [金丝雀升级](/zh/docs/setup/upgrade/canary)，CR 中定义的任何 Gateway  （包括安装在默认配置文件中的 `istio-ingressgateway`）也会被热升级。但应该避免这样，因为 Gateway  是影响应用程序正常运行时的关键组件。在新的控制和数据平面可以正常工作以后，再升级 Gateway  。

本指南将会向您介绍通过在单独的 `IstioOperator` CR 中定义和管理来升级 Gateway  的推荐方法，与用于安装和管理控制平面的设备分开。

{{< warning >}}
为了避免 `.`（点）在一些 Kubernetes 的路径中不是有效字符，修订名称不应该包含 `.`（点）。
{{< /warning >}}

## istioctl

本节介绍了使用 `istioctl` 单独安装和升级控制平面和 Gateway  。该示例演示了如何使用金丝雀升级方法将 Istio 1.8.0 升级到 1.8.1，并将控制平面的 Gateway  和其他 Gateway  分开管理。

### 使用 `istioctl` 安装{#installation-with-istioctl}

1.  确保主 `IstioOperator` CR 具有名字并且没有安装 Gateway  ：

    {{< text yaml >}}
    # 文件名: control-plane.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: control-plane # REQUIRED
    spec:
      profile: minimal
    {{< /text >}}

1.  为 Gateway  创建单独的 `IstioOperator` CR，确保具有名字且使用 `empty` profile：

    {{< text yaml >}}
    # 文件名: Gateway .yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: Gateway  # REQUIRED
    spec:
      profile: empty # REQUIRED
      components:
        ingressGateway :
          - name: istio-ingressgateway
            enabled: true
    {{< /text >}}

1.  安装 `CR`：

    {{< text bash >}}
    $ istio-1.8.0/bin/istioctl install -n istio-system -f control-plane.yaml --revision 1-8-0
    $ istio-1.8.0/bin/istioctl install -n istio-system -f Gateway .yaml --revision 1-8-0
    {{< /text >}}

Istioctl 的安装和操作动作通过 revision 和拥有者的 CR 名称进行确定具有所有权的资源。只有传递给 `istioctl` 安装、操作资源的名称和 revision 标签可以被 `IstioOperator` CR 匹配时，该资源才会受到 CR 更改的影响，集群内的其他资源都将被忽略。注意确保每个 `IstioOperator` 安装的组件不会与另一个 `IstioOperator` CR 相互重叠，否则两个 CR 会导致控制器或 `istioctl` 命令相互干扰。

### 使用 `istioctl` 升级 {#upgrade-with-istioctl}

假设目标版本为 1.8.1。

1. 下载 Istio 1.8.1 版本，并使用该版本的 `istioctl` 来安装 Istio 1.8.1 的控制平面：

    {{< text bash >}}
    $ istio-1.8.1/bin/istioctl install -f control-plane.yaml --revision 1-8-1
    {{< /text >}}

    (有关步骤2-4的更多详细信息，请参阅金丝雀升级文档。)

1.  验证控制平面是否正确运行。

1.  使用 istio.io/rev=1-8-1 标记工作负载的命名空间，并且重启相应的工作负载。

1.  验证工作负载是否已经注入新的代理版本，并且集群已经正常运行。

1.  此时，Ingress Gateway 仍然是 1.8.0 的版本。您应该可以看到一下容器正在运行：

    {{< text bash >}}
    $ kubectl get pods -n istio-system --show-labels

    NAME                                    READY   STATUS    RESTARTS   AGE   LABELS
    istio-ingressgateway-65f8bdd46c-d49wf   1/1     Running   0          21m   service.istio.io/canonical-revision=1-8-0 ...
    istiod-1-8-0-67f9b9b56-r22t5            1/1     Running   0          22m   istio.io/rev=1-8-0 ...
    istiod-1-8-1-75dfd7d494-xhmbb           1/1     Running   0          21s   istio.io/rev=1-8-1 ...
    {{< /text >}}

    最后一步，将集群中的所有 Gateway  升级到新版本：

    {{< text bash >}}
    $ istio-1.8.1/bin/istioctl install -f Gateway .yaml --revision 1-8-1
    {{< /text >}}

1.  删除 1.8.1 版本的控制平面：

    {{< text bash >}}
    $ istio-1.8.1/bin/istioctl x uninstall --revision 1-8-0
    {{< /text >}}

## Operator

本节介绍使用 Istio operator 单独安装和升级控制平面与 Gateway  。下面示例演示如何使用金丝雀升级方法将 Istio 1.8.0 升级到 1.8.1，并且分别管理控制平面和 Gateway  。

### 使用 Operator 安装{#installation-with-operator}

1. 使用 Istio Operator 向集群中安装一个修正版：

    {{< text bash >}}
    $ istio-1.8.0/bin/istioctl operator init --revision 1-8-0
    {{< /text >}}

1. 确保主 `IstioOperator` CR 具有名字和 revision，并且没有安装 Gateway  ：

    {{< text yaml >}}
    # 文件名: control-plane-1-8-0.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: control-plane-1-8-0 # REQUIRED
    spec:
      profile: minimal
      revision: 1-8-0 # REQUIRED
    {{< /text >}}

1.  为 Gateway  创建一个单独的 `IstioOperator` CR，确保具有名字并且使用了 `empty` profile：

    {{< text yaml >}}
    # 文件名: Gateway .yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: Gateway  # REQUIRED
    spec:
      profile: empty # REQUIRED
      revision: 1-8-0 # REQUIRED
      components:
        ingressGateway :
          - name: istio-ingressgateway
            enabled: true
    {{< /text >}}

1.  在集群中执行以下命令来完成部署:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl apply -n istio-system -f control-plane-1-8-0.yaml
    $ kubectl apply -n istio-system -f Gateway .yaml
    {{< /text >}}

验证 Operator 和 Istio 的控制平面已经完成安装并且正在运行。

### 通过 Operator 升级{#upgrade-with-operator}

假设目标版本为 1.8.1。

1.  下载 Istio 1.8.1 版本，并且使用 1.8.1 版本的 `istioctl` 安装 Istio 1.8.1 的 Operator：

    {{< text bash >}}
    $ istio-1.8.1/bin/istioctl operator init --revision 1-8-1
    {{< /text >}}

1.  将上述安装步骤中的控制平面 CR 赋值为 `control-plane-108-1.yaml`。将文件中的 `1-8-0` 修改为 `1-8-1`。

1.  使用新文件部署到集群中：

    {{< text bash >}}
    $ kubectl apply -n istio-system -f control-plane-1-8-1.yaml
    {{< /text >}}

1.  验证两个版本的 `istiod` 都在集群中运行。Operator 可能需要几分钟时间来安装新的控制平面，并使其变为运行状态。

    {{< text bash >}}
    $ kubectl -n istio-system get pod -l app=istiod
    NAME                            READY   STATUS    RESTARTS   AGE
    istiod-1-8-0-74f95c59c-4p6mc    1/1     Running   0          68m
    istiod-1-8-1-65b64fc749-5zq8w   1/1     Running   0          13m
    {{< /text >}}

1.  有关工作负载过渡到新的 Istio 版本的更多详细信息，请查阅金丝雀升级文档。

    -  使用 istio.io/rev=1-8-1 标记工作负载的命名空间，并且重启相应的工作负载。
    -  验证工作负载是否已经注入新的代理版本，并且集群已经正常运行。

1.  将 Gateway  升级到新版本。在安装步骤中，编辑 `Gateway.yaml` 文件，将所有的 `1-8-0` 替换为 `1-8-1` 的版本，并重新部署该文件：

    {{< text bash >}}
    $ kubectl apply -n istio-system -f Gateway .yaml
    {{< /text >}}

1.  执行 Gateway  部署的滚动重启：

    {{< text bash >}}
    $ kubectl rollout restart deployment -n istio-system istio-ingressgateway
    {{< /text >}}

1.  验证 Gateway  是 1.8.1 版本并且已经运行：

    {{< text bash >}}
    $ kubectl -n istio-system get pod -l app=istio-ingressgateway --show-labels
    NAME                                    READY   STATUS    RESTARTS   AGE   LABELS
    istio-ingressgateway-66dc957bd8-r2ptn   1/1     Running   0          14m   app=istio-ingressgateway,service.istio.io/canonical-revision=1-8-1...
    {{< /text >}}

1.  卸载控制平面：

    {{< text bash >}}
    $ kubectl delete istiooperator -n istio-system control-plane-1-8-0
    {{< /text >}}

1.  验证只有一个版本的 `istiod` 正在集群中运行：

    {{< text bash >}}
    $ kubectl -n istio-system get pod -l app=istiod
    NAME                            READY   STATUS    RESTARTS   AGE
    istiod-1-8-1-65b64fc749-5zq8w   1/1     Running   0          16m
    {{< /text >}}
