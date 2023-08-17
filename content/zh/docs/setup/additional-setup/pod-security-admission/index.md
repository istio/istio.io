---
title: 通过 Pod 安全准入安装 Istio
description: 通过 Pod Security 准入控制器安装和使用 Istio。
weight: 70
aliases:
    - /zh/docs/setup/kubernetes/install/pod-security-admission
    - /zh/docs/setup/kubernetes/additional-setup/pod-security-admission
keywords: [psa]
owner: istio/wg-networking-maintainers
test: yes
---

遵循以下指南，使用 Pod Security 准入控制器
（[PSA](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-admission/)）
在网格中针对命名空间执行 `baseline`
[策略](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-standards/)，
从而安装、配置并使用 Istio 网格。

Istio 默认会将 Init 容器 `istio-init` 注入到网格中部署的 Pod 内。
`istio-init` 需要用户或服务账号将 Pod 部署到网格上，还需要具备足够的 Kubernetes RBAC
权限以部署[具有 `NET_ADMIN` 和 `NET_RAW` 能力的容器](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)。

然而，`baseline` 策略在其[允许的权能列表](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-standards/#baseline)中并未包含
`NET_ADMIN` 或 `NET_RAW`。为了避免在所有网格化的命名空间中执行 `privileged` 策略，
有必要使用具有[Istio CNI 插件](/zh/docs/setup/additional-setup/cni/) 的 Istio 网格。
`istio-system` 命名空间中的 `istio-cni-node` DaemonSet 需要 `hostPath` 卷访问本地 CNI 目录。
因为这在 `baseline` 策略中是不被允许的，将部署 CNI DaemonSet 的命名空间需要执行
`privileged` [策略](https://kubernetes.io/zh/docs/concepts/security/pod-security-standards/#privileged)。
此命名空间默认为 `istio-system`。

{{< warning >}}
网格中的命名空间也可以使用 `restricted` [策略](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-standards/#baseline)。
您将需要按照策略规范为应用程序配置 `seccompProfile`。
{{< /warning >}}

## 通过 PSA 安装 Istio {#install-istio-with-psa}

1. 创建 `istio-system` 命名空间并为其打标签以执行 `privileged` 策略。

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl label --overwrite ns istio-system \
        pod-security.kubernetes.io/enforce=privileged \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/istio-system labeled
    {{< /text >}}

1. 在 Kubernetes 集群版本 1.25 或更高版本上[通过 CNI 安装 Istio](/zh/docs/setup/additional-setup/cni/#install-cni)。

    {{< text bash >}}
    $ istioctl install --set components.cni.enabled=true -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Ingress gateways installed
    ✔ CNI installed
    ✔ Installation complete
    {{< /text >}}

## 部署示例应用 {#deploy-sample-app}

1. 添加命名空间标签，以便为将要运行 demo 应用的 `default` 命名空间执行 `baseline` 策略：

    {{< text bash >}}
    $ kubectl label --overwrite ns default \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/default labeled
    {{< /text >}}

1. 使用启用 PSA 的配置资源来部署示例应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-psa.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

1. 通过检查响应的页面标题，确认应用正在集群内运行且正提供 HTML 页面：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## 卸载 {#uninstall}

1. 删除示例应用

    {{< text bash >}}
    $ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-psa.yaml
    {{< /text >}}

1. 删除 `default` 命名空间上的标签

    {{< text bash >}}
    $ kubectl label namespace default pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version-
    {{< /text >}}

1. 卸载 Istio

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    {{< /text >}}

1. 删除 `istio-system` 命名空间

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
